import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'audio_storage_interface.dart';

/// 音频上传服务 - 使用 Supabase Storage
class SupabaseAudioStorageService implements AudioStorageInterface {
  final SupabaseClient _supabase;
  final String bucketName = 'meeting-audio';
  final _uuid = const Uuid();
  
  // 上传进度流控制器
  final _uploadProgressController = StreamController<double>.broadcast();
  @override
  Stream<double> get uploadProgress => _uploadProgressController.stream;
  
  SupabaseAudioStorageService()
      : _supabase = Supabase.instance.client {
    
    if (Get.isLogEnable) {
      Get.log('Initializing Supabase Audio Storage Service');
      Get.log('  Bucket: $bucketName');
    }
  }
  
  /// 上传音频文件到 Supabase Storage
  @override
  Future<String> uploadAudioFile(File audioFile, {String? meetingId}) async {
    try {
      // 生成唯一的文件路径
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(audioFile.path);
      final uniqueId = meetingId ?? _uuid.v4();
      
      // 构建存储路径: user_id/meeting_id/timestamp-filename
      final storagePath = '$userId/$uniqueId/$timestamp-$fileName';
      
      if (Get.isLogEnable) {
        Get.log('Uploading audio file to Supabase Storage...');
        Get.log('  Storage Path: $storagePath');
        Get.log('  File Size: ${audioFile.lengthSync()} bytes');
      }
      
      // 读取文件内容
      final fileBytes = await audioFile.readAsBytes();
      final fileLength = fileBytes.length;
      
      // 模拟上传进度（Supabase SDK 暂不支持进度回调）
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (timer.tick * 100 < 1000) {
          _uploadProgressController.add(timer.tick * 0.1);
        } else {
          timer.cancel();
        }
      });
      
      // 执行上传
      final response = await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(audioFile.path),
              upsert: true,
            ),
          );
      
      // 上传完成
      _uploadProgressController.add(1.0);
      
      if (Get.isLogEnable) {
        Get.log('Audio file uploaded successfully to Supabase');
        Get.log('  Response: $response');
      }
      
      // 保存文件元数据到数据库
      await _saveFileMetadata(
        userId: userId,
        meetingId: uniqueId,
        fileName: fileName,
        filePath: storagePath,
        fileSize: fileLength,
        contentType: _getContentType(audioFile.path),
      );
      
      // 生成访问 URL
      final url = await generatePresignedUrl(storagePath);
      
      if (Get.isLogEnable) {
        Get.log('Generated URL: $url');
      }
      
      return url;
      
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error uploading audio file to Supabase: $e');
      }
      rethrow;
    }
  }
  
  /// 保存文件元数据到数据库
  Future<void> _saveFileMetadata({
    required String userId,
    required String meetingId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String contentType,
  }) async {
    try {
      final response = await _supabase
          .from('audio_files')
          .insert({
            'user_id': userId,
            'meeting_id': meetingId,
            'file_name': fileName,
            'file_path': filePath,
            'file_size': fileSize,
            'content_type': contentType,
            'transcription_status': 'pending',
          })
          .select()
          .single();
      
      if (Get.isLogEnable) {
        Get.log('File metadata saved: $response');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error saving file metadata: $e');
      }
      // 元数据保存失败不影响主流程
    }
  }
  
  /// 生成预签名 URL
  @override
  Future<String> generatePresignedUrl(String filePath, {int expires = 3600}) async {
    try {
      // 生成签名 URL
      final signedUrl = await _supabase.storage
          .from(bucketName)
          .createSignedUrl(filePath, expires);
      
      if (Get.isLogEnable) {
        Get.log('Generated signed URL (expires in ${expires}s): $signedUrl');
      }
      
      return signedUrl;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error generating signed URL: $e');
      }
      
      // 备用方案：返回公共 URL（如果 bucket 是公开的）
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
      
      return publicUrl;
    }
  }
  
  /// 删除音频文件
  @override
  Future<void> deleteAudioFile(String filePath) async {
    try {
      // 从 Storage 删除文件
      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);
      
      // 更新数据库中的记录（标记为已删除）
      await _supabase
          .from('audio_files')
          .update({'transcription_status': 'deleted'})
          .eq('file_path', filePath);
      
      if (Get.isLogEnable) {
        Get.log('Audio file deleted: $filePath');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error deleting audio file: $e');
      }
      // 删除失败不抛出异常，避免影响主流程
    }
  }
  
  /// 检查文件是否存在
  @override
  Future<bool> fileExists(String filePath) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .list(path: path.dirname(filePath));
      
      final fileName = path.basename(filePath);
      return response.any((file) => file.name == fileName);
    } catch (e) {
      return false;
    }
  }
  
  /// 获取用户的音频文件列表
  Future<List<AudioFileMetadata>> getUserAudioFiles({
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return [];
      }
      
      final response = await _supabase
          .from('audio_files')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((data) => AudioFileMetadata.fromJson(data))
          .toList();
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error fetching user audio files: $e');
      }
      return [];
    }
  }
  
  /// 更新转录状态
  Future<void> updateTranscriptionStatus(
    String meetingId,
    String status, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'transcription_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (metadata != null) {
        updates['metadata'] = metadata;
      }
      
      await _supabase
          .from('audio_files')
          .update(updates)
          .eq('meeting_id', meetingId);
      
      if (Get.isLogEnable) {
        Get.log('Updated transcription status for meeting $meetingId: $status');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error updating transcription status: $e');
      }
    }
  }
  
  /// 获取文件内容类型
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.flac':
        return 'audio/flac';
      case '.webm':
        return 'audio/webm';
      case '.ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }
  
  /// 清理资源
  @override
  void dispose() {
    _uploadProgressController.close();
  }
}

/// 音频文件元数据
class AudioFileMetadata {
  final String id;
  final String userId;
  final String meetingId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String contentType;
  final int? duration;
  final String transcriptionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  
  AudioFileMetadata({
    required this.id,
    required this.userId,
    required this.meetingId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.contentType,
    this.duration,
    required this.transcriptionStatus,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });
  
  factory AudioFileMetadata.fromJson(Map<String, dynamic> json) {
    return AudioFileMetadata(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      meetingId: json['meeting_id'].toString(),
      fileName: json['file_name'].toString(),
      filePath: json['file_path'].toString(),
      fileSize: json['file_size'] as int,
      contentType: json['content_type'].toString(),
      duration: json['duration'] as int?,
      transcriptionStatus: json['transcription_status'].toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meeting_id': meetingId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'content_type': contentType,
      'duration': duration,
      'transcription_status': transcriptionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}