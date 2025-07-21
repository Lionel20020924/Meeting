import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 认证服务
class SupabaseAuthService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // 当前用户状态
  final Rxn<User> currentUser = Rxn<User>();
  
  // 认证状态流
  late final StreamSubscription<AuthState> _authStateSubscription;
  
  @override
  void onInit() {
    super.onInit();
    
    // 监听认证状态变化
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (Get.isLogEnable) {
        Get.log('Auth state changed: $event');
      }
      
      // 更新当前用户
      currentUser.value = session?.user;
      
      // 处理不同的认证事件
      switch (event) {
        case AuthChangeEvent.signedIn:
          if (Get.isLogEnable) {
            Get.log('User signed in: ${session?.user.email}');
          }
          break;
        case AuthChangeEvent.signedOut:
          if (Get.isLogEnable) {
            Get.log('User signed out');
          }
          break;
        case AuthChangeEvent.userUpdated:
          if (Get.isLogEnable) {
            Get.log('User updated: ${session?.user.email}');
          }
          break;
        default:
          break;
      }
    });
    
    // 检查现有会话
    final session = _supabase.auth.currentSession;
    currentUser.value = session?.user;
  }
  
  /// 发送邮箱验证码（OTP）
  Future<void> sendOTP(String email) async {
    try {
      if (Get.isLogEnable) {
        Get.log('Sending OTP to: $email');
      }
      
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true, // 如果用户不存在则自动创建
      );
      
      if (Get.isLogEnable) {
        Get.log('OTP sent successfully to $email');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error sending OTP: $e');
      }
      rethrow;
    }
  }
  
  /// 使用邮箱和验证码登录
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      if (Get.isLogEnable) {
        Get.log('Verifying OTP for: $email');
      }
      
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );
      
      if (response.user != null) {
        if (Get.isLogEnable) {
          Get.log('OTP verified successfully for ${response.user!.email}');
        }
        
        // 检查是否是新用户
        final createdAt = DateTime.parse(response.user!.createdAt);
        final isNewUser = DateTime.now().difference(createdAt).inMinutes.abs() < 1;
        if (isNewUser) {
          if (Get.isLogEnable) {
            Get.log('New user created: ${response.user!.email}');
          }
          
          // 为新用户创建默认配置
          await _createDefaultUserProfile(response.user!);
        }
      }
      
      return response;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error verifying OTP: $e');
      }
      rethrow;
    }
  }
  
  /// 登出
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      currentUser.value = null;
      
      if (Get.isLogEnable) {
        Get.log('User signed out successfully');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error signing out: $e');
      }
      rethrow;
    }
  }
  
  /// 获取当前会话
  Session? get currentSession => _supabase.auth.currentSession;
  
  /// 检查是否已登录
  bool get isAuthenticated => currentUser.value != null;
  
  /// 获取当前用户ID
  String? get userId => currentUser.value?.id;
  
  /// 获取当前用户邮箱
  String? get userEmail => currentUser.value?.email;
  
  /// 更新用户元数据
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );
      
      if (Get.isLogEnable) {
        Get.log('User metadata updated: $data');
      }
      
      return response;
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error updating user metadata: $e');
      }
      rethrow;
    }
  }
  
  /// 创建默认用户配置
  Future<void> _createDefaultUserProfile(User user) async {
    try {
      // 创建默认用户配置
      final defaultProfile = {
        'display_name': user.email?.split('@').first ?? 'User',
        'avatar_url': null,
        'preferences': {
          'theme': 'system',
          'language': 'zh-CN',
          'notifications': true,
        },
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await updateUserMetadata(defaultProfile);
      
      if (Get.isLogEnable) {
        Get.log('Default user profile created for ${user.email}');
      }
    } catch (e) {
      if (Get.isLogEnable) {
        Get.log('Error creating default user profile: $e');
      }
      // 不抛出异常，避免影响登录流程
    }
  }
  
  @override
  void onClose() {
    _authStateSubscription.cancel();
    super.onClose();
  }
  
  /// 获取 SupabaseAuthService 实例
  static SupabaseAuthService get to => Get.find<SupabaseAuthService>();
}