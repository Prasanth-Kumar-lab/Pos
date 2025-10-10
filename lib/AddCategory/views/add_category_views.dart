import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/add_category_controller.dart';
import '../model/add_category_model.dart';

class AddCategoryView extends StatelessWidget {
  final String businessId;

  const AddCategoryView({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controller
    final AddCategoryController controller = Get.put(AddCategoryController());

    // Initialize text controllers
    final categoryNameController = TextEditingController();
    final businessIdController = TextEditingController(text: businessId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: categoryNameController,
                  decoration: InputDecoration(
                    labelText: 'Category name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                    prefixIcon: const Icon(CupertinoIcons.rectangle_grid_1x2),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Obx(
                      () => controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () async {
                      if (controller.formKey.currentState!.validate()) {
                        final category = CategoryModel(
                          categoryName: categoryNameController.text,
                          businessId: businessIdController.text,
                        );
                        await controller.addCategory(category);
                        if (controller.responseStatus.value == 'Success') {
                          Get.snackbar(
                            'Success',
                            controller.responseMessage.value,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          categoryNameController.clear();
                        } else {
                          Get.snackbar(
                            'Error',
                            controller.responseMessage.value.isNotEmpty
                                ? controller.responseMessage.value
                                : 'Failed to add category',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Add Category'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}