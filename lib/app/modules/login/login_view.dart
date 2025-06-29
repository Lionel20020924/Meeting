import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    // 根据屏幕高度动态计算间距 - 不考虑键盘高度以保持固定布局
    final availableHeight = size.height - padding.top - padding.bottom;
    final isSmallScreen = availableHeight < 600; // 更严格的小屏判断
    final isCompact = availableHeight < 700; // 调整紧凑模式阈值
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 24.0,
              vertical: isSmallScreen ? 8.0 : 12.0,
            ),
            child: Column(
              children: [
                // 顶部空间 - 减少以适应固定布局
                SizedBox(height: isSmallScreen ? 4 : 8),
                
                // Logo Section - 更小的尺寸
                _buildLogoSection(context, isSmallScreen: isSmallScreen),
                
                // 最小间距
                const SizedBox(height: 8),
                
                // Login Card - 使用Expanded填充剩余空间
                Expanded(
                  child: _buildLoginCard(context, 
                    isSmallScreen: isSmallScreen,
                    isCompact: isCompact
                  ),
                ),
                
                // 底部留白 - 最小化
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, {bool isSmallScreen = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              // Animated Logo Container
              Container(
                width: isSmallScreen ? 60 : 80,
                height: isSmallScreen ? 60 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.meeting_room_rounded,
                    size: isSmallScreen ? 30 : 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Meetingly',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  fontSize: isSmallScreen ? 24 : 28,
                  shadows: [
                    Shadow(
                  color: Colors.black26,
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record and summarize your meetings',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isSmallScreen ? 14 : 16,
                  shadows: [
                    Shadow(
                  color: Colors.black26,
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard(BuildContext context, {bool isSmallScreen = false, bool isCompact = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Add delay effect
        final delayedValue = value < 0.3 ? 0.0 : (value - 0.3) / 0.7;
        return Transform.translate(
          offset: Offset(0, 50 * (1 - delayedValue)),
          child: Opacity(
            opacity: delayedValue,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Email field
                  Obx(() => _buildTextField(
                    controller: controller.emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: controller.emailError.value,
                    isValid: controller.isEmailValid.value,
                    isSmallScreen: isSmallScreen,
                  )),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Password field
                  Obx(() => _buildTextField(
                    controller: controller.passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscureText: !controller.showPassword.value,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.login(),
                    errorText: controller.passwordError.value,
                    isValid: controller.isPasswordValid.value,
                    isSmallScreen: isSmallScreen,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.showPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  )),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Remember me & Forgot password - 只在非小屏显示
                  if (!isSmallScreen) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Obx(() => Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor: Colors.white70,
                              ),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: controller.rememberMe.value,
                                  onChanged: (value) =>
                                      controller.rememberMe.value = value ?? false,
                                  checkColor: Theme.of(context).colorScheme.primary,
                                  fillColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
                              ),
                            )),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: controller.forgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 8),
                  
                  // Login button
                  _buildLoginButton(context, isSmallScreen: isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Quick login button - 移到登录按钮正下方，更显眼
                  _buildQuickLoginButton(context, isSmallScreen: isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 20),
                  
                  // Or divider - 简化样式
                  if (!isSmallScreen) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Social login buttons - 优化布局
                  if (!isSmallScreen)
                    _buildSocialLoginButtons(context, isCompact: isCompact)
                  else
                    _buildCompactSocialLogin(context),
                  
                  // Sign up - 简化并合并到底部
                  if (!isSmallScreen) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: controller.goToSignUp,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    Widget? suffixIcon,
    String? errorText,
    bool? isValid,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: errorText != null && errorText.isNotEmpty
                  ? Colors.red.withValues(alpha: 0.5)
                  : isValid == true
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: errorText != null && errorText.isNotEmpty ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: isSmallScreen ? 14 : 16,
              ),
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: isSmallScreen ? 14 : 16,
              ),
              prefixIcon: Icon(
                icon, 
                color: Colors.white70,
                size: isSmallScreen ? 20 : 24,
              ),
              suffixIcon: suffixIcon ?? (isValid == true
                  ? Icon(
                  Icons.check_circle, 
                  color: Colors.green.withValues(alpha: 0.7),
                  size: isSmallScreen ? 20 : 24,
                    )
                  : null),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20, 
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: errorText != null && errorText.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    errorText,
                    style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, {bool isSmallScreen = false}) {
    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isSmallScreen ? 48 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: controller.isLoading.value
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.8),
                ],
        ),
        boxShadow: controller.isLoading.value
            ? []
            : [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: MaterialButton(
        onPressed: controller.isLoading.value ? null : controller.login,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Login',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    ));
  }

  Widget _buildSocialLoginButtons(BuildContext context, {bool isCompact = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          onPressed: () => controller.socialLogin('google'),
          icon: Icons.g_mobiledata_rounded,
          label: isCompact ? '' : 'Google',
          color: Colors.red,
          isCompact: isCompact,
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          onPressed: () => controller.socialLogin('apple'),
          icon: Icons.apple,
          label: isCompact ? '' : 'Apple',
          color: Colors.white,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20,
          vertical: isCompact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isCompact ? 20 : 24),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 14 : 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // 快速登录按钮 - 更显眼的设计
  Widget _buildQuickLoginButton(BuildContext context, {bool isSmallScreen = false}) {
    return OutlinedButton.icon(
      onPressed: controller.quickLogin,
      icon: Icon(
        Icons.flash_on,
        color: Colors.amber,
        size: isSmallScreen ? 18 : 20,
      ),
      label: Text(
        'Quick Login (Dev)',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 24,
          vertical: isSmallScreen ? 10 : 12,
        ),
        side: BorderSide(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  // 紧凑的社交登录按钮组
  Widget _buildCompactSocialLogin(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Or login with',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => controller.socialLogin('google'),
                icon: Icon(
                  Icons.g_mobiledata_rounded,
                  color: Colors.red,
                  size: 24,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => controller.socialLogin('apple'),
                icon: Icon(
                  Icons.apple,
                  color: Colors.white,
                  size: 24,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}