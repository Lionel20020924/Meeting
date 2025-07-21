import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;
import 'audio_storage_interface.dart';

/// 音频上传服务 - 使用 MinIO 客户端连接火山引擎 TOS
class AudioUploadService implements AudioStorageInterface {
  late final Minio _minioClient;
  final String bucketName;
  final String region;
  
  // 上传进度流控制器
  final _uploadProgressController = StreamController<double>.broadcast();
  @override
  Stream<double> get uploadProgress => _uploadProgressController.stream;
  
  AudioUploadService() : 
    bucketName = dotenv.env['TOS_BUCKET_NAME'] ?? 'meetingly',
    region = dotenv.env['TOS_REGION'] ?? 'cn-beijing' {
    
    // 初始化 MinIO 客户端
    final endpoint = dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com';
    final accessKeyId = dotenv.env['TOS_ACCESS_KEY_ID'] ?? '';
    final secretKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    
    if (Get.isLogEnable) {
      Get.log('Initializing MinIO client for TOS:');
      Get.log('  Endpoint: $endpoint');
      Get.log('  Bucket: $bucketName');
      Get.log('  Region: $region');
      Get.log('  Access Key ID: ${accessKeyId.substring(0, 10)}...');
      Get.log('  Secret Key decoded: ${secretKey.isNotEmpty}');
    }
    
    // 配置 MinIO 客户端以连接火山引擎 TOS
    _minioClient = Minio(
      endPoint: endpoint,
      port: 443,
      useSSL: true,
      accessKey: accessKeyId,
      secretKey: secretKey,
      region: region,
      pathStyle: false,
      // 不设置 sessionToken
    );
    
    // 测试连接
    _testConnection();
  }
  
  /// 解码 Base64 编码的密钥 (可能是双重编码)
  String _decodeSecretKey() {
    final encodedKey = dotenv.env['TOS_SECRET_ACCESS_KEY'] ?? '';
    if (encodedKey.isEmpty) return '';
    
    // 对于 MinIO，尝试不同的密钥格式
    // 选项 1：尝试使用原始 Base64 字符串（不解码）
    if (Get.isLogEnable) {
      Get.log('Testing secret key formats for MinIO...');
    }
    
    try {
      // 第一次 Base64 解码
      final firstDecode = base64Decode(encodedKey);
      var decodedString = utf8.decode(firstDecode);
      
      // 检查是否需要第二次解码
      if (decodedString.length < 50 && !decodedString.contains(' ')) {
        try {
          // 添加必要的填充
          final remainder = decodedString.length % 4;
          if (remainder != 0) {
            decodedString += '=' * (4 - remainder);
          }
          
          // 第二次 Base64 解码
          final secondDecode = base64Decode(decodedString);
          final hexString = utf8.decode(secondDecode);
          
          // 检查是否是十六进制字符串
          if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexString) && hexString.length == 32) {
            if (Get.isLogEnable) {
              Get.log('Detected hex string: $hexString');
              Get.log('MinIO might expect the hex string directly');
            }
            
            // 对于 MinIO，可能需要返回十六进制字符串本身
            // 而不是转换后的二进制
            return hexString;
          }
          
          return hexString;
        } catch (e) {
          // 第二次解码失败，使用第一次解码的结果
          if (Get.isLogEnable) {
            Get.log('Using single decoded value for MinIO');
          }
          return decodedString;
        }
      }
      
      return decodedString;
    } catch (e) {
      // 解码失败，返回原始值
      if (Get.isLogEnable) {
        Get.log('Using original Base64 value for MinIO');
      }
      return encodedKey;
    }
  }
  
  /// 测试 MinIO 连接
  Future<void> _testConnection() async {
    try {
      // 尝试检查 bucket 是否存在
      final exists = await _minioClient.bucketExists(bucketName);
      if (Get.isLogEnable) {
        Get.log('MinIO connection test - Bucket "$bucketName" exists: $exists');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('MinIO connection test failed: $e');
      }
    }
  }
  
  /// 上传音频文件到 TOS
  @override
  Future<String> uploadAudioFile(File audioFile, {String? meetingId}) async {
    try {
      // 生成对象键
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basename(audioFile.path);
      final objectKey = 'audio/$timestamp-$fileName';
      
      if (Get.isLogEnable) {
        Get.log('Uploading audio file to TOS via MinIO...');
        Get.log('Bucket: $bucketName');
        Get.log('Object Key: $objectKey');
        Get.log('File Size: ${audioFile.lengthSync()} bytes');
      }
      
      // 获取文件流和长度
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
      if (Get.isLogEnable) {
        Get.log('Attempting upload with MinIO:');
        Get.log('  Bucket: $bucketName');
        Get.log('  Object Key: $objectKey');
        Get.log('  Content Type: ${_getContentType(audioFile.path)}');
        Get.log('  File Size: $fileLength bytes');
      }
      
      try {
        // 使用 MinIO 上传
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
          Get.log('Audio file uploaded successfully via MinIO');
        }
        
        // 生成访问 URL
        final url = await generatePresignedUrl(objectKey);
        
        if (Get.isLogEnable) {
          Get.log('Generated URL: $url');
        }
        
        return url;
      } catch (uploadError) {
        if (Get.isLogEnable) {
          Get.log('MinIO upload error details:');
          Get.log('  Error: $uploadError');
          Get.log('  Type: ${uploadError.runtimeType}');
          
          // 尝试提供更详细的错误信息
          if (uploadError.toString().contains('SignatureDoesNotMatch')) {
            Get.log('  Issue: Signature mismatch - check secret key format');
          } else if (uploadError.toString().contains('Forbidden')) {
            Get.log('  Issue: Access forbidden - check permissions or credentials');
          } else if (uploadError.toString().contains('NoSuchBucket')) {
            Get.log('  Issue: Bucket not found - check bucket name');
          }
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
  @override
  Future<String> generatePresignedUrl(String objectKey, {int expires = 3600}) async {
    try {
      // 使用 MinIO 生成预签名 URL
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
        // 如果预签名 URL 生成失败，返回直接访问 URL
        Get.log('Falling back to direct URL');
      }
      
      // 备用方案：返回直接访问 URL
      final endpoint = dotenv.env['TOS_ENDPOINT'] ?? 'tos-s3-cn-beijing.volces.com';
      return 'https://$bucketName.$endpoint/$objectKey';
    }
  }
  
  /// 删除音频文件
  @override
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
  @override
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
  @override
  void dispose() {
    _uploadProgressController.close();
  }
}