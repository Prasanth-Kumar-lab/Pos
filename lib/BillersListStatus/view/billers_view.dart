/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../Reports/model/reports_model.dart';

class BillerController extends GetxController {
  final ReportModel _reportModel = ReportModel();
  var billers = <Biller>[].obs;
  var isLoading = true.obs; // Start with loading true
  var updatingStatus = <String>{}.obs;

  // Initialize with empty businessId
  String businessId = '';

  @override
  void onInit() {
    super.onInit();
    // Fetch billers immediately when controller is created
    fetchBillers();
  }

  // Method to set businessId and fetch billers
  void initialize(String businessId) {
    this.businessId = businessId;
    fetchBillers();
  }

  Future<void> fetchBillers() async {
    // Don't fetch if businessId is empty
    if (businessId.isEmpty) {
      isLoading(false);
      return;
    }

    try {
      isLoading(true);
      final data = await _reportModel.fetchBillerIds(businessId);
      billers.assignAll(data.map((billerData) => Biller.fromJson(billerData)).toList());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load billers: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE57373),
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateBillerStatus(String billerId, int status) async {
    try {
      updatingStatus.add(billerId);

      final url = Uri.parse('https://erpapp.in/mart_print/mart_print_apis/user_status_api.php');
      final response = await http.post(
        url,
        body: {
          'biller_id': billerId,
          'business_id': businessId,
          'status': status.toString(),
        },
      );
      debugPrint('Status Update API Response: ${response.statusCode} - ${response.body}');
      debugPrint('Request Params - business_id: $businessId, biller_id: $billerId, status: $status');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']?.toString().toLowerCase() == 'success') {
          // Update the specific biller's status in the list
          final index = billers.indexWhere((biller) => biller.billerId == billerId);
          if (index != -1) {
            billers[index] = billers[index].copyWith(status: status == 1 ? '1' : '2');
          }

          final updatedBillerId = data['biller_id'] ?? billerId;
          final message = data['Message'] ?? 'Status updated successfully';

          Get.snackbar(
            'Success',
            '$message (Biller ID: $updatedBillerId)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        } else {
          // Revert the UI change if API failed
          final index = billers.indexWhere((biller) => biller.billerId == billerId);
          if (index != -1) {
            billers.refresh(); // Force UI update
          }
          throw Exception('API error: ${data['Message'] ?? 'Unknown error'}');
        }
      } else {
        // Revert the UI change if API failed
        final index = billers.indexWhere((biller) => biller.billerId == billerId);
        if (index != -1) {
          billers.refresh();
        }
        throw Exception('Failed to update biller status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Status Update API Error: $e');

      // Ensure UI reflects actual state after error
      final index = billers.indexWhere((biller) => biller.billerId == billerId);
      if (index != -1) {
        billers.refresh();
      }

      Get.snackbar(
        'Error',
        'Failed to update biller status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE57373),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    } finally {
      updatingStatus.remove(billerId);
    }
  }

  bool isUpdating(String billerId) => updatingStatus.contains(billerId);
}

class Biller {
  final String billerId;
  final String billerName;
  final String status;

  Biller({
    required this.billerId,
    required this.billerName,
    required this.status,
  });

  factory Biller.fromJson(Map<String, dynamic> json) {
    return Biller(
      billerId: json['biller_id']?.toString() ?? '',
      billerName: json['biller_name']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? '2',
    );
  }

  Biller copyWith({
    String? billerId,
    String? billerName,
    String? status,
  }) {
    return Biller(
      billerId: billerId ?? this.billerId,
      billerName: billerName ?? this.billerName,
      status: status ?? this.status,
    );
  }

  bool get isActive => status == '1';
}

class BillerList extends StatefulWidget {
  final String businessId;

  const BillerList({Key? key, required this.businessId}) : super(key: key);

  @override
  State<BillerList> createState() => _BillerListState();
}

class _BillerListState extends State<BillerList> {
  late BillerController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with the specific businessId
    controller = Get.put(BillerController(), tag: widget.businessId);
    // Initialize the controller with businessId and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billers List',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.green.shade300,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchBillers,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (controller.billers.isEmpty) {
          return _StatusMessage(
            icon: Icons.inbox,
            message: 'No billers found for this business.',
            onRetry: controller.fetchBillers,
            retryText: 'Refresh',
          );
        } else {
          return RefreshIndicator(
            onRefresh: controller.fetchBillers,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: controller.billers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final biller = controller.billers[index];
                final isUpdating = controller.isUpdating(biller.billerId);

                return _BillerListItem(
                  biller: biller,
                  isUpdating: isUpdating,
                  onStatusChanged: (bool value) {
                    controller.updateBillerStatus(
                        biller.billerId,
                        value ? 1 : 2
                    );
                  },
                );
              },
            ),
          );
        }
      }),
    );
  }
}

class _BillerListItem extends StatelessWidget {
  final Biller biller;
  final bool isUpdating;
  final Function(bool) onStatusChanged;

  const _BillerListItem({
    Key? key,
    required this.biller,
    required this.isUpdating,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${biller.billerId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              biller.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: biller.isActive ? Colors.green : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isUpdating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Switch(
          value: biller.isActive,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey,
          onChanged: onStatusChanged,
        ),
        onTap: () {
          if (!isUpdating) {
            Get.snackbar(
              'Biller Info',
              '${biller.billerName}\nID: ${biller.billerId}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade700,
              colorText: Colors.white,
              margin: const EdgeInsets.all(12),
              borderRadius: 8,
              duration: const Duration(seconds: 2),
            );
          }
        },
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

// Updated ReportModel to handle API responses better
class ReportModel {
  Future<List<Map<String, dynamic>>> fetchBillerIds(String businessId) async {
    final url = Uri.parse(
      'https://erpapp.in/mart_print/mart_print_apis/list_users_api.php?business_id=$businessId',
    );

    try {
      final response = await http.get(url);
      debugPrint('Fetch Billers API Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            return data['data'].cast<Map<String, dynamic>>();
          } else if (data.containsKey('billers') && data['billers'] is List) {
            return data['billers'].cast<Map<String, dynamic>>();
          } else if (data.containsKey('users') && data['users'] is List) {
            return data['users'].cast<Map<String, dynamic>>();
          }
        }

        debugPrint('Unexpected API response format: $data');
        return [];
      } else {
        throw Exception('Failed to fetch biller IDs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch Billers API Error: $e');
      rethrow;
    }
  }
}
*/
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../Reports/model/reports_model.dart';

class BillerController extends GetxController {
  final ReportModel _reportModel = ReportModel();
  var billers = <Biller>[].obs;
  var isLoading = true.obs; // Start with loading true
  var updatingStatus = <String>{}.obs;

  // Initialize with empty businessId
  String businessId = '';

  @override
  void onInit() {
    super.onInit();
    // Fetch billers immediately when controller is created
    fetchBillers();
  }

  // Method to set businessId and fetch billers
  void initialize(String businessId) {
    this.businessId = businessId;
    fetchBillers();
  }
  Future<String> fetchBillerStatus(String billerId) async {
    try {
      final url = Uri.parse(
        'https://erpapp.in/mart_print/mart_print_apis/get_user_status.php?user_id=$billerId&business_id=$businessId',
      );
      final response = await http.get(url);
      debugPrint('Fetch Biller Status API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Correct key from API response
        return data['user_status']?.toString() ?? '2';
      } else {
        return '2'; // Default to inactive if API fails
      }
    } catch (e) {
      debugPrint('Error fetching biller status: $e');
      return '2'; // Default to inactive on error
    }
  }


  Future<void> fetchBillers() async {
    if (businessId.isEmpty) {
      isLoading(false);
      return;
    }

    try {
      isLoading(true);
      final data = await _reportModel.fetchBillerIds(businessId);
      final fetchedBillers = data.map((billerData) => Biller.fromJson(billerData)).toList();

      // Fetch status concurrently for all billers
      final updatedBillers = await Future.wait(fetchedBillers.map((biller) async {
        final status = await fetchBillerStatus(biller.billerId);
        return biller.copyWith(status: status);
      }));

      billers.assignAll(updatedBillers);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load billers: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE57373),
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }



  Future<void> updateBillerStatus(String billerId, int status) async {
    try {
      updatingStatus.add(billerId);

      final url = Uri.parse('https://erpapp.in/mart_print/mart_print_apis/user_status_api.php');
      final response = await http.post(
        url,
        body: {
          'biller_id': billerId,
          'business_id': businessId,
          'status': status.toString(),
        },
      );
      debugPrint('Status Update API Response: ${response.statusCode} - ${response.body}');
      debugPrint('Request Params - business_id: $businessId, biller_id: $billerId, status: $status');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']?.toString().toLowerCase() == 'success') {
          // Update the specific biller's status in the list
          final index = billers.indexWhere((biller) => biller.billerId == billerId);
          if (index != -1) {
            billers[index] = billers[index].copyWith(status: status == 1 ? '1' : '2');
          }

          final updatedBillerId = data['biller_id'] ?? billerId;
          final message = data['Message'] ?? 'Status updated successfully';

          Get.snackbar(
            'Success',
            '$message (Biller ID: $updatedBillerId)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        } else {
          // Revert the UI change if API failed
          final index = billers.indexWhere((biller) => biller.billerId == billerId);
          if (index != -1) {
            billers.refresh(); // Force UI update
          }
          throw Exception('API error: ${data['Message'] ?? 'Unknown error'}');
        }
      } else {
        // Revert the UI change if API failed
        final index = billers.indexWhere((biller) => biller.billerId == billerId);
        if (index != -1) {
          billers.refresh();
        }
        throw Exception('Failed to update biller status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Status Update API Error: $e');

      // Ensure UI reflects actual state after error
      final index = billers.indexWhere((biller) => biller.billerId == billerId);
      if (index != -1) {
        billers.refresh();
      }

      Get.snackbar(
        'Error',
        'Failed to update biller status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE57373),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    } finally {
      updatingStatus.remove(billerId);
    }
  }

  bool isUpdating(String billerId) => updatingStatus.contains(billerId);
}

class Biller {
  final String billerId;
  final String billerName;
  final String status;

  Biller({
    required this.billerId,
    required this.billerName,
    required this.status,
  });

  factory Biller.fromJson(Map<String, dynamic> json) {
    return Biller(
      billerId: json['biller_id']?.toString() ?? '',
      billerName: json['biller_name']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? '2',
    );
  }

  Biller copyWith({
    String? billerId,
    String? billerName,
    String? status,
  }) {
    return Biller(
      billerId: billerId ?? this.billerId,
      billerName: billerName ?? this.billerName,
      status: status ?? this.status,
    );
  }

  bool get isActive => status == '1';
}

class BillerList extends StatefulWidget {
  final String businessId;

  const BillerList({Key? key, required this.businessId}) : super(key: key);

  @override
  State<BillerList> createState() => _BillerListState();
}

class _BillerListState extends State<BillerList> {
  late BillerController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with the specific businessId
    controller = Get.put(BillerController(), tag: widget.businessId);
    // Initialize the controller with businessId and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Billers List',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.green.shade300,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchBillers,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (controller.billers.isEmpty) {
          return _StatusMessage(
            icon: Icons.inbox,
            message: 'No billers found for this business.',
            onRetry: controller.fetchBillers,
            retryText: 'Refresh',
          );
        } else {
          return RefreshIndicator(
            onRefresh: controller.fetchBillers,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: controller.billers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final biller = controller.billers[index];
                final isUpdating = controller.isUpdating(biller.billerId);

                return _BillerListItem(
                  biller: biller,
                  isUpdating: isUpdating,
                  onStatusChanged: (bool value) {
                    controller.updateBillerStatus(
                        biller.billerId,
                        value ? 1 : 2   // ON = inactive(2), OFF = active(1)
                    );
                  },
                );
              },
            ),
          );
        }
      }),
    );
  }
}

class _BillerListItem extends StatelessWidget {
  final Biller biller;
  final bool isUpdating;
  final Function(bool) onStatusChanged;

  const _BillerListItem({
    Key? key,
    required this.biller,
    required this.isUpdating,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${biller.billerId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              biller.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: biller.isActive ? Colors.green : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isUpdating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : /*Switch(
          value: biller.isActive,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey,
          onChanged: onStatusChanged,
        ),*/
        Switch(
          value: biller.isActive,     // Reverse UI display !
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey,
          onChanged: onStatusChanged,  // Call parent callback
        ),

        onTap: () {
          if (!isUpdating) {
            Get.snackbar(
              'Biller Info',
              '${biller.billerName}\nID: ${biller.billerId}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade700,
              colorText: Colors.white,
              margin: const EdgeInsets.all(12),
              borderRadius: 8,
              duration: const Duration(seconds: 2),
            );
          }
        },
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

// Updated ReportModel to handle API responses better
class ReportModel {
  Future<List<Map<String, dynamic>>> fetchBillerIds(String businessId) async {
    final url = Uri.parse(
      'https://erpapp.in/mart_print/mart_print_apis/list_users_api.php?business_id=$businessId',
    );

    try {
      final response = await http.get(url);
      debugPrint('Fetch Billers API Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            return data['data'].cast<Map<String, dynamic>>();
          } else if (data.containsKey('billers') && data['billers'] is List) {
            return data['billers'].cast<Map<String, dynamic>>();
          } else if (data.containsKey('users') && data['users'] is List) {
            return data['users'].cast<Map<String, dynamic>>();
          }
        }

        debugPrint('Unexpected API response format: $data');
        return [];
      } else {
        throw Exception('Failed to fetch biller IDs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch Billers API Error: $e');
      rethrow;
    }
  }
}