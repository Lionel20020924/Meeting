import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false, // 防止键盘弹出时调整布局
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              
              // Logo and App Name
              _buildLogoSection(context),
              
              const SizedBox(height: 50),
              
              // Login Form - 使用 Expanded 来填充剩余空间
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _buildLoginForm(context),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Column(
      children: [
        // Logo with gradient shadow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1), // Indigo
                Color(0xFF8B5CF6), // Purple
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.record_voice_over_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 28),
        
        // App Name
        const Text(
          'Recme',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          'Smart meeting recorder & transcriber',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => TextFormField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: controller.emailError.value.isNotEmpty 
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 1.5,
                    ),
                  ),
                  errorText: controller.emailError.value.isEmpty 
                    ? null 
                    : controller.emailError.value,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              )),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Password Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => TextFormField(
                controller: controller.passwordController,
                obscureText: !controller.showPassword.value,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => controller.login(),
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    letterSpacing: 2,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.showPassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: controller.passwordError.value.isNotEmpty 
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 1.5,
                    ),
                  ),
                  errorText: controller.passwordError.value.isEmpty 
                    ? null 
                    : controller.passwordError.value,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              )),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Remember me and Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember me
              Row(
                children: [
                  Obx(() => SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: (value) => 
                          controller.rememberMe.value = value ?? false,
                      activeColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              // Forgot password
              TextButton(
                onPressed: controller.forgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Login Button
          Obx(() => SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Sign up section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account?",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: controller.goToSignUp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Dev Quick Login (optional)
          if (Get.isLogEnable) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: controller.quickLogin,
                icon: const Icon(
                  Icons.developer_mode,
                  size: 18,
                  color: Colors.grey,
                ),
                label: Text(
                  'Quick Login (Dev)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}