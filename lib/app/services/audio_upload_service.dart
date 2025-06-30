import 'dart:io';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'volcano_engine/tos_service.dart';

/// 音频上传服务 - 使用火山引擎 TOS 服务
class AudioUploadService {
  late final TOSService _tosService;
  final String bucketName;
  final String region;
  
  // 上传进度流控制器
  final _uploadProgressController = StreamController<double>.broadcast();
  Stream<double> get uploadProgress => _uploadProgressController.stream;
  
  AudioUploadService() : 
    bucketName = dotenv.env['TOS_BUCKET_NAME'] ?? 'meetingly',
    region = dotenv.env['TOS_REGION'] ?? 'cn-beijing' {
    
    // 初始化 TOS 服务
    final endpoint = dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com';
    final accessKeyId = dotenv.env['TOS_ACCESS_KEY_ID'] ?? '';
    final secretAccessKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    
    if (Get.isLogEnable) {
      Get.log('Initializing TOS Service:');
      Get.log('  Endpoint: $endpoint');
      Get.log('  Bucket: $bucketName');
      Get.log('  Region: $region');
      Get.log('  Access Key ID: ${accessKeyId.substring(0, 10)}...');
    }
    
    _tosService = TOSService(
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      endpoint: endpoint,
      bucketName: bucketName,
      region: region,
    );
  }
  
  /// 上传音频文件到 TOS
  Future<String> uploadAudioFile(File audioFile) async {
    try {
      // 生成对象键
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(audioFile.path);
      final objectKey = 'audio/$timestamp-$fileName';
      
      if (Get.isLogEnable) {
        Get.log('Uploading audio file to TOS...');
        Get.log('Bucket: $bucketName');
        Get.log('Object Key: $objectKey');
        Get.log('File Size: ${audioFile.lengthSync()} bytes');
      }
      
      // 上传进度跟踪
      final fileLength = audioFile.lengthSync();
      _uploadProgressController.add(0.0);
      
      // 使用 TOSService 上传文件
      if (Get.isLogEnable) {
        Get.log('Attempting upload with TOSService:');
        Get.log('  Object Key: $objectKey');
        Get.log('  Content Type: ${_getContentType(audioFile.path)}');
        Get.log('  File Size: $fileLength bytes');
      }
      
      try {
        // TOSService.uploadFile 返回完整的 URL
        final uploadedUrl = await _tosService.uploadFile(
          audioFile,
          objectKey: objectKey,
        );
        
        // 上传完成，设置进度为 100%
        _uploadProgressController.add(1.0);
        
        if (Get.isLogEnable) {
          Get.log('Audio file uploaded successfully');
          Get.log('Uploaded URL: $uploadedUrl');
        }
        
        return uploadedUrl;
      } catch (uploadError) {
        if (Get.isLogEnable) {
          Get.log('TOS upload error details:');
          Get.log('  Error: $uploadError');
          Get.log('  Type: ${uploadError.runtimeType}');
        }
        rethrow;
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error uploading audio file: $e');
      }
      rethrow;
    }
  }
  
  /// 生成预签名 URL
  Future<String> generatePresignedUrl(String objectKey, {int expires = 3600}) async {
    try {
      // TOSService 目前返回的是直接访问 URL，不是预签名 URL
      // 如果需要预签名 URL，需要在 TOSService 中实现
      final url = 'https://$bucketName.${_tosService.endpoint}/$objectKey';
      
      if (Get.isLogEnable) {
        Get.log('Generated URL for object: $url');
        Get.log('Note: This is a direct URL, not a presigned URL');
      }
      
      return url;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error generating URL: $e');
      }
      rethrow;
    }
  }
  
  /// 删除音频文件
  Future<void> deleteAudioFile(String objectKey) async {
    try {
      await _tosService.deleteFile(objectKey);
      
      if (Get.isLogEnable) {
        Get.log('Audio file deleted: $objectKey');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error deleting audio file: $e');
      }
      // 删除失败不抛出异常，避免影响主流程
    }
  }
  
  /// 检查文件是否存在
  Future<bool> fileExists(String objectKey) async {
    try {
      return await _tosService.fileExists(objectKey);
    } catch (e) {
      return false;
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
      default:
        return 'application/octet-stream';
    }
  }
  
  /// 清理资源
  void dispose() {
    _uploadProgressController.close();
  }
}