/*
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:task/api_endpoints.dart';
import '../../home_screen/model/product_model.dart';
import '../model/print_model.dart';
import '../../home_screen/controller/controller.dart'; // Import ProductController

class PrintController extends GetxController {
  final Rx<Printer?> selectedPrinter = Rx<Printer?>(null);
  RxList<Product> selectedProducts = <Product>[].obs;
  final RxDouble totalAmount = 0.0.obs;
  final String businessId;

  final RxString connectionStatus = ''.obs;
  ReceiptController? receiptController;
  final Rx<SystemSettings?> systemSettings = Rx<SystemSettings?>(null);
  final RxBool isLoadingSettings = false.obs;
  final RxString errorMessage = ''.obs;

  PrintController({
    required List<Product> initialProducts,
    required double initialTotal,
    required this.businessId,
  }) {
    selectedProducts.value = initialProducts;
    totalAmount.value = initialTotal;
  }

  void updateCartData(List<Product> products, double total) {
    selectedProducts.value = products.map((p) => Product(
      productId: p.productId,
      itemName: p.itemName,
      sellingPrice: p.sellingPrice,
      itemImage: p.itemImage,
      quantity: p.quantity, // Ensure quantity is copied
      cartItemId: p.cartItemId,
    )).toList();
    totalAmount.value = total;
    log('Updated cart in PrintController: ${products.length} items, total: $total');
  }

  Future<void> syncCartData(ProductController productController) async {
    await productController.fetchCartItems(); // Fetch latest cart items from API
    selectedProducts.value = productController.cartItems.map((p) => Product(
      productId: p.productId,
      itemName: p.itemName,
      sellingPrice: p.sellingPrice,
      itemImage: p.itemImage,
      quantity: p.quantity, // Use API-fetched quantity
      cartItemId: p.cartItemId,
    )).toList();
    totalAmount.value = selectedProducts.fold(
      0.0,
          (sum, p) => sum + ((p.sellingPrice ?? 0.0) * p.quantity),
    );
    log('Synced cart data with API: ${selectedProducts.length} items, total: ${totalAmount.value}');
  }

  void initializePrinterConnection(BuildContext context) {
    _loadSelectedPrinter(context);
    fetchSystemSettings();
  }

  Future<void> _loadSelectedPrinter(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('selected_printer_address');
    final name = prefs.getString('selected_printer_name');

    if (address != null) {
      selectedPrinter.value = Printer(address: address, name: name);
      log("Loaded saved printer: ${name ?? address}");

      connectionStatus.value = 'Connecting to saved printer...';
      _showConnectionStatusDialog(context);

      final isConnected = await FlutterBluetoothPrinter.connect(address);
      connectionStatus.value = isConnected ? 'Connected' : 'Failed to auto-connect';
      log(isConnected ? "Auto-connected to saved printer." : "Failed to auto-connect to saved printer.");
    }
  }

  Future<void> _saveSelectedPrinter(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_printer_address', printer.address);
    await prefs.setString('selected_printer_name', printer.name ?? '');
    log("Saved printer: ${printer.name ?? printer.address}");
  }

  Future<void> selectBluetoothDevice(BuildContext context) async {
    final selected = await FlutterBluetoothPrinter.selectDevice(context);
    if (selected != null) {
      selectedPrinter.value = Printer(address: selected.address, name: selected.name);
      await _saveSelectedPrinter(selectedPrinter.value!);

      connectionStatus.value = 'Connecting...';
      _showConnectionStatusDialog(context);

      final isConnected = await FlutterBluetoothPrinter.connect(selected.address);
      connectionStatus.value = isConnected ? 'Connected' : 'Failed to connect';
    } else {
      log("Device selection canceled.");
    }
  }

  void _showConnectionStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Obx(() {
          return AlertDialog(
            title: const Text('Printer Connection'),
            content: Text(
              connectionStatus.value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (connectionStatus.value != 'Connecting...')
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          );
        });
      },
    );
  }

  Future<void> fetchSystemSettings() async {
    if (businessId.isEmpty) {
      errorMessage.value = 'Business ID is missing';
      return;
    }

    isLoadingSettings.value = true;
    errorMessage.value = '';

    final url = Uri.parse('${ApiConstants.listSystemSettingsEndPoint}?business_id=$businessId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final settings = SystemSettings.fromJsonResponse(response.body);
        if (settings != null) {
          systemSettings.value = settings;
          log('System settings fetched successfully.');
        } else {
          errorMessage.value = 'Invalid response format';
        }
      } else {
        errorMessage.value = 'Failed to fetch settings: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching settings: $e';
      log('Error fetching system settings: $e');
    } finally {
      isLoadingSettings.value = false;
    }
  }

  Future<bool> completeOrder(String cartId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.orderCompleteEndPoint),
        body: {
          'business_id': businessId,
          'cart_id': cartId,
          'status': 'Completed',
        },
      );

      log('Order Complete Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'Success') {
          log('Order marked as Completed successfully.');
          return true;
        } else {
          errorMessage.value = 'Failed to complete order: ${responseData['message'] ?? 'Unknown error'}';
          return false;
        }
      } else {
        errorMessage.value = 'Failed to complete order: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error completing order: $e';
      log('Error completing order: $e');
      return false;
    }
  }

  Future<void> printReceipt(BuildContext context, ProductController productController) async {
    if (selectedPrinter.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a printer first')),
      );
      return;
    }

    try {
      await receiptController?.print(
        address: selectedPrinter.value!.address,
        keepConnected: true,
        addFeeds: 4,
      );
      log('Printing successful');

      // Call order_complete.php after successful print
      final cartId = productController.cartId.value;
      final orderCompleted = await completeOrder(cartId);

      if (orderCompleted) {
        // Clear cart only if order completion is successful
        await productController.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order completed and cart cleared')),
        );
        Navigator.of(context).pop(); // Close dialog or screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print successful but failed to complete order: ${errorMessage.value}')),
        );
      }
    } catch (e) {
      log('Printing failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printing failed: $e')),
      );
    }
  }

  void setReceiptController(ReceiptController controller) {
    receiptController = controller;
  }
}*/
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:task/api_endpoints.dart';
import '../../home_screen/model/product_model.dart';
import '../model/print_model.dart';
import '../../home_screen/controller/controller.dart';

class PrintController extends GetxController {
  final Rx<Printer?> selectedPrinter = Rx<Printer?>(null);
  RxList<Product> selectedProducts = <Product>[].obs;
  final RxDouble totalAmount = 0.0.obs;
  final String businessId;

  final RxString connectionStatus = ''.obs;
  ReceiptController? receiptController;
  final Rx<SystemSettings?> systemSettings = Rx<SystemSettings?>(null);
  final RxBool isLoadingSettings = false.obs;
  final RxString errorMessage = ''.obs;

  PrintController({
    required List<Product> initialProducts,
    required double initialTotal,
    required this.businessId,
  }) {
    selectedProducts.value = initialProducts;
    totalAmount.value = initialTotal;
  }

  void updateCartData(List<Product> products, double total) {
    selectedProducts.value = products.map((p) => Product(
      productId: p.productId,
      itemName: p.itemName,
      sellingPrice: p.sellingPrice,
      itemImage: p.itemImage,
      quantity: p.quantity,
      cartItemId: p.cartItemId,
    )).toList();
    totalAmount.value = total;
    log('Updated cart in PrintController: ${products.length} items, total: $total');
  }

  Future<void> syncCartData(ProductController productController) async {
    await productController.fetchCartItems();
    selectedProducts.value = productController.cartItems.map((p) => Product(
      productId: p.productId,
      itemName: p.itemName,
      sellingPrice: p.sellingPrice,
      itemImage: p.itemImage,
      quantity: p.quantity,
      cartItemId: p.cartItemId,
    )).toList();
    totalAmount.value = selectedProducts.fold(
      0.0,
          (sum, p) => sum + ((p.sellingPrice ?? 0.0) * p.quantity),
    );
    log('Synced cart data with API: ${selectedProducts.length} items, total: ${totalAmount.value}');
  }

  void initializePrinterConnection(BuildContext context) {
    _loadSelectedPrinter(context);
    fetchSystemSettings();
  }

  Future<void> _loadSelectedPrinter(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('selected_printer_address');
    final name = prefs.getString('selected_printer_name');

    if (address != null) {
      selectedPrinter.value = Printer(address: address, name: name);
      log("Loaded saved printer: ${name ?? address}");

      connectionStatus.value = 'Connecting to saved printer...';
      _showConnectionStatusDialog(context);

      final isConnected = await FlutterBluetoothPrinter.connect(address);
      connectionStatus.value = isConnected ? 'Connected' : 'Failed to auto-connect';
      log(isConnected ? "Auto-connected to saved printer." : "Failed to auto-connect to saved printer.");
    }
  }

  Future<void> _saveSelectedPrinter(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_printer_address', printer.address);
    await prefs.setString('selected_printer_name', printer.name ?? '');
    log("Saved printer: ${printer.name ?? printer.address}");
  }

  Future<void> selectBluetoothDevice(BuildContext context) async {
    final selected = await FlutterBluetoothPrinter.selectDevice(context);
    if (selected != null) {
      selectedPrinter.value = Printer(address: selected.address, name: selected.name);
      await _saveSelectedPrinter(selectedPrinter.value!);

      connectionStatus.value = 'Connecting...';
      _showConnectionStatusDialog(context);

      final isConnected = await FlutterBluetoothPrinter.connect(selected.address);
      connectionStatus.value = isConnected ? 'Connected' : 'Failed to connect';
    } else {
      log("Device selection canceled.");
    }
  }

  void _showConnectionStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Obx(() {
          return AlertDialog(
            title: const Text('Printer Connection'),
            content: Text(
              connectionStatus.value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (connectionStatus.value != 'Connecting...')
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          );
        });
      },
    );
  }

  Future<void> fetchSystemSettings() async {
    if (businessId.isEmpty) {
      errorMessage.value = 'Business ID is missing';
      return;
    }
    isLoadingSettings.value = true;
    errorMessage.value = '';

    final url = Uri.parse('${ApiConstants.listSystemSettingsEndPoint}?business_id=$businessId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final settings = SystemSettings.fromJsonResponse(response.body);
        if (settings != null) {
          systemSettings.value = settings;
          log('System settings fetched successfully.');
        } else {
          errorMessage.value = 'Invalid response format';
        }
      } else {
        errorMessage.value = 'Failed to fetch settings: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching settings: $e';
      log('Error fetching system settings: $e');
    } finally {
      isLoadingSettings.value = false;
    }
  }

  Future<bool> completeOrder(String cartId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.orderCompleteEndPoint),
        body: {
          'business_id': businessId,
          'cart_id': cartId,
          'status': 'Completed',
        },
      );

      log('Order Complete Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'Success') {
          log('Order marked as Completed successfully.');
          return true;
        } else {
          errorMessage.value = 'Failed to complete order: ${responseData['message'] ?? 'Unknown error'}';
          return false;
        }
      } else {
        errorMessage.value = 'Failed to complete order: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error completing order: $e';
      log('Error completing order: $e');
      return false;
    }
  }
  /*Future<void> printReceipt(BuildContext context, ProductController productController) async {
    if (selectedPrinter.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a printer first')),         //Prints only when bluetooth connected
      );
      return;
    }

    try {
      await receiptController?.print(
        address: selectedPrinter.value!.address,
        keepConnected: true,
        addFeeds: 4,
      );
      log('Printing successful');

      // Call order_complete.php after successful print
      final cartId = productController.cartId.value;
      final orderCompleted = await completeOrder(cartId);

      if (orderCompleted) {
        // Reset UI cart instead of clearing API cart
        productController.resetUICart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order completed and UI cart reset')),
        );
        Navigator.of(context).pop(); // Close dialog or screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print successful but failed to complete order: ${errorMessage.value}')),
        );
      }
    } catch (e) {
      log('Printing failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printing failed: $e')),
      );
    }
  }*/
  /*Future<void> printReceipt(BuildContext context, ProductController productController) async {
    bool printSuccess = false;

    try {
      if (selectedPrinter.value == null) {
        log('No printer selected. Skipping print.');
      } else {
        await receiptController?.print(
          address: selectedPrinter.value!.address,
          keepConnected: true,
          addFeeds: 4,
        );
        printSuccess = true;
        log('Printing successful');
      }
    } catch (e) {
      log('Printing failed: $e');
    }

    // ✔ ALWAYS CALL completeOrder — no matter what
    final cartId = productController.cartId.value;
    final orderCompleted = await completeOrder(cartId);

    if (orderCompleted) {
      productController.resetUICart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            printSuccess
                ? 'Printed & Order Completed'
                : 'Printer not connected, but Order Completed',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order not completed: ${errorMessage.value}')),
      );
    }
  }*/                                                                                 //YESTERDAY
  Future<void> printReceipt(BuildContext context, ProductController productController) async {
    bool printSuccess = false;

    try {
      if (selectedPrinter.value != null) {
        await receiptController?.print(
          address: selectedPrinter.value!.address,
          keepConnected: true,
          addFeeds: 4,
        );
        printSuccess = true;
        log('Printing successful');
      } else {
        log('No printer selected → Skipping print (still completing order)');
      }
    } catch (e) {
      log('Print failed: $e');
    }

    // Always reset UI cart after user tried to print (intent was to finish sale)
    productController.resetUICart();

    Get.snackbar(
      'Success',
      printSuccess
          ? 'Printed & Order Completed'
          : 'Order Completed (No Printer Connected)',
      backgroundColor: printSuccess ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );

    Navigator.of(context).pop(); // Close PrintScreen
  }


  void setReceiptController(ReceiptController controller) {
    receiptController = controller;
  }
}