import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/system_settings_controller.dart';
import '../widgets/Circular_fields.dart';

class AddSystemSettingsView extends StatelessWidget {
  const AddSystemSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SystemSettingsController());
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add System Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                /// Business ID (ReadOnly)
                CircularInputField(
                  controller: controller.businessIdController,
                  labelText: 'Business ID',
                  readOnly: true,
                  fillColor: Colors.orange.shade100,
                ),
                const SizedBox(height: 16),

                /// Bill Prefix
                CircularInputField(
                  controller: controller.billPrefixController,
                  labelText: 'Bill Prefix',
                  hintText: 'Enter bill prefix (e.g., INV)',
                  validator: (value) => controller.validateField(value, 'bill prefix'),
                ),
                const SizedBox(height: 16),

                /// Quote
                CircularInputField(
                  controller: controller.quoteController,
                  labelText: 'Quote',
                  hintText: 'Enter quote',
                  validator: (value) => controller.validateField(value, 'quote'),
                ),
                const SizedBox(height: 16),

                /// Firm Name
                CircularInputField(
                  controller: controller.firmNameController,
                  labelText: 'Firm Name',
                  hintText: 'Enter firm name',
                  validator: (value) => controller.validateField(value, 'firm name'),
                ),
                const SizedBox(height: 16),

                /// Firm Contact 1
                CircularInputField(
                  controller: controller.firmContact1Controller,
                  labelText: 'Firm Contact 1',
                  hintText: 'Enter primary contact number',
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      controller.validateField(value, 'primary contact number'),
                ),
                const SizedBox(height: 16),

                /// Firm Contact 2
                CircularInputField(
                  controller: controller.firmContact2Controller,
                  labelText: 'Firm Contact 2',
                  hintText: 'Enter secondary contact number (optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                /// File
                CircularInputField(
                  controller: controller.fileController,
                  labelText: 'File',
                  hintText: 'Enter file name or path',
                  validator: (value) =>
                      controller.validateField(value, 'file name or path'),
                ),
                const SizedBox(height: 16),

                /// Bill Address
                CircularInputField(
                  controller: controller.billAddressController,
                  labelText: 'Bill Address',
                  hintText: 'Enter billing address',
                  maxLines: 3,
                  validator: (value) =>
                      controller.validateField(value, 'billing address'),
                ),
                const SizedBox(height: 16),

                /// GSTIN Number
                CircularInputField(
                  controller: controller.billGstinNumController,
                  labelText: 'Bill GSTIN Number',
                  hintText: 'Enter GSTIN number',
                  validator: (value) =>
                      controller.validateField(value, 'GSTIN number'),
                ),
                const SizedBox(height: 24),

                /// Save Button
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.saveSystemSettings(formKey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Circular button
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )),
                const SizedBox(height: 24),

                /// Saved Data
                Obx(() => controller.savedData.value != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved System Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Business ID: ${controller.savedData.value!['business_id']}'),
                            const SizedBox(height: 8),
                            Text('Bill Prefix: ${controller.savedData.value!['bill_prefix']}'),
                            const SizedBox(height: 8),
                            Text('Quote: ${controller.savedData.value!['quote']}'),
                            const SizedBox(height: 8),
                            Text('Firm Name: ${controller.savedData.value!['firm_name']}'),
                            const SizedBox(height: 8),
                            Text('Firm Contact 1: ${controller.savedData.value!['firm_contact1']}'),
                            const SizedBox(height: 8),
                            Text('Firm Contact 2: ${controller.savedData.value!['firm_contact2']}'),
                            const SizedBox(height: 8),
                            Text('File: ${controller.savedData.value!['file']}'),
                            const SizedBox(height: 8),
                            Text('Bill Address: ${controller.savedData.value!['bill_address']}'),
                            const SizedBox(height: 8),
                            Text('Bill GSTIN Number: ${controller.savedData.value!['bill_gstin_num']}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


