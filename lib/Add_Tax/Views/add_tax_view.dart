/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/add_tax_controller.dart';
import '../model/add_tax_model.dart';

class AddTaxView extends StatelessWidget {
  final String businessId;

  const AddTaxView({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controller
    final AddTaxController controller = Get.put(AddTaxController());

    // Initialize text controllers
    final taxTypeController = TextEditingController();
    final taxPercentageController = TextEditingController();
    final businessIdController = TextEditingController(text: businessId);

    // List of tax types for dropdown
    final List<String> taxTypes = ['CGST', 'IGST', 'SGST'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tax'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: null,
                  decoration: InputDecoration(
                    labelText: 'Tax type',
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
                    prefixIcon: const Icon(CupertinoIcons.money_pound_circle),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                  ),
                  items: taxTypes.map((String taxType) {
                    return DropdownMenuItem<String>(
                      value: taxType,
                      child: Text(taxType),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      taxTypeController.text = newValue;
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a tax type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: taxPercentageController,
                  decoration: InputDecoration(
                    labelText: 'Tax percentage',
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
                    prefixIcon: const Icon(Icons.percent),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a tax percentage';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
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
                        final addTax = AddTaxModel(
                          taxType: taxTypeController.text,
                          taxPercentage: taxPercentageController.text,
                          businessId: businessIdController.text,
                        );
                        await controller.addTaxMethod(addTax);
                        if (controller.responseStatus.value == 'Success') {
                          Get.snackbar(
                            'Success',
                            controller.responseMessage.value,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          taxTypeController.clear();
                          taxPercentageController.clear();
                        } else {
                          Get.snackbar(
                            'Error',
                            controller.responseMessage.value.isNotEmpty
                                ? controller.responseMessage.value
                                : 'Failed to add tax',
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
                    child: const Text('Add Tax'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/add_tax_controller.dart';
import '../model/add_tax_model.dart';

class AddTaxView extends StatelessWidget {
  final String businessId;

  const AddTaxView({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final AddTaxController controller = Get.put(AddTaxController());

    // Load taxes initially
    controller.fetchTaxes(businessId: businessId);

    final taxTypeController = TextEditingController();
    final taxPercentageController = TextEditingController();
    final businessIdController = TextEditingController(text: businessId);

    final List<String> taxTypes = ['CGST', 'IGST', 'SGST'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Taxes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Add Tax', icon: Icon(Icons.add)),
              Tab(text: 'Tax List', icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Add Tax Tab
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: null,
                        decoration: InputDecoration(
                          labelText: 'Tax type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                            BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                                color: Colors.orange, width: 2),
                          ),
                          prefixIcon:
                          const Icon(CupertinoIcons.money_pound_circle),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                        items: taxTypes.map((String taxType) {
                          return DropdownMenuItem<String>(
                            value: taxType,
                            child: Text(taxType),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            taxTypeController.text = newValue;
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a tax type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: taxPercentageController,
                        decoration: InputDecoration(
                          labelText: 'Tax percentage',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                            BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                                color: Colors.orange, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.percent),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a tax percentage';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
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
                            if (controller.formKey.currentState!
                                .validate()) {
                              final addTax = AddTaxModel(
                                taxType: taxTypeController.text,
                                taxPercentage: taxPercentageController.text,
                                businessId: businessIdController.text,
                              );
                              await controller.addTaxMethod(addTax);
                              if (controller.responseStatus.value ==
                                  'Success') {
                                Get.snackbar(
                                  'Success',
                                  controller.responseMessage.value,
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                                taxTypeController.clear();
                                taxPercentageController.clear();
                                await controller.fetchTaxes(
                                    businessId: businessId);
                              } else {
                                Get.snackbar(
                                  'Error',
                                  controller.responseMessage.value.isNotEmpty
                                      ? controller.responseMessage.value
                                      : 'Failed to add tax',
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
                          child: const Text('Add Tax'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tax List Tab
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.taxes.isEmpty) {
                return const Center(child: Text('No taxes found.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.taxes.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final tax = controller.taxes[index];
                  return ListTile(
                    //leading: const Icon(Icons.percent),
                    title: Text(tax.taxType),
                    subtitle: Text('${tax.taxPercentage}'),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
