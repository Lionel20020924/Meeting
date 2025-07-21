import 'dart:io';
import 'dart:async';

/// 音频存储服务接口
abstract class AudioStorageInterface {
  /// 上传进度流
  Stream<double> get uploadProgress;
  
  /// 上传音频文件
  /// 返回可访问的 URL
  Future<String> uploadAudioFile(File audioFile, {String? meetingId});
  
  /// 生成预签名 URL
  Future<String> generatePresignedUrl(String filePath, {int expires = 3600});
  
  /// 删除音频文件
  Future<void> deleteAudioFile(String filePath);
  
  /// 检查文件是否存在
  Future<bool> fileExists(String filePath);
  
  /// 清理资源
  void dispose();
}