import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/supabase_auth_service.dart';

/// 认证中间件 - 用于保护需要登录的路由
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<SupabaseAuthService>();
    
    // 检查是否已登录
    if (!authService.isAuthenticated) {
      // 如果未登录且不是登录页，重定向到登录页
      if (route != Routes.LOGIN) {
        return const RouteSettings(name: Routes.LOGIN);
      }
    } else {
      // 如果已登录且是登录页，重定向到首页
      if (route == Routes.LOGIN) {
        return const RouteSettings(name: Routes.HOME);
      }
    }
    
    return null;
  }
  
  @override
  GetPage? onPageCalled(GetPage? page) {
    if (Get.isLogEnable) {
      Get.log('AuthMiddleware: Checking access to ${page?.name}');
    }
    return page;
  }
}