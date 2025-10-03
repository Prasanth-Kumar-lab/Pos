import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../api_endpoints.dart';
import '../model/profile_model.dart';
import 'package:flutter/material.dart';
class ProfileController extends GetxController {
  var profile = Rxn<Profile>();
  final String userId;
  final String role;

  ProfileController({required this.userId, required this.role});
  var isPasswordVisible = false.obs;
  var editPasswordVisible = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleEditPasswordVisibility() {
    editPasswordVisible.value = !editPasswordVisible.value;
  }
  Future<void> fetchProfile() async {
    final url = Uri.parse('${ApiConstants.profileEndPoint}?user_id=$userId&role=$role');
    var request = http.MultipartRequest('POST', url);
    request.fields['user_id'] = userId;
    request.fields['role'] = role;

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (jsonList.isNotEmpty) {
          profile.value = Profile.fromJson(jsonList.first);
        } else {
          Get.snackbar('Error', 'No profile data found');
        }
      } else {
        Get.snackbar('Error', 'Failed to fetch profile');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching profile: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    String? password,
    required String mobileNumber,
    required String role,
    required String aadharNumber,
    required String address,
  }) async {
    final url = Uri.parse(ApiConstants.updateProfiileEndPoint);
    var request = http.MultipartRequest('POST', url);

    request.fields['user_id'] = userId;
    request.fields['name'] = name;
    request.fields['username'] = username;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }
    request.fields['number'] = mobileNumber;
    request.fields['role'] = role;
    request.fields['aadhar_number'] = aadharNumber;
    request.fields['address'] = address;

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Assuming the API returns a list like fetchProfile
        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          profile.value = Profile.fromJson(jsonResponse.first);
        } else if (jsonResponse is Map<String, dynamic>) {
          profile.value = Profile.fromJson(jsonResponse);
        } else {
          Get.snackbar('Error', 'Invalid response format');
          return;
        }
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update profile: ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error updating profile: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}