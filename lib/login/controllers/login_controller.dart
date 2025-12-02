import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  /*
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
  }*/
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

        isLoading.value = false;

        if (data['status'] == 'Success') {
          final String name = data['name'] ?? 'User';
          final String mobileNumber = data['number'] ?? 'N/A';
          final String role = data['role'] ?? 'N/A';
          final String username = usernameController.text.trim();
          final String businessId = data['business_id'] ?? 'Not generated';
          final String user_id = data['id']?.toString() ?? 'N/A';

          // Save user data
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
            Fluttertoast.showToast(
              msg: 'Welcome $name',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.shade600,
              textColor: Colors.white,
            );
            Get.offAll(() => ProfileButtons(
              name: name,
              username: username,
              mobileNumber: mobileNumber,
              businessId: businessId,
              role: role,
              user_id: user_id,
            ));
          } else if (role == 'Biller') {
            Fluttertoast.showToast(
              msg: 'Welcome $name',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.shade600,
              textColor: Colors.white,
            );
            Get.offAll(() => HomeScreen(
              name: name,
              username: username,
              mobileNumber: mobileNumber,
              businessId: businessId,
              role: role,
              user_id: user_id,
            ));
          } else {
            Fluttertoast.showToast(
              msg: 'Invalid role: $role',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red.shade600,
              textColor: Colors.white,
            );
          }
        } else {
          // ──────── FAILED LOGIN → SHOW ALERT DIALOG ────────
          String message = data['message'] ?? 'Login failed. Please try again.';

          if (message.toLowerCase().contains('no users found') ||
              message.toLowerCase().contains('user not found')) {
            message = 'Please check the details and login again';
          } else if (message.toLowerCase().contains('password')) {
            message = 'Please check the details and login again';
          }

          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Login Failed'),
                ],
              ),
              content: Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              actions: [
                /*TextButton(
                  onPressed: () => Get.back(), // Close dialog
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),*/
              ],
            ),
            barrierDismissible: true,
          );
        }
      } catch (e) {
        isLoading.value = false;
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Error'),
            content: const Text(
                'Unable to connect to server. Please check your internet connection.'),
            actions: [],
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear only user-specific keys, preserve printer settings
    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('username');
    await prefs.remove('mobileNumber');
    await prefs.remove('businessId');
    await prefs.remove('user_id');
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}