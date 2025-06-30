import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;

/// 音频上传服务 - 使用 MinIO 客户端（S3 兼容）
class AudioUploadService {
  late final Minio _minioClient;
  final String bucketName;
  final String region;
  
  // 上传进度流控制器
  final _uploadProgressController = StreamController<double>.broadcast();
  Stream<double> get uploadProgress => _uploadProgressController.stream;
  
  AudioUploadService() : 
    bucketName = dotenv.env['TOS_BUCKET_NAME'] ?? 'meetingly',
    region = dotenv.env['TOS_REGION'] ?? 'cn-beijing' {
    
    // 初始化 MinIO 客户端
    _minioClient = Minio(
      endPoint: dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com',
      accessKey: dotenv.env['TOS_ACCESS_KEY_ID'] ?? '',
      secretKey: _decodeSecretKey(),
      region: region,
      useSSL: true,
    );
  }
  
  /// 解码 Base64 编码的密钥
  String _decodeSecretKey() {
    final encodedKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    if (encodedKey.isEmpty) return '';
    
    // 检查是否是 Base64 编码
    if (encodedKey.contains('=') || encodedKey.length % 4 == 0) {
      try {
        return String.fromCharCodes(base64Decode(encodedKey));
      } catch (e) {
        // 如果解码失败，返回原始值
        return encodedKey;
      }
    }
    return encodedKey;
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
      
      // 获取文件流
      final fileStream = audioFile.openRead();
      final fileLength = audioFile.lengthSync();
      
      // 上传文件并跟踪进度
      int uploadedBytes = 0;
      final transformedStream = fileStream.transform<Uint8List>(
        StreamTransformer.fromHandlers(
          handleData: (List<int> data, sink) {
            uploadedBytes += data.length;
            final progress = uploadedBytes / fileLength;
            _uploadProgressController.add(progress);
            sink.add(Uint8List.fromList(data));
          },
        ),
      );
      
      // 执行上传
      await _minioClient.putObject(
        bucketName,
        objectKey,
        transformedStream,
        size: fileLength,
        metadata: {
          'content-type': _getContentType(audioFile.path),
          'uploaded-by': 'flutter-meeting-app',
          'upload-time': DateTime.now().toIso8601String(),
        },
      );
      
      if (Get.isLogEnable) {
        Get.log('Audio file uploaded successfully');
      }
      
      // 生成预签名 URL（1小时有效期）
      final presignedUrl = await generatePresignedUrl(objectKey);
      
      return presignedUrl;
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
      final presignedUrl = await _minioClient.presignedGetObject(
        bucketName,
        objectKey,
        expires: expires,
      );
      
      if (Get.isLogEnable) {
        Get.log('Generated presigned URL (expires in ${expires}s): $presignedUrl');
      }
      
      return presignedUrl;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error generating presigned URL: $e');
      }
      rethrow;
    }
  }
  
  /// 删除音频文件
  Future<void> deleteAudioFile(String objectKey) async {
    try {
      await _minioClient.removeObject(bucketName, objectKey);
      
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
      await _minioClient.statObject(bucketName, objectKey);
      return true;
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