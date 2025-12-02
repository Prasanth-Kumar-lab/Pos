/*
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
}*/
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../AddProducts/model/list_product_category_fetch.dart';
import '../model/add_category_model.dart';
import 'package:task/api_endpoints.dart';

class AddCategoryController extends GetxController {
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;
  var responseStatus = ''.obs;
  var responseMessage = ''.obs;
  var categories = <CategoryModel>[].obs;
  final String businessId;

  AddCategoryController({required this.businessId});

  /*
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
      responseMessage.value =
          jsonResponse['message'] ?? 'Failed to add category';
    } catch (e) {
      responseStatus.value = 'error';
      responseMessage.value = 'Failed to connect to server: $e';
    } finally {
      isLoading.value = false;
    }
  }*/
  Future<void> addCategory(CategoryModel category) async {
    try {
      isLoading.value = true;

      var request =
      http.MultipartRequest('POST', Uri.parse(ApiConstants.addCategoryEndPoint));
      request.fields.addAll(category.toJson());

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      // Check HTTP status code and API response
      if (response.statusCode == 200) {
        responseStatus.value = jsonResponse['status'] ?? 'error';
        responseMessage.value =
            jsonResponse['message'] ?? 'Failed to add category';

        if (responseStatus.value.toLowerCase() == 'success') {
          Fluttertoast.showToast(
            msg: 'Category added successfully',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to add category: ${responseMessage.value}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        responseStatus.value = 'error';
        responseMessage.value = 'Failed with status code: ${response.statusCode}';
        Fluttertoast.showToast(
          msg: responseMessage.value,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      responseStatus.value = 'error';
      responseMessage.value = 'Failed to connect to server: $e';
      Fluttertoast.showToast(
        msg: responseMessage.value,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    if (businessId.isEmpty) {
      Get.snackbar('Error', 'Business ID is missing');
      return;
    }

    final url = Uri.parse('${ApiConstants.listProductCategory}?business_id=$businessId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        categories.value =
            jsonList.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: Please ask admin to add');
    }
  }
}
