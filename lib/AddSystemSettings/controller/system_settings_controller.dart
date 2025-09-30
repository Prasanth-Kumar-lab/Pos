import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/system_settings_model.dart';

class SystemSettingsController extends GetxController {
  final TextEditingController billPrefixController = TextEditingController();
  final TextEditingController quoteController = TextEditingController();
  final TextEditingController firmNameController = TextEditingController();
  final TextEditingController firmContact1Controller = TextEditingController();
  final TextEditingController firmContact2Controller = TextEditingController();
  final TextEditingController fileController = TextEditingController();
  final TextEditingController billAddressController = TextEditingController();
  final TextEditingController billGstinNumController = TextEditingController();
  final TextEditingController businessIdController = TextEditingController();

  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> savedData = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    // Initialize businessId from passed argument
    final String businessId = Get.arguments['businessId'] ?? '';
    businessIdController.text = businessId;
  }

  @override
  void onClose() {
    billPrefixController.dispose();
    quoteController.dispose();
    firmNameController.dispose();
    firmContact1Controller.dispose();
    firmContact2Controller.dispose();
    fileController.dispose();
    billAddressController.dispose();
    billGstinNumController.dispose();
    businessIdController.dispose();
    super.onClose();
  }

  String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  Future<void> saveSystemSettings(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    final model = SystemSettingsModel(
      billPrefix: billPrefixController.text,
      quote: quoteController.text,
      firmName: firmNameController.text,
      firmContact1: firmContact1Controller.text,
      firmContact2: firmContact2Controller.text,
      file: fileController.text,
      billAddress: billAddressController.text,
      billGstinNum: billGstinNumController.text,
      businessId: businessIdController.text,
    );

    final result = await model.saveSettings();

    isLoading.value = false;

    // Debug: Log result
    print('Model Result Status: ${result['status']}');
    print('Model Result Message: ${result['message']}');

    if (result['status'] == 'success') {
      savedData.value = result['data'];
      Get.snackbar(
        'Success',
        result['message'], // e.g., "System Settings Updated"
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'], // Only use model's error message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }
}