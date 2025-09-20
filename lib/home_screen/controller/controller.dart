import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:task/api_endpoints.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  RxList<Product> products = <Product>[].obs;
  RxList<Product> filteredProducts = <Product>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts(); // Fetch products on controller initialization
    filteredProducts.assignAll(products); // Show all by default
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.productsEndPoint),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          products.assignAll(data.map((item) => Product.fromJson(item)).toList());
          filteredProducts.assignAll(products);
          isLoading.value = false;
        } else {
          errorMessage.value = 'Unexpected response format';
          isLoading.value = false;
        }
      } else {
        errorMessage.value = 'Failed to load products: ${response.statusCode}';
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      isLoading.value = false;
    }
  }

  void incrementQuantity(int index) {
    products[index].quantity++;
    products.refresh();
    filteredProducts.refresh();
  }

  void decrementQuantity(int index) {
    if (products[index].quantity > 0) {
      products[index].quantity--;
      products.refresh();
      filteredProducts.refresh();
    }
  }

  List<Product> get selectedProducts =>
      products.where((p) => p.quantity > 0).toList();

  bool get hasItemsInCart => selectedProducts.isNotEmpty;

  double get totalAmount => selectedProducts.fold(
      0.0, (sum, p) => sum + (p.sellingPrice! * p.quantity));

  void clearCart() {
    for (var product in products) {
      product.quantity = 0;
    }
    products.refresh();
    filteredProducts.refresh();
  }

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