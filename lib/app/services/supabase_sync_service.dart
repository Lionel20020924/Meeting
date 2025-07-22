import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';
import 'supabase_auth_service.dart';

/// Supabase 数据同步服务
class SupabaseSyncService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = Get.find<SupabaseAuthService>();
  
  // 同步状态
  final RxBool isSyncing = false.obs;
  final RxString lastSyncTime = ''.obs;
  final RxInt pendingSyncCount = 0.obs;
  final RxMap<String, String> meetingSyncStatus = <String, String>{}.obs;
  
  // 同步错误
  final RxList<String> syncErrors = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadLastSyncTime();
  }
  
  /// 加载上次同步时间
  Future<void> _loadLastSyncTime() async {
    try {
      final userId = _authService.userId;
      if (userId == null) return;
      
      final response = await _supabase
          .from('sync_metadata')
          .select('last_sync_at')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null && response['last_sync_at'] != null) {
        lastSyncTime.value = response['last_sync_at'];
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error loading last sync time: $e');
      }
    }
  }
  
  /// 执行完整同步
  Future<void> performFullSync() async {
    if (!_authService.isAuthenticated) {
      Get.snackbar(
        'Error',
        'Please login to sync data',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    if (isSyncing.value) {
      Get.snackbar(
        'Info',
        'Sync already in progress',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    try {
      isSyncing.value = true;
      syncErrors.clear();
      
      // 1. 获取本地会议数据
      final localMeetings = await StorageService.loadMeetings();
      
      // 2. 获取云端会议数据
      final cloudMeetings = await _fetchCloudMeetings();
      
      // 3. 同步会议数据
      await _syncMeetings(localMeetings, cloudMeetings);
      
      // 4. 更新同步时间
      await _updateSyncMetadata();
      
      Get.snackbar(
        'Success',
        'Sync completed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Sync error: $e');
      }
      syncErrors.add(e.toString());
      Get.snackbar(
        'Sync Failed',
        'Error during sync: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSyncing.value = false;
    }
  }
  
  /// 获取云端会议数据
  Future<List<Map<String, dynamic>>> _fetchCloudMeetings() async {
    try {
      final response = await _supabase
          .from('meetings')
          .select('''
            *,
            meeting_notes(*),
            meeting_transcriptions(*),
            meeting_summaries(*)
          ''')
          .isFilter('deleted_at', null)
          .order('date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error fetching cloud meetings: $e');
      }
      return [];
    }
  }
  
  /// 同步会议数据
  Future<void> _syncMeetings(
    List<Map<String, dynamic>> localMeetings,
    List<Map<String, dynamic>> cloudMeetings,
  ) async {
    final userId = _authService.userId!;
    
    // 创建查找映射
    final cloudMeetingMap = <String, Map<String, dynamic>>{};
    for (final meeting in cloudMeetings) {
      final legacyId = meeting['legacy_id'];
      if (legacyId != null) {
        cloudMeetingMap[legacyId] = meeting;
      }
    }
    
    // 处理每个本地会议
    for (final localMeeting in localMeetings) {
      final localId = localMeeting['id']?.toString();
      if (localId == null) continue;
      
      try {
        meetingSyncStatus[localId] = 'syncing';
        
        final cloudMeeting = cloudMeetingMap[localId];
        
        if (cloudMeeting == null) {
          // 本地有，云端没有 - 上传到云端
          await _uploadMeeting(localMeeting, userId);
          meetingSyncStatus[localId] = 'synced';
        } else {
          // 两边都有 - 比较更新时间
          final localDate = DateTime.parse(localMeeting['date'] ?? '');
          final cloudDate = DateTime.parse(cloudMeeting['updated_at'] ?? cloudMeeting['date']);
          
          if (localDate.isAfter(cloudDate)) {
            // 本地更新 - 更新云端
            await _updateCloudMeeting(cloudMeeting['id'], localMeeting);
            meetingSyncStatus[localId] = 'synced';
          } else {
            // 云端更新或相同 - 保持现状
            meetingSyncStatus[localId] = 'synced';
          }
        }
      } catch (e) {
        meetingSyncStatus[localId] = 'error';
        syncErrors.add('Failed to sync meeting $localId: $e');
      }
    }
    
    // 处理云端有但本地没有的会议（可能在其他设备创建）
    for (final cloudMeeting in cloudMeetings) {
      final legacyId = cloudMeeting['legacy_id'];
      if (legacyId != null && !localMeetings.any((m) => m['id']?.toString() == legacyId)) {
        // 下载到本地
        await _downloadMeeting(cloudMeeting);
      }
    }
  }
  
  /// 上传会议到云端
  Future<void> _uploadMeeting(Map<String, dynamic> localMeeting, String userId) async {
    try {
      // 1. 创建会议记录
      final meetingData = {
        'user_id': userId,
        'legacy_id': localMeeting['id']?.toString(),
        'title': localMeeting['title'],
        'date': localMeeting['date'],
        'duration': localMeeting['duration'],
        'participants': localMeeting['participants'] ?? '1',
        'audio_path': localMeeting['audioPath'],
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      };
      
      final meetingResponse = await _supabase
          .from('meetings')
          .insert(meetingData)
          .select()
          .single();
      
      final meetingId = meetingResponse['id'];
      
      // 2. 上传笔记
      if (localMeeting['notes'] != null && localMeeting['notes'] is List) {
        final notes = localMeeting['notes'] as List;
        if (notes.isNotEmpty) {
          final notesData = notes.map((note) => {
            'meeting_id': meetingId,
            'time': note['time'],
            'note': note['note'],
          }).toList();
          
          await _supabase.from('meeting_notes').insert(notesData);
        }
      }
      
      // 3. 上传转录
      if (localMeeting['transcription'] != null || localMeeting['formattedTranscription'] != null) {
        final transcriptionData = {
          'meeting_id': meetingId,
          'full_text': localMeeting['transcription'],
          'formatted_text': localMeeting['formattedTranscription'],
        };
        
        final transcriptionResponse = await _supabase
            .from('meeting_transcriptions')
            .insert(transcriptionData)
            .select()
            .single();
        
        // 上传转录片段
        if (localMeeting['transcriptionSegments'] != null && localMeeting['transcriptionSegments'] is List) {
          final segments = localMeeting['transcriptionSegments'] as List;
          if (segments.isNotEmpty) {
            final segmentsData = segments.map((segment) => {
              'transcription_id': transcriptionResponse['id'],
              'text': segment['text'],
              'start_time': segment['startTime'],
              'end_time': segment['endTime'],
              'speaker_id': segment['speakerId'],
              'confidence': segment['confidence'],
            }).toList();
            
            await _supabase.from('transcription_segments').insert(segmentsData);
          }
        }
      }
      
      // 4. 上传摘要
      if (localMeeting['summary'] != null || 
          (localMeeting['keyPoints'] != null && localMeeting['keyPoints'] is List) ||
          (localMeeting['actionItems'] != null && localMeeting['actionItems'] is List)) {
        final summaryData = {
          'meeting_id': meetingId,
          'summary_text': localMeeting['summary'],
          'key_points': localMeeting['keyPoints'] ?? [],
          'action_items': localMeeting['actionItems'] ?? [],
        };
        
        await _supabase.from('meeting_summaries').insert(summaryData);
      }
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error uploading meeting: $e');
      }
      rethrow;
    }
  }
  
  /// 更新云端会议
  Future<void> _updateCloudMeeting(String meetingId, Map<String, dynamic> localMeeting) async {
    try {
      // 更新会议基本信息
      await _supabase
          .from('meetings')
          .update({
            'title': localMeeting['title'],
            'date': localMeeting['date'],
            'duration': localMeeting['duration'],
            'participants': localMeeting['participants'] ?? '1',
            'audio_path': localMeeting['audioPath'],
            'last_synced_at': DateTime.now().toIso8601String(),
          })
          .eq('id', meetingId);
      
      // 更新其他相关数据...
      // TODO: 实现笔记、转录、摘要的更新逻辑
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error updating cloud meeting: $e');
      }
      rethrow;
    }
  }
  
  /// 下载会议到本地
  Future<void> _downloadMeeting(Map<String, dynamic> cloudMeeting) async {
    try {
      // 转换云端数据格式到本地格式
      final localMeeting = {
        'id': cloudMeeting['legacy_id'] ?? cloudMeeting['id'],
        'title': cloudMeeting['title'],
        'date': cloudMeeting['date'],
        'duration': cloudMeeting['duration'],
        'participants': cloudMeeting['participants'],
        'audioPath': cloudMeeting['audio_path'],
      };
      
      // 添加笔记
      if (cloudMeeting['meeting_notes'] != null && cloudMeeting['meeting_notes'] is List) {
        localMeeting['notes'] = (cloudMeeting['meeting_notes'] as List).map((note) => {
          'time': note['time'],
          'note': note['note'],
        }).toList();
      }
      
      // 添加转录
      if (cloudMeeting['meeting_transcriptions'] != null && cloudMeeting['meeting_transcriptions'] is List) {
        final transcriptions = cloudMeeting['meeting_transcriptions'] as List;
        if (transcriptions.isNotEmpty) {
          final transcription = transcriptions.first;
          localMeeting['transcription'] = transcription['full_text'];
          localMeeting['formattedTranscription'] = transcription['formatted_text'];
        }
      }
      
      // 添加摘要
      if (cloudMeeting['meeting_summaries'] != null && cloudMeeting['meeting_summaries'] is List) {
        final summaries = cloudMeeting['meeting_summaries'] as List;
        if (summaries.isNotEmpty) {
          final summary = summaries.first;
          localMeeting['summary'] = summary['summary_text'];
          localMeeting['keyPoints'] = summary['key_points'] ?? [];
          localMeeting['actionItems'] = summary['action_items'] ?? [];
        }
      }
      
      // 保存到本地
      await StorageService.saveMeeting(localMeeting);
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error downloading meeting: $e');
      }
      rethrow;
    }
  }
  
  /// 删除会议（硬删除）
  Future<void> deleteMeeting(String meetingId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    
    try {
      // 查找云端会议
      final response = await _supabase
          .from('meetings')
          .select('id')
          .eq('legacy_id', meetingId)
          .maybeSingle();
      
      if (response != null) {
        // 调用硬删除函数
        await _supabase
            .rpc('hard_delete_meeting', params: {'p_meeting_id': response['id']});
      }
      
      // 同时删除本地数据
      await StorageService.deleteMeeting(meetingId);
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error deleting meeting: $e');
      }
      rethrow;
    }
  }
  
  /// 更新同步元数据
  Future<void> _updateSyncMetadata() async {
    try {
      final userId = _authService.userId!;
      final now = DateTime.now().toIso8601String();
      
      await _supabase
          .from('sync_metadata')
          .upsert({
            'user_id': userId,
            'last_sync_at': now,
            'device_id': 'flutter_app', // TODO: 获取真实设备ID
          }, onConflict: 'user_id,device_id');
      
      lastSyncTime.value = now;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error updating sync metadata: $e');
      }
    }
  }
  
  /// 获取待同步会议数量
  Future<int> getPendingSyncCount() async {
    try {
      final localMeetings = await StorageService.loadMeetings();
      final cloudMeetings = await _fetchCloudMeetings();
      
      // 简单计算：本地有但云端没有的数量
      final cloudIds = cloudMeetings
          .map((m) => m['legacy_id'])
          .where((id) => id != null)
          .toSet();
      
      final pendingCount = localMeetings
          .where((m) => !cloudIds.contains(m['id']?.toString()))
          .length;
      
      pendingSyncCount.value = pendingCount;
      return pendingCount;
    } catch (e) {
      return 0;
    }
  }
  
  /// 获取格式化的上次同步时间
  String get formattedLastSyncTime {
    if (lastSyncTime.value.isEmpty) return 'Never';
    
    try {
      final syncDate = DateTime.parse(lastSyncTime.value);
      final now = DateTime.now();
      final difference = now.difference(syncDate);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${syncDate.day}/${syncDate.month}/${syncDate.year}';
      }
    } catch (e) {
      return lastSyncTime.value;
    }
  }
  
  /// 获取会议同步状态
  String getMeetingSyncStatus(String meetingId) {
    return meetingSyncStatus[meetingId] ?? 'unknown';
  }
  
  /// 单例访问
  static SupabaseSyncService get to => Get.find<SupabaseSyncService>();
}