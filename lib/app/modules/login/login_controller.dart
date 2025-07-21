import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../routes/app_pages.dart';
import '../../services/supabase_auth_service.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  
  final isLoading = false.obs;
  final otpSent = false.obs;
  final countdown = 0.obs;
  Timer? _countdownTimer;
  
  // Validation states
  final emailError = ''.obs;
  final otpError = ''.obs;
  final isEmailValid = false.obs;
  final isOtpValid = false.obs;
  
  // Auth service
  final SupabaseAuthService _authService = Get.put(SupabaseAuthService());

  @override
  void onInit() {
    super.onInit();
    
    // Clear any existing state first
    _clearState();
    
    // Add listeners for real-time validation
    emailController.addListener(_validateEmail);
    otpController.addListener(_validateOtp);
  }
  
  void _clearState() {
    // Reset all states to initial values
    isLoading.value = false;
    otpSent.value = false;
    countdown.value = 0;
    emailError.value = '';
    otpError.value = '';
    isEmailValid.value = false;
    isOtpValid.value = false;
    
    // Clear text controllers
    emailController.clear();
    otpController.clear();
    
    // Cancel countdown timer
    _countdownTimer?.cancel();
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> sendOtp() async {
    if (!isEmailValid.value) {
      emailError.value = 'Please enter a valid email';
      return;
    }
    
    isLoading.value = true;
    try {
      await _authService.sendOTP(emailController.text.trim());
      otpSent.value = true;
      _startCountdown();
      
      Get.snackbar(
        'Verification Code Sent',
        'Please check your email for the verification code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!isOtpValid.value) {
      otpError.value = 'Please enter a valid 6-digit code';
      return;
    }
    
    isLoading.value = true;
    try {
      final response = await _authService.verifyOTP(
        email: emailController.text.trim(),
        token: otpController.text.trim(),
      );
      
      if (response.user != null) {
        Get.offAllNamed(Routes.HOME);
      }
    } catch (e) {
      otpError.value = 'Invalid verification code';
      Get.snackbar(
        'Verification Failed',
        'The verification code is invalid or expired',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    if (!otpSent.value) {
      await sendOtp();
    } else {
      await verifyOtp();
    }
  }
  
  void resendOtp() {
    if (countdown.value == 0) {
      sendOtp();
    }
  }

  void quickLogin() {
    // For debug purposes, skip authentication
    if (Get.isLogEnable) {
      Get.log('Quick login - skipping authentication');
    }
    Get.offAllNamed(Routes.HOME);
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
  
  void _validateOtp() {
    final otp = otpController.text;
    if (otp.isEmpty) {
      otpError.value = '';
      isOtpValid.value = false;
    } else if (otp.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(otp)) {
      otpError.value = 'Please enter a valid 6-digit code';
      isOtpValid.value = false;
    } else {
      otpError.value = '';
      isOtpValid.value = true;
    }
  }
  
  bool validateForm() {
    if (!otpSent.value) {
      _validateEmail();
      if (emailController.text.isEmpty) {
        emailError.value = 'Email is required';
      }
      return isEmailValid.value;
    } else {
      _validateOtp();
      if (otpController.text.isEmpty) {
        otpError.value = 'Verification code is required';
      }
      return isOtpValid.value;
    }
  }
}