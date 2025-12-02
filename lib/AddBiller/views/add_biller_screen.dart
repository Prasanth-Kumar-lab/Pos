import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:task/AddBiller/controller/add_biller_controller.dart';
import '../../../login/widgets/custom_text_field_and_button.dart';
import '../../BillersListStatus/view/billers_view.dart';

class AddBillerScreen extends StatefulWidget {
  final String businessId;
  const AddBillerScreen({Key? key, required this.businessId}) : super(key: key);

  @override
  _AddBillerScreenState createState() => _AddBillerScreenState();
}

class _AddBillerScreenState extends State<AddBillerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AddBillerController addController = Get.put(AddBillerController());
  final BillerController billerController = Get.put(BillerController(), tag: 'billerController');

  @override
  void initState() {
    super.initState();
    addController.businessIdController.text = widget.businessId; // Set initial businessId
    billerController.initialize(widget.businessId); // Initialize biller list with businessId
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Controller disposal is handled in respective controllers' onClose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Billers'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'Add Biller'),
              Tab(text: 'Added Billers'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Add Biller Tab
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: addController.formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          'Create Account For Biller',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomTextField(
                          controller: addController.nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: addController.mobileNumberController,
                          label: 'Mobile Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                              return 'Please enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: addController.usernameController,
                          label: 'Username',
                          icon: Icons.account_circle_outlined,
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter your username' : null,
                        ),
                        const SizedBox(height: 16),
                        Obx(() => CustomTextField(
                          controller: addController.passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: addController.obscurePassword.value,
                          suffixIcon: IconButton(
                            icon: Icon(
                              addController.obscurePassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black54,
                            ),
                            onPressed: addController.togglePasswordVisibility,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        )),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: addController.addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter your address' : null,
                        ),
                        const SizedBox(height: 24),
                        Obx(() => CustomButton(
                          text: 'Add Biller',
                          isLoading: addController.isLoading.value,
                          onPressed: addController.handleSignup,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Added Billers Tab
            Obx(() {
              if (billerController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (billerController.billers.isEmpty) {
                return _StatusMessage(
                  icon: Icons.inbox,
                  message: 'No billers found for this business.',
                  onRetry: billerController.fetchBillers,
                  retryText: 'Refresh',
                );
              } else {
                return RefreshIndicator(
                  onRefresh: billerController.fetchBillers,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: billerController.billers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final biller = billerController.billers[index];
                      final isUpdating = billerController.isUpdating(biller.billerId);
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.3),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(
                            biller.billerName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.black),
                          onTap: () {
                            Get.snackbar(
                              'Biller Selected',
                              biller.billerName,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.shade700,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(12),
                              borderRadius: 8,
                              duration: const Duration(seconds: 2),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}

/// Widget to show empty or error state with optional retry
class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  const _StatusMessage({
    Key? key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}