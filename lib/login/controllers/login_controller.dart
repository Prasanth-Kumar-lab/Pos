import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:task/home_screen/view/view.dart';
import '../../api_endpoints.dart';
import '../../profile/views/profile_buttons.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var obscurePassword = true.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> handleLogin() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;

      try {
        final response = await http.post(
          Uri.parse(ApiConstants.loginEndpoint),
          body: {
            'username': usernameController.text.trim(),
            'password': passwordController.text.trim(),
          },
        );

        final data = jsonDecode(response.body);
        if (data['status'] == 'Success') {
          isLoading.value = false;
          Get.snackbar(
            'Success',
            data['message'] ?? 'Login successful',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
          );

          // Extract data from API response
          final String name = data['name'] ?? 'User';
          final String mobileNumber = data['number'] ?? 'N/A';
          final String role = data['role'] ?? 'N/A';
          final String username = usernameController.text.trim();
          final String businessId = data['business_id'] ?? 'Not generated';
          final String user_id = data['id'] ?? 'N/A';

          // Navigate based on role
          if (role == 'Admin') {
            Get.offAll(() => ProfileButtons(
              name: name,
              username: username,
              mobileNumber: mobileNumber,
              businessId: businessId,
              role: role,
              user_id: user_id,
            )); // Navigate to ProfileButtons for Admin
          } else if (role == 'Biller') {
            Get.offAll(() => HomeScreen(
              name: name,
              username: username,
              mobileNumber: mobileNumber,
              businessId: businessId,
              role: role,
              user_id: user_id,
            )); // Navigate to HomeScreen for Biller
          } else {
            // Handle unexpected role
            Get.snackbar(
              'Error',
              'Invalid role: $role',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          isLoading.value = false;
          Get.snackbar(
            'Error',
            data['message'] ?? 'Login failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Something went wrong: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}