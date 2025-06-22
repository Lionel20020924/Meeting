import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final showPassword = false.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;
  
  // Validation states
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final isEmailValid = false.obs;
  final isPasswordValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load saved email if remember me was checked
    loadSavedCredentials();
    
    // Add listeners for real-time validation
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  void loadSavedCredentials() {
    // TODO: Load saved credentials from local storage
    // Example: emailController.text = savedEmail;
  }

  void forgotPassword() {
    Get.snackbar(
      'Forgot Password',
      'Password reset link will be sent to your email',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void socialLogin(String provider) {
    Get.snackbar(
      'Social Login',
      'Login with $provider will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void goToSignUp() {
    Get.snackbar(
      'Sign Up',
      'Sign up functionality will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> login() async {
    if (!validateForm()) {
      return;
    }

    isLoading.value = true;
    
    try {
      // TODO: Implement actual login logic
      await Future.delayed(const Duration(seconds: 2));
      
      // Save credentials if remember me is checked
      if (rememberMe.value) {
        // TODO: Save credentials to local storage
      }
      
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void quickLogin() {
    // Fill in test credentials
    emailController.text = 'test@example.com';
    passwordController.text = 'password123';
    
    // Show quick message
    Get.snackbar(
      'Debug Mode',
      'Using test credentials',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
    
    // Perform login after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAllNamed(Routes.HOME);
    });
  }
  
  // Validation methods
  void _validateEmail() {
    final email = emailController.text;
    if (email.isEmpty) {
      emailError.value = '';
      isEmailValid.value = false;
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email';
      isEmailValid.value = false;
    } else {
      emailError.value = '';
      isEmailValid.value = true;
    }
  }
  
  void _validatePassword() {
    final password = passwordController.text;
    if (password.isEmpty) {
      passwordError.value = '';
      isPasswordValid.value = false;
    } else if (password.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isPasswordValid.value = false;
    } else {
      passwordError.value = '';
      isPasswordValid.value = true;
    }
  }
  
  bool validateForm() {
    _validateEmail();
    _validatePassword();
    
    if (emailController.text.isEmpty) {
      emailError.value = 'Email is required';
    }
    if (passwordController.text.isEmpty) {
      passwordError.value = 'Password is required';
    }
    
    return isEmailValid.value && isPasswordValid.value;
  }
}