import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../model/add_category_model.dart';
import 'package:task/api_endpoints.dart';

class AddCategoryController extends GetxController {
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;
  var responseStatus = ''.obs;
  var responseMessage = ''.obs;

  Future<void> addCategory(CategoryModel category) async {
    try {
      isLoading.value = true;
      var request = http.MultipartRequest(
          'POST', Uri.parse(ApiConstants.addCategoryEndPoint));
      request.fields.addAll(category.toJson());

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      responseStatus.value = jsonResponse['status'] ?? 'error';
      responseMessage.value = jsonResponse['message'] ?? 'Failed to add category';
    } catch (e) {
      responseStatus.value = 'error';
      responseMessage.value = 'Failed to connect to server: $e';
    } finally {
      isLoading.value = false;
    }
  }
}