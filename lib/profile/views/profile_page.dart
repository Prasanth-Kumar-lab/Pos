import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../login/views/login_screen.dart';
import '../controller/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  final String businessId;
  final String user_id;
  final String role;

  const ProfilePage({
    Key? key,
    required this.businessId,
    required this.user_id,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController(userId: user_id, role: role));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade900,
          ),
        ),
        backgroundColor: Colors.orange.withOpacity(0.6),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blueGrey.shade900),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Obx(() {
          if (controller.profile.value == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            );
          }
          final data = controller.profile.value!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(data.name, data.username),
                const SizedBox(height: 24),
                _buildProfileDetails(data, businessId, user_id, role, controller),
                const SizedBox(height: 24),
                _buildActionButtons(context, controller),
              ],
            ),
          );
        }),
      ),
    );
  }
  Widget _buildProfileHeader(String? name, String? username) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            child: Icon(Icons.person, size: 60, color: Colors.blueGrey.shade900),
          ),
          const SizedBox(height: 16),
          Text(
            name!.isEmpty ? 'No Name Provided' : name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            username!.isEmpty ? 'No Username Provided' : username,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(data, String businessId, String userId, String role, ProfileController controller) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200, width: 1),
      ),
      color: Colors.orange.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User ID:', userId),
            _buildDetailRow('Mobile Number:', data.mobileNumber!.isEmpty ? 'Not Provided' : data.mobileNumber!),
            _buildDetailRow('Address:', data.address!.isEmpty ? 'Not Provided' : data.address!),
            _buildDetailRow('Business ID:', businessId),
            _buildDetailRow('Role:', data.role!.isEmpty ? role : data.role!),
            _buildPasswordRow(controller, data.password!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade900,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow(ProfileController controller, String actualPassword) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Password:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade900,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use Obx only for the specific reactive part
                Obx(() => Text(
                  actualPassword.isEmpty
                      ? 'Not Set'
                      : (controller.isPasswordVisible.value ? actualPassword : '********'),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontFamily: controller.isPasswordVisible.value ? null : 'monospace',
                  ),
                )),
                if (actualPassword.isNotEmpty) // Only show eye icon if password exists
                  Obx(() => GestureDetector(
                    onTap: () {
                      controller.togglePasswordVisibility();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileController controller) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _showEditProfileDialog(context, controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text(
                    'Confirm Logout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // Clear all saved login data

                          Get.offAll(() => const LoginScreen()); // Navigate to login screen

                        Get.snackbar(
                          'Logged Out',
                          'You have been logged out successfully.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                barrierDismissible: false,
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileController controller) {
    final profile = controller.profile.value;
    final nameController = TextEditingController(text: profile?.name ?? '');
    final usernameController = TextEditingController(text: profile?.username ?? '');
    final passwordController = TextEditingController(text: profile?.password ?? '');
    final mobileNumberController = TextEditingController(text: profile?.mobileNumber ?? '');
    final roleController = TextEditingController(text: profile?.role ?? role);
    final addressController = TextEditingController(text: profile?.address ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    errorText: null,
                  ),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    errorText: null,
                  ),
                ),
                Obx(() => TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password (optional, min 8 characters)',
                    errorText: null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.editPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blueGrey.shade900,
                      ),
                      onPressed: () {
                        controller.toggleEditPasswordVisibility();
                      },
                    ),
                  ),
                  obscureText: !controller.editPasswordVisible.value,
                )),
                TextField(
                  controller: mobileNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    errorText: null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    errorText: null,
                  ),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    errorText: null,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Basic validation
              if (nameController.text.isEmpty ||
                  usernameController.text.isEmpty ||
                  mobileNumberController.text.isEmpty ||
                  roleController.text.isEmpty ||
                  addressController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please fill all required fields',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              // Password validation (optional, but if provided, must be at least 8 characters)
              if (passwordController.text.isNotEmpty && passwordController.text.length < 8) {
                Get.snackbar(
                  'Error',
                  'Password must be at least 8 characters long',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              await controller.updateProfile(
                name: nameController.text,
                username: usernameController.text,
                password: passwordController.text.isEmpty ? null : passwordController.text,
                mobileNumber: mobileNumberController.text,
                role: roleController.text,
                aadharNumber: '', // Since Aadhar is commented out, pass empty string
                address: addressController.text,
              );
              Get.back(); // Close the dialog after updating
            },
            child: const Text('Save', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}