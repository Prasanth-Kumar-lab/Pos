import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:task/AddBiller/model/add_biller_model.dart';
import 'package:task/api_endpoints.dart';

class AddBillerController extends GetxController {

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final aadharNumberController = TextEditingController();
  final addressController = TextEditingController();
  final businessIdController = TextEditingController();

  var isLoading = false.obs;
  var obscurePassword = true.obs;

  @override
  void onClose() {
    nameController.dispose();
    mobileNumberController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    aadharNumberController.dispose();
    addressController.dispose();
    businessIdController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  Future<void> handleSignup() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;

      final user = AddBillerModel(
        name: nameController.text.trim(),
        mobileNumber: mobileNumberController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        role: 'Biller',
        aadharNumber: aadharNumberController.text.trim(),
        address: addressController.text.trim(),
        businessId: businessIdController.text.trim(),
      );

      try {
        final response = await http.post(
          Uri.parse(ApiConstants.signUpEndpoint),
          body: user.toJson(),
        );

        isLoading.value = false;

        if (response.statusCode == 200) {
          // ✅ Show success message
          Fluttertoast.showToast(
            msg: "Your biller account has been created successfully!",
            toastLength: Toast.LENGTH_SHORT, // LENGTH_SHORT ≈ 3 seconds
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.shade600,
            textColor: Colors.white,
            fontSize: 16.0,
          );


          //  Reset all input fields
          nameController.clear();
          mobileNumberController.clear();
          usernameController.clear();
          passwordController.clear();
          aadharNumberController.clear();
          addressController.clear();
          // Keep businessIdController as it is since it's pre-filled.

          //  Reset the form state
          formKey.currentState!.reset();

          //  Optionally navigate back or stay on the page
          // Get.offAll(() => LoginScreen());
        } else {
          //Get.snackbar(
            //'Error',
            //'Sign Up Failed: ${response.body}',
            //snackPosition: SnackPosition.BOTTOM,
            //backgroundColor: Colors.red,
            //colorText: Colors.white,
          //);
          Fluttertoast.showToast(
            msg: "Error SignUp failed! ${response.body}",
            toastLength: Toast.LENGTH_SHORT, // LENGTH_SHORT ≈ 3 seconds
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.shade600,
            textColor: Colors.white,
            fontSize: 16.0,
          );

        }
      } catch (e) {
        isLoading.value = false;
        //Get.snackbar(
          //'Error',
          //'An error occurred: $e',
          //snackPosition: SnackPosition.BOTTOM,
          //backgroundColor: Colors.red,
          //colorText: Colors.white,
        //);
        Fluttertoast.showToast(
          msg: "Error, An error occured! $e",
          toastLength: Toast.LENGTH_SHORT, // LENGTH_SHORT ≈ 3 seconds
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
          fontSize: 16.0,
        );

      }
    }
  }
}