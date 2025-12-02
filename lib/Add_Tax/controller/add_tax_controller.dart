/*
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../model/add_tax_model.dart';
import 'package:task/api_endpoints.dart';

class AddTaxController extends GetxController {
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;
  var responseStatus = ''.obs;
  var responseMessage = ''.obs;

  /*Future<void> addTaxMethod(AddTaxModel addTax) async {
    try {
      isLoading.value = true;
      var request = http.MultipartRequest(
          'POST', Uri.parse(ApiConstants.addTaxEndPoint));
      request.fields.addAll(addTax.toJson());

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      responseStatus.value = jsonResponse['status'] ?? 'error';
      responseMessage.value = jsonResponse['message'] ?? 'Failed to add tax';
    } catch (e) {
      responseStatus.value = 'error';
      responseMessage.value = 'Failed to connect to server: $e';
    } finally {
      isLoading.value = false;
    }
  }*/
  Future<void> addTaxMethod(AddTaxModel addTax) async {
    try {
      isLoading.value = true;

      var request =
      http.MultipartRequest('POST', Uri.parse(ApiConstants.addTaxEndPoint));
      request.fields.addAll(addTax.toJson());

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      // Check HTTP status code and API response
      if (response.statusCode == 200) {
        responseStatus.value = jsonResponse['status'] ?? 'error';
        responseMessage.value = jsonResponse['message'] ?? 'Failed to add tax';

        if (responseStatus.value.toLowerCase() == 'success') {
          Fluttertoast.showToast(
            msg: 'Tax method added successfully',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to add tax: ${responseMessage.value}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
          );
        }
      } else {
        responseStatus.value = 'error';
        responseMessage.value = 'Failed with status code: ${response.statusCode}';
        Fluttertoast.showToast(
          msg: responseMessage.value,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
        );
      }
    } catch (e) {
      responseStatus.value = 'error';
      responseMessage.value = 'Failed to connect to server: $e';
      Fluttertoast.showToast(
        msg: responseMessage.value,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }
}*/
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../AddProducts/model/list_tax_model.dart';
import '../model/add_tax_model.dart';
import '../../api_endpoints.dart';

class AddTaxController extends GetxController {
  var taxes = <ListTaxModel>[].obs;
  var isLoading = false.obs;
  var responseStatus = ''.obs;
  var responseMessage = ''.obs;

  final formKey = GlobalKey<FormState>();

  // Fetch taxes
  Future<void> fetchTaxes({required String businessId}) async {
    isLoading.value = true;
    try {
      final url = Uri.parse('${ApiConstants.listTax}?business_id=$businessId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> jsonList;
        if (jsonData is List) {
          jsonList = jsonData;
        } else if (jsonData is Map) {
          jsonList = jsonData['data'] ?? [];
        } else {
          jsonList = [];
        }

        taxes.value = jsonList
            .map((json) => ListTaxModel.fromJson(json))
            .toList();
      } else {
        responseMessage.value = 'Failed to fetch taxes';
      }
    } catch (e) {
      responseMessage.value = 'Error fetching taxes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new tax
  Future<void> addTaxMethod(AddTaxModel tax) async {
    isLoading.value = true;
    try {
      final url = Uri.parse(ApiConstants.addTaxEndPoint);
      final response = await http.post(url, body: tax.toJson());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final status = json['status'] ?? 'Error';
        final message = json['message'] ?? '';

        responseStatus.value = status;
        responseMessage.value = message;

        // Show toast based on status
        Fluttertoast.showToast(
          msg: message.isNotEmpty ? message : (status == 'Success' ? 'Tax added successfully' : 'Failed to add tax'),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: status == 'Success' ? Colors.green : Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

      } else {
        responseStatus.value = 'Error';
        responseMessage.value = 'Failed to add tax: ${response.statusCode}';
        Fluttertoast.showToast(
          msg: 'Failed to add tax: ${response.statusCode}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      responseStatus.value = 'Error';
      responseMessage.value = 'Error adding tax: $e';
      Fluttertoast.showToast(
        msg: 'Error adding tax: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
