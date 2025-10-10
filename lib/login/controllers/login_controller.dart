import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api_endpoints.dart';
import '../../home_screen/view/view.dart';
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

          final String name = data['name'] ?? 'User';
          final String mobileNumber = data['number'] ?? 'N/A';
          final String role = data['role'] ?? 'N/A';
          final String username = usernameController.text.trim();
          final String businessId = data['business_id'] ?? 'Not generated';
          final String user_id = data['id'] ?? 'N/A';

          // Save user data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('role', role);
          await prefs.setString('name', name);
          await prefs.setString('username', username);
          await prefs.setString('mobileNumber', mobileNumber);
          await prefs.setString('businessId', businessId);
          await prefs.setString('user_id', user_id);

          // Navigate based on role
          if (role == 'Admin') {
            Get.offAll(() => ProfileButtons(
              name: name,
              username: username,
              mobileNumber: mobileNumber,
              businessId: businessId,
              role: role,
              user_id: user_id,
            ));
          } else if (role == 'Biller') {
            Get.offAll(() => HomeScreen(
              name: name,
              username: username,
              mobileNumber: mobileNumber,
              businessId: businessId,
              role: role,
              user_id: user_id,
            ));
          } else {
            Get.snackbar(
              'Error',
              'Invalid role: $role',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          isLoading.value = false;
          Get.snackbar(
            'Error',
            data['message'] ?? 'Login failed',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Something went wrong: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
