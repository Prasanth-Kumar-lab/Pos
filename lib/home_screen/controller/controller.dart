import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:task/api_endpoints.dart';
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
  RxString customerName = 'Customer'.obs; // Store customer_name
  RxString customerMobileNumber = '0'.obs; // Store customer_mobile_number
  RxString finalInvoiceId = '1'.obs; // Store final_invoice_id

  final String businessId;
  final String billerId;

  ProductController({required this.businessId, required this.billerId});

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.productsEndPoint),
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
        cartItemCount.value = int.tryParse(response.body.trim()) ?? 0;
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
          finalInvoiceId.value = data['final_invoice_id']?.toString() ?? '1';
          final items = data['items'] as List? ?? [];
          cartItems.assignAll(items.map((item) => Product.fromCartJson(item)).toList());

          // Sync quantities and cartItemId with local products
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
          products.refresh();
          filteredProducts.refresh();
          fetchCartCount();
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
    product.quantity++;
    products.refresh();
    filteredProducts.refresh();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'business_id': businessId,
          'biller_id': billerId,
          'status': 'Pending',
          'transaction_type': 'Increment',
          'product_id': product.productId ?? product.itemName,
          'gst_type': 'NO_GST',
        },
      );

      print('Increment Quantity Response: ${response.statusCode} - ${response.body}');

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
            if (responseData['cart_item_id'] != null) {
              product.cartItemId = responseData['cart_item_id'].toString();
              print('Updated cart_item_id for ${product.itemName}: ${product.cartItemId}');
            }
            Get.snackbar('Success', 'Quantity incremented for ${product.itemName}',
                snackPosition: SnackPosition.BOTTOM);
          } else {
            errorMessage.value = 'Failed to increment quantity: ${responseData['message'] ?? 'Unknown error'}';
            product.quantity--;
            products.refresh();
            filteredProducts.refresh();
            Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
          }
        } catch (e) {
          if (response.body.contains('Item Added') || response.body.contains('Item Updated')) {
            Get.snackbar('Success', 'Quantity incremented for ${product.itemName}',
                snackPosition: SnackPosition.BOTTOM);
          } else {
            errorMessage.value = 'Failed to increment quantity: ${response.body}';
            product.quantity--;
            products.refresh();
            filteredProducts.refresh();
            Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
          }
        }
      } else {
        errorMessage.value = 'Failed to increment quantity: ${response.statusCode} - ${response.body}';
        product.quantity--;
        products.refresh();
        filteredProducts.refresh();
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      errorMessage.value = 'Error incrementing quantity: $e';
      product.quantity--;
      products.refresh();
      filteredProducts.refresh();
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      fetchCartCount();
    }
  }

  Future<void> decrementQuantity(int index) async {
    final product = products[index];
    if (product.quantity > 0) {
      product.quantity--;
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

        print('Decrement Quantity Response: ${response.statusCode} - ${response.body}');

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
              Get.snackbar('Success', 'Quantity decremented for ${product.itemName}',
                  snackPosition: SnackPosition.BOTTOM);
            } else {
              errorMessage.value = 'Failed to decrement quantity: ${responseData['message'] ?? 'Unknown error'}';
              product.quantity++;
              products.refresh();
              filteredProducts.refresh();
              Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
            }
          } catch (e) {
            if (response.body.contains('Item Added') || response.body.contains('Item Updated')) {
              Get.snackbar('Success', 'Quantity decremented for ${product.itemName}',
                  snackPosition: SnackPosition.BOTTOM);
            } else {
              errorMessage.value = 'Failed to decrement quantity: ${response.body}';
              product.quantity++;
              products.refresh();
              filteredProducts.refresh();
              Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
            }
          }
        } else {
          errorMessage.value = 'Failed to decrement quantity: ${response.statusCode} - ${response.body}';
          product.quantity++;
          products.refresh();
          filteredProducts.refresh();
          Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        errorMessage.value = 'Error decrementing quantity: $e';
        product.quantity++;
        products.refresh();
        filteredProducts.refresh();
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      } finally {
        fetchCartCount();
      }
    }
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

  Future<void> clearCart() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ordersEndPoint),
        body: {
          'delete_cart_id': cartId.value,
          'business_id': businessId,
          'transaction_type': 'Delete_Order',
        },
      );

      print('Delete Order Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'Success' ||
              (responseData['message'] != null &&
                  (responseData['message'].toString().contains('Item Added') ||
                      responseData['message'].toString().contains('Item Updated')))) {
            for (var product in products) {
              product.quantity = 0;
              product.cartItemId = null;
            }
            cartId.value = '1';
            customerName.value = 'Customer';
            customerMobileNumber.value = '0';
            finalInvoiceId.value = '1';
            products.refresh();
            filteredProducts.refresh();
            Get.snackbar('Success', 'Cart cleared successfully', snackPosition: SnackPosition.BOTTOM);
          } else {
            errorMessage.value = 'Failed to delete order: ${responseData['message'] ?? 'Unknown error'}';
            Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
          }
        } catch (e) {
          if (response.body.contains('Item Added') || response.body.contains('Item Updated')) {
            for (var product in products) {
              product.quantity = 0;
              product.cartItemId = null;
            }
            cartId.value = '1';
            customerName.value = 'Customer';
            customerMobileNumber.value = '0';
            finalInvoiceId.value = '1';
            products.refresh();
            filteredProducts.refresh();
            Get.snackbar('Success', 'Cart cleared successfully', snackPosition: SnackPosition.BOTTOM);
          } else {
            errorMessage.value = 'Failed to delete order: ${response.body}';
            Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
          }
        }
      } else {
        errorMessage.value = 'Failed to delete order: ${response.statusCode} - ${response.body}';
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      errorMessage.value = 'Error deleting order: $e';
      Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.BOTTOM);
    } finally {
      fetchCartCount();
    }
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
}