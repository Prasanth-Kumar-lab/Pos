/*
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:task/api_endpoints.dart';
import 'package:uuid/uuid.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  RxList<Product> products = <Product>[].obs;
  RxList<Product> filteredProducts = <Product>[].obs;
  RxList<Product> cartItems = <Product>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString searchQuery = ''.obs;
  RxString cartId = '1'.obs;
  RxInt cartItemCount = 0.obs;
  RxString customerName = ''.obs;
  RxString customerMobileNumber = ''.obs;
  RxString finalInvoiceId = '0'.obs;

  final String businessId;
  final String billerId;
  final StreamController<int> _cartCountStreamController = StreamController<int>.broadcast();

  Stream<int> get cartCountStream => _cartCountStreamController.stream;

  ProductController({required this.businessId, required this.billerId});

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    ever(cartItemCount, (int count) {
      _cartCountStreamController.add(count);
    });
  }

  @override
  void onClose() {
    _cartCountStreamController.close();
    super.onClose();
  }
  Map<String, List<Product>> get productsGroupedByCategory {
    final Map<String, List<Product>> grouped = {};

    for (var product in filteredProducts) {
      final category = product.productCategory ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(product);
    }

    return grouped;
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.productsEndPoint),
        body: {'business_id': businessId},
      );

      print('Fetch Products Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          products.assignAll(data.map((item) => Product.fromJson(item)).toList());
          filteredProducts.assignAll(products);
          isLoading.value = false;
          await fetchCartItems();
        } else {
          errorMessage.value = 'Unexpected response format';
          isLoading.value = false;
        }
      } else {
        errorMessage.value = 'Failed to load products: ${response.statusCode}';
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching products: $e';
      isLoading.value = false;
    }
  }

  Future<void> fetchCartCount() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cartCountEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
        },
      );

      print('Fetch Cart Count Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final serverCount = int.tryParse(response.body.trim()) ?? 0;
        if ((serverCount - cartItemCount.value).abs() > 1) {
          cartItemCount.value = serverCount;
        }
        print('Updated cartItemCount from server: ${cartItemCount.value}');
      } else {
        errorMessage.value = 'Failed to fetch cart count: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching cart count: $e';
    }
  }

  Future<void> fetchCartItems() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.getCartItemsEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
        },
      );

      print('Fetch Cart Items Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded JSON: $data');

        if (data is Map<String, dynamic> && data['status'] == 'success') {
          cartId.value = data['cart_id']?.toString() ?? '1';
          customerName.value = data['customer_name']?.toString() ?? 'Customer';
          customerMobileNumber.value = data['customer_mobile_number']?.toString() ?? '0';

          String serverInvoiceId = data['final_invoice_id']?.toString() ?? '';
          if (serverInvoiceId.isEmpty || serverInvoiceId == '0') {
            serverInvoiceId = '';
          }
          finalInvoiceId.value = serverInvoiceId;

          final items = data['items'] as List? ?? [];
          cartItems.assignAll(items.map((item) => Product.fromCartJson(item)).toList());

          for (var product in products) {
            product.quantity = 0;
            product.cartItemId = null;
          }
          for (var cartItem in cartItems) {
            final matchingProduct = products.firstWhere(
                  (p) => p.productId == cartItem.productId || p.itemName == cartItem.itemName,
              orElse: () => Product(),
            );
            if (matchingProduct.productId != null || matchingProduct.itemName != null) {
              matchingProduct.quantity = cartItem.quantity;
              matchingProduct.cartItemId = cartItem.cartItemId;
              if (cartItem.sellingPrice == null || cartItem.sellingPrice == 0.0) {
                cartItem.sellingPrice = matchingProduct.sellingPrice;
              }
              if (cartItem.itemImage == null) {
                cartItem.itemImage = matchingProduct.itemImage;
              }
            }
          }
          cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
          print('Updated cartItemCount after fetchCartItems: ${cartItemCount.value}');
          products.refresh();
          filteredProducts.refresh();
        } else {
          errorMessage.value = 'Failed to fetch cart items: ${data['message'] ?? 'Invalid response format'}';
        }
      } else {
        errorMessage.value = 'Failed to fetch cart items: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching cart items: $e';
      print('Exception during fetchCartItems: $e');
    }
  }

  Future<void> incrementQuantity(int index) async {
    final product = products[index];
    final previousQuantity = product.quantity;
    product.quantity++;

    final cartItemIndex = cartItems.indexWhere((item) => item.productId == product.productId || item.itemName == product.itemName);
    if (cartItemIndex != -1) {
      cartItems[cartItemIndex].quantity = product.quantity;
    } else {
      cartItems.add(Product(
        productId: product.productId,
        itemName: product.itemName,
        sellingPrice: product.sellingPrice,
        itemImage: product.itemImage,
        quantity: product.quantity,
        cartItemId: product.cartItemId,
      ));
    }
    cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
    products.refresh();
    filteredProducts.refresh();

    _syncWithServer('Increment', product, previousQuantity);
  }

  Future<void> decrementQuantity(int index) async {
    final product = products[index];
    if (product.quantity > 0) {
      final previousQuantity = product.quantity;
      product.quantity--;

      final cartItemIndex = cartItems.indexWhere((item) => item.productId == product.productId || item.itemName == product.itemName);
      if (cartItemIndex != -1) {
        cartItems[cartItemIndex].quantity = product.quantity;
        if (product.quantity == 0) {
          cartItems.removeAt(cartItemIndex);
        }
      }
      cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
      products.refresh();
      filteredProducts.refresh();

      _syncWithServer('Decrement', product, previousQuantity);
    }
  }

  Future<void> _syncWithServer(String transactionType, Product product, int previousQuantity) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'status': 'Pending',
          'transaction_type': transactionType,
          'product_id': product.productId ?? product.itemName,
          'gst_type': 'NO_GST',
        },
      );

      print('$transactionType Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'Success' ||
              (responseData['message'] != null &&
                  (responseData['message'].toString().contains('Item Added') ||
                      responseData['message'].toString().contains('Item Updated')))) {
            if (responseData['cart_id'] != null) {
              cartId.value = responseData['cart_id'].toString();
            }
            if (responseData['cart_item_id'] != null) {
              product.cartItemId = responseData['cart_item_id'].toString();
              final cartItemIndex = cartItems.indexWhere((item) => item.productId == product.productId || item.itemName == product.itemName);
              if (cartItemIndex != -1) {
                cartItems[cartItemIndex].cartItemId = product.cartItemId;
              }
            }
            await fetchCartItems();
          } else {
            _revertQuantity(product, previousQuantity, transactionType);
          }
        } catch (e) {
          if (response.body.contains('Item Added') || response.body.contains('Item Updated')) {
            await fetchCartItems();
          } else {
            _revertQuantity(product, previousQuantity, transactionType);
          }
        }
      } else {
        _revertQuantity(product, previousQuantity, transactionType);
      }
    } catch (e) {
      _revertQuantity(product, previousQuantity, transactionType);
    }
  }

  void _revertQuantity(Product product, int previousQuantity, String transactionType) {
    errorMessage.value = 'Failed to $transactionType quantity: ${product.itemName}';
    product.quantity = previousQuantity;
    final cartItemIndex = cartItems.indexWhere((item) => item.productId == product.productId || item.itemName == product.itemName);
    if (cartItemIndex != -1) {
      cartItems[cartItemIndex].quantity = previousQuantity;
      if (previousQuantity == 0) {
        cartItems.removeAt(cartItemIndex);
      }
    } else if (previousQuantity > 0) {
      cartItems.add(Product(
        productId: product.productId,
        itemName: product.itemName,
        sellingPrice: product.sellingPrice,
        itemImage: product.itemImage,
        quantity: previousQuantity,
        cartItemId: product.cartItemId,
      ));
    }
    cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
    products.refresh();
    filteredProducts.refresh();
    Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> removeItemFromCart(int index) async {
    final product = products[index];
    final previousQuantity = product.quantity;
    product.quantity = 0;
    products.refresh();
    filteredProducts.refresh();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'status': 'Pending',
          'transaction_type': 'Decrement',
          'product_id': product.productId ?? product.itemName,
        },
      );

      print('Remove Item Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'Success' ||
              (responseData['message'] != null &&
                  (responseData['message'].toString().contains('Item Added') ||
                      responseData['message'].toString().contains('Item Updated')))) {
            if (responseData['cart_id'] != null) {
              cartId.value = responseData['cart_id'].toString();
              print('Updated cart_id: ${cartId.value}');
            }
            Get.snackbar('Success', '${product.itemName} removed from cart',
                snackPosition: SnackPosition.BOTTOM);
          } else {
            errorMessage.value = 'Failed to remove item: ${responseData['message'] ?? 'Unknown error'}';
            product.quantity = previousQuantity;
            products.refresh();
            filteredProducts.refresh();
            Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
          }
        } catch (e) {
          if (response.body.contains('Item Added') || response.body.contains('Item Updated')) {
            Get.snackbar('Success', '${product.itemName} removed from cart',
                snackPosition: SnackPosition.BOTTOM);
          } else {
            errorMessage.value = 'Failed to remove item: ${response.body}';
            product.quantity = previousQuantity;
            products.refresh();
            filteredProducts.refresh();
            Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
          }
        }
      } else {
        errorMessage.value = 'Failed to remove item: ${response.statusCode} - ${response.body}';
        product.quantity = previousQuantity;
        products.refresh();
        filteredProducts.refresh();
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      errorMessage.value = 'Error removing item: $e';
      product.quantity = previousQuantity;
      products.refresh();
      filteredProducts.refresh();
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      fetchCartCount();
    }
  }

  void resetUICart() {
    for (var product in products) {
      product.quantity = 0;
      product.cartItemId = null;
    }
    cartItems.clear();
    cartItemCount.value = 0;
    cartId.value = '1';
    customerName.value = 'Customer';
    customerMobileNumber.value = '0';
    finalInvoiceId.value = '';
    products.refresh();
    filteredProducts.refresh();
    //Get.snackbar('Success', 'Cart cleared in UI', snackPosition: SnackPosition.BOTTOM);
  }

  List<Product> get selectedProducts => products.where((p) => p.quantity > 0).toList();

  bool get hasItemsInCart => selectedProducts.isNotEmpty;

  double get totalAmount => selectedProducts.fold(
      0.0, (sum, p) => sum + (p.sellingPrice! * p.quantity));

  void filterProducts(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      final lowercaseQuery = query.toLowerCase().replaceAll(' ', '');
      filteredProducts.assignAll(
        products.where((product) {
          final lowercaseProductName =
              product.itemName?.toLowerCase().replaceAll(' ', '') ?? '';
          return lowercaseProductName.contains(lowercaseQuery);
        }).toList(),
      );
    }
  }
}*/
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:task/api_endpoints.dart';
import 'package:vibration/vibration.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  RxList<Product> products = <Product>[].obs;
  RxList<Product> filteredProducts = <Product>[].obs;
  RxList<Product> cartItems = <Product>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString searchQuery = ''.obs;
  RxString cartId = '1'.obs;
  RxInt cartItemCount = 0.obs;
  RxString customerName = ''.obs;
  RxString customerMobileNumber = ''.obs;
  RxString finalInvoiceId = '0'.obs;
  var totalAmount = 1.0.obs;  // Sub-Total
  var gstAmount = 1.0.obs;    // GST
  var roundOff = 1.0.obs;     // Round-Off
  var grandTotal = 1.0.obs;   // Grand Total = Sub-Total + GST + Round-Off
  double get computedGrandTotal => totalAmount.value + gstAmount.value + roundOff.value;



  final String businessId;
  final String billerId;
  final StreamController<int> _cartCountStreamController = StreamController<int>.broadcast();

  Stream<int> get cartCountStream => _cartCountStreamController.stream;

  ProductController({required this.businessId, required this.billerId});

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    ever(cartItemCount, (int count) {
      _cartCountStreamController.add(count);
    });
  }

  @override
  void onClose() {
    _cartCountStreamController.close();
    super.onClose();
  }

  Map<String, List<Product>> get productsGroupedByCategory {
    final Map<String, List<Product>> grouped = {};
    for (var product in filteredProducts) {
      final category = product.productCategory ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(product);
    }
    return grouped;
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.productsEndPoint),
        body: {'business_id': businessId},
      );

      print('Fetch Products Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          products.assignAll(data.map((item) => Product.fromJson(item)).toList());
          filteredProducts.assignAll(products);
          isLoading.value = false;
          await fetchCartItems();
        } else {
          errorMessage.value = 'Unexpected response format';
          isLoading.value = false;
        }
      } else {
        errorMessage.value = 'Failed to load products: ${response.statusCode}';
        isLoading.value = false;
      }
    } catch (e) {
      //errorMessage.value = 'Error fetching products: $e';
      isLoading.value = false;
    }
  }

  Future<void> fetchCartCount() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cartCountEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
        },
      );

      print('Fetch Cart Count Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final serverCount = int.tryParse(response.body.trim()) ?? 0;
        if ((serverCount - cartItemCount.value).abs() > 1) {
          cartItemCount.value = serverCount;
        }
        print('Updated cartItemCount from server: ${cartItemCount.value}');
      } else {
        errorMessage.value = 'Failed to fetch cart count: ${response.statusCode}';
      }
    } catch (e) {
      //errorMessage.value = 'Error fetching cart count: $e';
    }
  }

  /*Future<void> fetchCartItems() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.getCartItemsEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'cart_id': cartId.value,
        },
      );

      print('Fetch Cart Items Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded JSON: $data');

        if (data is Map<String, dynamic> && data['status'] == 'success') {
          // Update basic cart info
          cartId.value = data['cart_id']?.toString() ?? '1';
          customerName.value = data['customer_name']?.toString() ?? 'Customer';
          customerMobileNumber.value = data['customer_mobile_number']?.toString() ?? '0';
          finalInvoiceId.value = data['final_invoice_id']?.toString() ?? '';

          // Parse items into cartItems
          final items = data['items'] as List? ?? [];
          cartItems.assignAll(items.map((item) => Product.fromCartJson(item)).toList());

          // Reset quantities for master products
          for (var product in products) {
            product.quantity = 0;
            product.cartItemId = null;
          }

          // Sync cart quantities with master product list
          for (var cartItem in cartItems) {
            final matchingProduct = products.firstWhere(
                  (p) => p.productId == cartItem.productId,
              orElse: () => Product(),
            );

            if (matchingProduct.productId != null || matchingProduct.itemName != null) {
              matchingProduct.quantity = cartItem.quantity;
              matchingProduct.cartItemId = cartItem.cartItemId;

              if (cartItem.sellingPrice == null || cartItem.sellingPrice == 0.0) {
                cartItem.sellingPrice = matchingProduct.sellingPrice;
              }
              if (cartItem.itemImage == null) {
                cartItem.itemImage = matchingProduct.itemImage;
              }
            }
          }

          // Update cart item count
          cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);

          // Refresh product lists
          products.refresh();
          filteredProducts.refresh();

          // ✅ Parse cart_summary for totals
          if (data['cart_summary'] != null) {
            final cartSummary = data['cart_summary'];

            totalAmount.value = double.tryParse(cartSummary['subtotal']?.toString() ?? '0') ?? 0.0;
            gstAmount.value = double.tryParse(cartSummary['gst_amount']?.toString() ?? '0') ?? 0.0;
            roundOff.value = double.tryParse(cartSummary['round_of']?.toString() ?? '0') ?? 0.0;

            // Grand Total = Sub-Total + GST + Round-Off
            grandTotal.value = totalAmount.value + gstAmount.value + roundOff.value;
          }

          print('Cart item count: ${cartItemCount.value}');
          print('Sub-Total: ${totalAmount.value}, GST: ${gstAmount.value}, Round-Off: ${roundOff.value}, Grand Total: ${grandTotal.value}');
        } else {
          print('Failed to fetch cart items: ${data['message'] ?? 'Invalid response format'}');
        }
      } else {
        print('Failed to fetch cart items: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception during fetchCartItems: $e');
    }
  }*/
  Future<void> fetchCartItems() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.getCartItemsEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'cart_id': cartId.value,
        },
      );

      print('Fetch Cart Items Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded JSON: $data');

        if (data is Map<String, dynamic> && data['status'] == 'success') {
          // Update basic cart info
          cartId.value = data['cart_id']?.toString() ?? '1';
          customerName.value = data['customer_name']?.toString() ?? 'Customer';
          customerMobileNumber.value = data['customer_mobile_number']?.toString() ?? '0';
          finalInvoiceId.value = data['final_invoice_id']?.toString() ?? '';

          // Parse items
          final items = data['items'] as List? ?? [];
          cartItems.assignAll(items.map((item) => Product.fromCartJson(item)).toList());

          // Reset quantities in master product list
          for (var product in products) {
            product.quantity = 0;
            product.cartItemId = null;
          }

          // Sync quantities and cart_item_id back to main product list
          for (var cartItem in cartItems) {
            final matchingProduct = products.firstWhere(
                  (p) => p.productId == cartItem.productId,
              orElse: () => Product(),
            );

            if (matchingProduct.productId != null) {
              matchingProduct.quantity = cartItem.quantity;
              matchingProduct.cartItemId = cartItem.cartItemId;

              // Fallback image/price if missing in cart
              if (cartItem.itemImage == null || cartItem.itemImage!.isEmpty) {
                cartItem.itemImage = matchingProduct.itemImage;
              }
              if (cartItem.sellingPrice == null || cartItem.sellingPrice == 0.0) {
                cartItem.sellingPrice = matchingProduct.sellingPrice;
              }
            }
          }

          // Update cart count
          cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);

          // CRITICAL FIX: Parse amounts with commas safely
          if (data['cart_summary'] != null) {
            final summary = data['cart_summary'];

            totalAmount.value = _parseAmount(summary['subtotal']);
            gstAmount.value   = _parseAmount(summary['gst_amount']);
            roundOff.value    = _parseAmount(summary['round_of']);
            grandTotal.value  = _parseAmount(summary['grand_total']); // most accurate

            // Optional: Recompute if you don't trust server grand_total
            // grandTotal.value = totalAmount.value + gstAmount.value + roundOff.value;
          } else {
            // Fallback: calculate from items (less accurate due to rounding/GST logic)
            totalAmount.value = cartItems.fold(0.0,
                    (sum, item) => sum + (item.sellingPrice ?? 0.0) * item.quantity);
            gstAmount.value = 0.0;
            roundOff.value = 0.0;
            grandTotal.value = totalAmount.value;
          }

          // Refresh UI
          products.refresh();
          filteredProducts.refresh();
          cartItems.refresh();

          print('Cart synced successfully');
          print('Final Invoice ID: ${finalInvoiceId.value}');
          print('Grand Total: ${grandTotal.value.toStringAsFixed(2)}');
        } else {
          print('Failed to fetch cart: ${data['message'] ?? 'Invalid format'}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchCartItems: $e');
    }
  }

// HELPER FUNCTION – Add this inside ProductController class
  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    String cleaned = value.toString().replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }


  Future<void> incrementQuantity(int index) async {
    //if (await Vibration.hasCustomVibrationsSupport() ?? false) {
      //Vibration.vibrate(duration: 50, amplitude: 100);
    //}
    final product = products[index];
    final newQuantity = product.quantity + 1;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'status': 'Pending',
          'transaction_type': 'Increment',
          'product_id': product.productId ?? product.itemName,
          'gst_type': 'With_GST',
        },
      );

      print('Increment Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'Success' ||
            (responseData['message']?.toString().contains('Item Added') ?? false) ||
            (responseData['message']?.toString().contains('Item Updated') ?? false)) {
          // Update local state only on success
          product.quantity = newQuantity;
          if (responseData['cart_id'] != null) {
            cartId.value = responseData['cart_id'].toString();
          }
          if (responseData['cart_item_id'] != null) {
            product.cartItemId = responseData['cart_item_id'].toString();
          }

          // Update cartItems
          //final cartItemIndex = cartItems.indexWhere(
          //      (item) => item.productId == product.productId || item.itemName == product.itemName,
          //);
          final cartItemIndex = cartItems.indexWhere(
                (item) => item.productId == product.productId,
          );
          if (cartItemIndex != -1) {
            cartItems[cartItemIndex].quantity = newQuantity;
            cartItems[cartItemIndex].cartItemId = product.cartItemId;
          } else {
            cartItems.add(Product(
              productId: product.productId,
              itemName: product.itemName,
              sellingPrice: product.sellingPrice,
              itemImage: product.itemImage,
              quantity: newQuantity,
              cartItemId: product.cartItemId,
            ));
          }

          cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
          products.refresh();
          filteredProducts.refresh();
          await fetchCartItems(); // Sync with server to ensure consistency
        } else {
          errorMessage.value = 'Failed to increment quantity: ${responseData['message'] ?? 'Unknown error'}';
          Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        errorMessage.value = 'Failed to increment quantity: ${response.statusCode} - ${response.body}';
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      //errorMessage.value = 'Error incrementing quantity: $e';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> decrementQuantity(int index) async {
    //if (await Vibration.hasCustomVibrationsSupport() ?? false) {
      //Vibration.vibrate(duration: 40, amplitude: 80);
    //}
    final product = products[index];
    if (product.quantity <= 0) return; // Prevent decrementing below 0
    final newQuantity = product.quantity - 1;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'status': 'Pending',
          'transaction_type': 'Decrement',
          'product_id': product.productId ?? product.itemName,
          'gst_type': 'NO_GST',
        },
      );

      print('Decrement Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'Success' ||
            (responseData['message']?.toString().contains('Item Updated') ?? false) ||
            (responseData['message']?.toString().contains('Item Removed') ?? false)) {
          // Update local state only on success
          product.quantity = newQuantity;
          if (responseData['cart_id'] != null) {
            cartId.value = responseData['cart_id'].toString();
          }

          // Update cartItems
          //final cartItemIndex = cartItems.indexWhere(
          //      (item) => item.productId == product.productId || item.itemName == product.itemName,
          //);
          final cartItemIndex = cartItems.indexWhere(
                (item) => item.productId == product.productId,
          );
          if (cartItemIndex != -1) {
            if (newQuantity == 0) {
              cartItems.removeAt(cartItemIndex);
              product.cartItemId = null;
            } else {
              cartItems[cartItemIndex].quantity = newQuantity;
            }
          }

          cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
          products.refresh();
          filteredProducts.refresh();
          await fetchCartItems(); // Sync with server to ensure consistency
        } else {
          errorMessage.value = 'Failed to decrement quantity: ${responseData['message'] ?? 'Unknown error'}';
          Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        errorMessage.value = 'Failed to decrement quantity: ${response.statusCode} - ${response.body}';
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      //errorMessage.value = 'Error decrementing quantity: $e';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> removeItemFromCart(int index) async {
    final product = products[index];
    if (product.quantity == 0) return; // Nothing to remove

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'status': 'Pending',
          'transaction_type': 'Decrement',
          'product_id': product.productId ?? product.itemName,
        },
      );

      print('Remove Item Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'Success' ||
            (responseData['message']?.toString().contains('Item Removed') ?? false) ||
            (responseData['message']?.toString().contains('Item Updated') ?? false)) {
          // Update local state only on success
          product.quantity = 0;
          product.cartItemId = null;
          //final cartItemIndex = cartItems.indexWhere(
          //      (item) => item.productId == product.productId || item.itemName == product.itemName,
          //);
          final cartItemIndex = cartItems.indexWhere(
                (item) => item.productId == product.productId,
          );
          if (cartItemIndex != -1) {
            cartItems.removeAt(cartItemIndex);
          }
          if (responseData['cart_id'] != null) {
            cartId.value = responseData['cart_id'].toString();
          }
          cartItemCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
          products.refresh();
          filteredProducts.refresh();
          Get.snackbar('Success', '${product.itemName} removed from cart',
              snackPosition: SnackPosition.BOTTOM);
          await fetchCartItems(); // Sync with server
        } else {
          errorMessage.value = 'Failed to remove item: ${responseData['message'] ?? 'Unknown error'}';
          Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        errorMessage.value = 'Failed to remove item: ${response.statusCode} - ${response.body}';
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      //errorMessage.value = 'Error removing item: $e';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      fetchCartCount();
    }
  }

  void resetUICart() {
    // Clears only the local UI state; server state remains intact
    for (var product in products) {
      product.quantity = 0;
      product.cartItemId = null;
    }
    cartItems.clear();
    cartItemCount.value = 0;
    cartId.value = '1';
    customerName.value = 'Customer';
    customerMobileNumber.value = '0';
    finalInvoiceId.value = '';
    products.refresh();
    filteredProducts.refresh();
    Get.snackbar('Success', 'Cart cleared in UI', snackPosition: SnackPosition.BOTTOM);
  }

  List<Product> get selectedProducts => products.where((p) => p.quantity > 0).toList();

  bool get hasItemsInCart => selectedProducts.isNotEmpty;

  double get calculatedTotalAmount => selectedProducts.fold(
      0.0, (sum, p) => sum + (p.sellingPrice! * p.quantity));


  void filterProducts(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      final lowercaseQuery = query.toLowerCase().replaceAll(' ', '');
      filteredProducts.assignAll(
        products.where((product) {
          final lowercaseProductName =
              product.itemName?.toLowerCase().replaceAll(' ', '') ?? '';
          return lowercaseProductName.contains(lowercaseQuery);
        }).toList(),
      );
    }
  }
}