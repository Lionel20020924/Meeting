import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';

/// 火山引擎 TOS (对象存储) 服务
class TOSService {
  final String accessKeyId;
  final String secretAccessKey;
  final String endpoint;
  final String bucketName;
  final String region;

  TOSService({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.endpoint,
    required this.bucketName,
    required this.region,
  });

  /// 上传文件到 TOS
  Future<String> uploadFile(File file, {String? objectKey}) async {
    try {
      // 生成对象键（如果未提供）
      objectKey ??= _generateObjectKey(file.path);
      
      // 读取文件内容
      final fileBytes = await file.readAsBytes();
      
      // 构建请求URL
      final url = 'https://$bucketName.$endpoint/$objectKey';
      
      // 生成签名头
      final headers = await _generateHeaders(
        method: 'PUT',
        objectKey: objectKey,
        contentType: _getContentType(file.path),
        contentLength: fileBytes.length,
      );
      
      // 发送请求
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: fileBytes,
      );
      
      if (response.statusCode == 200) {
        if (Get.isLogEnable) {
          Get.log('File uploaded successfully to TOS: $url');
        }
        return url;
      } else {
        throw Exception('Failed to upload file: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error uploading file to TOS: $e');
      }
      rethrow;
    }
  }

  /// 生成对象键
  String _generateObjectKey(String filePath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = path.basename(filePath);
    return 'meeting-recordings/$timestamp-$fileName';
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
      default:
        return 'application/octet-stream';
    }
  }

  /// 生成请求头（包含签名）
  Future<Map<String, String>> _generateHeaders({
    required String method,
    required String objectKey,
    required String contentType,
    required int contentLength,
  }) async {
    final dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
    final date = '${dateFormat.format(DateTime.now().toUtc())} GMT';
    
    // 构建规范请求
    final canonicalRequest = _buildCanonicalRequest(
      method: method,
      objectKey: objectKey,
      date: date,
      contentType: contentType,
    );
    
    // 生成签名
    final signature = _generateSignature(canonicalRequest);
    
    return {
      'Host': '$bucketName.$endpoint',
      'Date': date,
      'Content-Type': contentType,
      'Content-Length': contentLength.toString(),
      'Authorization': 'TOS $accessKeyId:$signature',
    };
  }

  /// 构建规范请求
  String _buildCanonicalRequest({
    required String method,
    required String objectKey,
    required String date,
    required String contentType,
  }) {
    final canonicalHeaders = [
      'content-type:$contentType',
      'date:$date',
      'host:$bucketName.$endpoint',
    ].join('\n');
    
    return [
      method,
      '/$objectKey',
      '',
      canonicalHeaders,
    ].join('\n');
  }

  /// 生成签名
  String _generateSignature(String canonicalRequest) {
    final key = utf8.encode(secretAccessKey);
    final bytes = utf8.encode(canonicalRequest);
    
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    return base64.encode(digest.bytes);
  }

  /// 删除文件
  Future<void> deleteFile(String objectKey) async {
    try {
      final url = 'https://$bucketName.$endpoint/$objectKey';
      
      final headers = await _generateHeaders(
        method: 'DELETE',
        objectKey: objectKey,
        contentType: '',
        contentLength: 0,
      );
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete file: ${response.statusCode}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error deleting file from TOS: $e');
      }
      rethrow;
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String objectKey) async {
    try {
      final url = 'https://$bucketName.$endpoint/$objectKey';
      
      final headers = await _generateHeaders(
        method: 'HEAD',
        objectKey: objectKey,
        contentType: '',
        contentLength: 0,
      );
      
      final response = await http.head(
        Uri.parse(url),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error checking file existence: $e');
      }
      return false;
    }
  }
}