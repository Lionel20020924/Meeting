import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'audio_storage_interface.dart';
import 'audio_upload_service.dart';
import 'supabase_audio_storage_service.dart';

/// 音频存储服务工厂类
class AudioStorageFactory {
  static AudioStorageInterface? _instance;
  
  /// 获取音频存储服务实例
  static AudioStorageInterface getInstance() {
    if (_instance != null) {
      return _instance!;
    }
    
    // 检查是否应该使用 Supabase
    final useSupabase = dotenv.env['USE_SUPABASE_STORAGE']?.toLowerCase() == 'true';
    
    if (useSupabase) {
      if (Get.isLogEnable) {
        Get.log('Using Supabase Storage for audio files');
      }
      _instance = SupabaseAudioStorageService();
    } else {
      if (Get.isLogEnable) {
        Get.log('Using Volcano Engine TOS for audio files');
      }
      _instance = AudioUploadService();
    }
    
    return _instance!;
  }
  
  /// 清理并重新创建实例
  static void reset() {
    if (_instance != null) {
      _instance!.dispose();
      _instance = null;
    }
  }
  
  /// 强制使用特定的存储服务
  static void forceUseSupabase() {
    reset();
    if (Get.isLogEnable) {
      Get.log('Forcing use of Supabase Storage');
    }
    _instance = SupabaseAudioStorageService();
  }
  
  /// 强制使用火山引擎 TOS
  static void forceUseTOS() {
    reset();
    if (Get.isLogEnable) {
      Get.log('Forcing use of Volcano Engine TOS');
    }
    _instance = AudioUploadService();
  }
}