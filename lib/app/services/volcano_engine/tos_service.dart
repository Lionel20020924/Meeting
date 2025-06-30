import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:get/get.dart';

/// 火山引擎 TOS (对象存储) 服务 - 使用 AWS S3 V4 签名
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
      
      // 构建请求URL - 使用虚拟主机风格
      final url = 'https://$bucketName.$endpoint/$objectKey';
      
      if (Get.isLogEnable) {
        Get.log('TOS Upload URL: $url');
        Get.log('TOS Endpoint: $endpoint');
        Get.log('TOS Bucket: $bucketName');
        Get.log('TOS Object Key: $objectKey');
        Get.log('File size: ${fileBytes.length} bytes');
      }
      
      // 生成 AWS S3 V4 签名头
      final headers = await _generateAWSV4Headers(
        method: 'PUT',
        bucketName: bucketName,
        objectKey: objectKey,
        contentType: _getContentType(file.path),
        payload: fileBytes,
      );
      
      if (Get.isLogEnable) {
        Get.log('Request Headers:');
        headers.forEach((key, value) {
          if (key.toLowerCase() != 'authorization') {
            Get.log('  $key: $value');
          } else {
            Get.log('  $key: ${value.substring(0, 50)}...');
          }
        });
      }
      
      // 发送请求
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: fileBytes,
      );
      
      if (Get.isLogEnable) {
        Get.log('Response Status: ${response.statusCode}');
        Get.log('Response Headers: ${response.headers}');
        if (response.statusCode != 200) {
          Get.log('Response Body: ${response.body}');
        }
      }
      
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

  /// 生成 AWS S3 V4 签名头
  Future<Map<String, String>> _generateAWSV4Headers({
    required String method,
    required String bucketName,
    required String objectKey,
    required String contentType,
    required List<int> payload,
  }) async {
    final now = DateTime.now().toUtc();
    final dateStamp = DateFormat('yyyyMMdd').format(now);
    final amzDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    
    // 计算 payload hash
    final payloadHash = sha256.convert(payload).toString();
    
    // 虚拟主机风格的 host
    final host = '$bucketName.$endpoint';
    
    // 构建规范请求头
    final headers = <String, String>{
      'host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
    };
    
    if (contentType.isNotEmpty) {
      headers['content-type'] = contentType;
    }
    
    // 虚拟主机风格的规范 URI
    final canonicalUri = '/$objectKey';
    final canonicalQueryString = '';
    final canonicalHeaders = headers.entries
        .map((e) => '${e.key}:${e.value}')
        .toList()
        ..sort();
    final canonicalHeadersString = canonicalHeaders.join('\n');
    final signedHeaders = headers.keys.toList()..sort();
    final signedHeadersString = signedHeaders.join(';');
    
    final canonicalRequest = [
      method,
      canonicalUri,
      canonicalQueryString,
      canonicalHeadersString,
      '',
      signedHeadersString,
      payloadHash,
    ].join('\n');
    
    if (Get.isLogEnable) {
      Get.log('Canonical Request:\n$canonicalRequest');
    }
    
    // 创建字符串以签名
    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign = [
      algorithm,
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');
    
    if (Get.isLogEnable) {
      Get.log('String to Sign:\n$stringToSign');
    }
    
    // 计算签名
    final kDate = _hmacSha256('AWS4$secretAccessKey', dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, 's3');
    final kSigning = _hmacSha256(kService, 'aws4_request');
    final signature = _hmacSha256Hex(kSigning, stringToSign);
    
    // 构建 Authorization 头
    final authorization = '$algorithm Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeadersString, Signature=$signature';
    
    // 返回所有需要的头
    return {
      'Host': host,
      'Content-Type': contentType,
      'Content-Length': payload.length.toString(),
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'Authorization': authorization,
    };
  }

  /// HMAC-SHA256 计算
  List<int> _hmacSha256(dynamic key, String data) {
    final keyBytes = key is String ? utf8.encode(key) : key as List<int>;
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  /// HMAC-SHA256 计算并返回十六进制
  String _hmacSha256Hex(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }

  /// 删除文件
  Future<void> deleteFile(String objectKey) async {
    try {
      final url = 'https://$bucketName.$endpoint/$objectKey';
      
      final headers = await _generateAWSV4Headers(
        method: 'DELETE',
        bucketName: bucketName,
        objectKey: objectKey,
        contentType: '',
        payload: [],
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
      
      final headers = await _generateAWSV4Headers(
        method: 'HEAD',
        bucketName: bucketName,
        objectKey: objectKey,
        contentType: '',
        payload: [],
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