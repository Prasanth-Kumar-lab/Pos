import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/cupertino.dart';
import 'package:task/profile/views/profile_page.dart';
import 'package:task/print/views/print_screen.dart';
import '../controller/controller.dart';
class HomeScreen extends StatefulWidget {
  final String name;
  final String username;
  final String mobileNumber;
  final String businessId;
  final String role;
  final String user_id;

  const HomeScreen({
    Key? key,
    required this.name,
    required this.username,
    required this.mobileNumber,
    required this.businessId,
    required this.role,
    required this.user_id,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final ProductController _controller;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  PersistentBottomSheetController? _bottomSheetController;
  bool _isBottomSheetVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ProductController(
      businessId: widget.businessId,
      billerId: widget.user_id,
    ));
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello ${widget.name}.', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Get.to(() => ProfilePage(
              businessId: widget.businessId,
              user_id: widget.user_id,
              role: widget.role,
            ));
          },
          icon: Icon(CupertinoIcons.profile_circled, size: 30, color: Colors.blueGrey.shade900),
        ),
        backgroundColor: Colors.orange.withOpacity(0.6),
        actions: [
          IconButton(onPressed: _controller.fetchProducts, icon: Icon(Icons.sync)),
        ],
      ),
      floatingActionButton: Obx(() {
        if (_controller.cartItemCount.value > 0 && !_isBottomSheetVisible) {
          return Builder(
            builder: (context) => FloatingActionButton.extended(
              onPressed: () {
                _showCartBottomSheet(context);
              },
              icon: Stack(
                children: <Widget>[
                  Icon(Icons.shopping_cart),
                  if (_controller.cartItemCount.value > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_controller.cartItemCount.value}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
              label: Text('View Cart'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return SizedBox.shrink();
      }),
      body: Container(
        color: Colors.orange.withOpacity(0.4),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) => _controller.filterProducts(value),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(() => _controller.isLoading.value
                    ? _buildShimmerGrid()
                    : _controller.errorMessage.isNotEmpty
                    ? Center(child: Text(_controller.errorMessage.value))
                    : _controller.filteredProducts.isEmpty
                    ? Container(
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      child: Lottie.asset('assets/No Data found.json'),
                    ),
                  ),
                )
                    : Scrollbar(
                  thumbVisibility: true,
                  radius: Radius.circular(10),
                  thickness: 6,
                  child: GridView.builder(
                    padding: EdgeInsets.all(7),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                    ),
                    itemCount: _controller.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _controller.filteredProducts[index];
                      final originalIndex = _controller.products.indexOf(product);
                      print('Grid Item at index $index: '
                          'itemName: ${product.itemName != null ? "Displayed (${product.itemName})" : "Not Displayed"}, '
                          'sellingPrice: ${product.sellingPrice != null ? "Displayed (${product.sellingPrice})" : "Not Displayed"}, '
                          'itemImage: ${product.itemImage != null && product.itemImage!.isNotEmpty ? "Displayed (${product.itemImage})" : "Not Displayed"}');
                      final isSearchMatch = _controller.searchQuery.value.isNotEmpty &&
                          (product.itemName != null &&
                              product.itemName!.toLowerCase().replaceAll(' ', '').contains(
                                  _controller.searchQuery.value.toLowerCase().replaceAll(' ', '')));
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSearchMatch
                              ? BorderSide(color: Colors.green, width: 1)
                              : BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  product.itemImage != null && product.itemImage!.isNotEmpty
                                      ? Image.network(
                                    product.itemImage!,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.image_not_supported, size: 50, color: Colors.blueAccent),
                                  )
                                      : Icon(Icons.image_not_supported, size: 50, color: Colors.blueAccent),
                                  SizedBox(height: 8),
                                  Text(
                                    product.itemName ?? 'No name',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '₹${product.sellingPrice?.toStringAsFixed(2) ?? 'N/A'}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => _controller.decrementQuantity(originalIndex),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.red.shade700,
                                      radius: 14,
                                      child: Icon(Icons.remove, color: Colors.white, size: 20),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(product.quantity.toString(), style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _controller.incrementQuantity(originalIndex),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.green.shade700,
                                      radius: 14,
                                      child: Icon(Icons.add, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) async {
    await _controller.fetchCartItems(); // Fetch latest cart items from API
    setState(() {
      _isBottomSheetVisible = true;
    });

    _bottomSheetController = showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: Lottie.asset('assets/Shopping Cart.json'),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Cart Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent.shade700,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.3),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _bottomSheetController?.close();
                          setState(() {
                            _isBottomSheetVisible = false;
                          });
                        },
                        tooltip: 'Close Cart',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final cartTotal = _controller.cartItems.fold(
                    0.0,
                        (sum, p) => sum + ((p.sellingPrice ?? 0.0) * p.quantity),
                  );
                  return ListView(
                    children: [
                      ..._controller.cartItems.asMap().entries.map((entry) {
                        final product = entry.value;
                        final originalIndex = _controller.products.indexWhere((p) => p.productId == product.productId);
                        return Slidable(
                          key: ValueKey(product),
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  if (originalIndex != -1) {
                                    _controller.removeItemFromCart(originalIndex);
                                  }
                                  Get.snackbar(
                                    'Removed',
                                    '${product.itemName} removed from cart',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  if (originalIndex != -1) {
                                    _controller.removeItemFromCart(originalIndex);
                                  }
                                  Get.snackbar(
                                    'Removed',
                                    '${product.itemName} removed from cart',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              child: product.itemImage != null && product.itemImage!.isNotEmpty
                                  ? ClipOval(
                                child: Image.network(
                                  product.itemImage!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image, color: Colors.blueAccent),
                                ),
                              )
                                  : Icon(Icons.image, color: Colors.blueAccent),
                            ),
                            title: Text(product.itemName ?? 'No name'),
                            subtitle: Text(
                              '₹${product.sellingPrice?.toStringAsFixed(2) ?? 'N/A'} x ${product.quantity} = ₹${((product.sellingPrice ?? 0.0) * product.quantity).toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (originalIndex != -1) {
                                      _controller.decrementQuantity(originalIndex);
                                    }
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red.shade700,
                                    radius: 14,
                                    child: Icon(Icons.remove, color: Colors.white, size: 20),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(product.quantity.toString()),
                                SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    if (originalIndex != -1) {
                                      _controller.incrementQuantity(originalIndex);
                                    }
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.green.shade700,
                                    radius: 14,
                                    child: Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      Divider(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              '₹${cartTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.orangeAccent.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: cartTotal > 0
                              ? () {
                            Navigator.pop(context); // Close bottomSheet
                            setState(() {
                              _isBottomSheetVisible = false;
                            });
                            Get.to(() => PrintScreen(
                                selectedProducts: _controller.cartItems.toList(),
                                totalAmount: cartTotal,
                                businessId:widget.businessId
                            ));
                            Get.snackbar(
                              'Checkout',
                              'Proceeding to checkout....',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                              : null,
                          child: Text(
                            'Checkout',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );

    _bottomSheetController!.closed.then((_) {
      setState(() {
        _isBottomSheetVisible = false;
      });
    });
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 14,
                      ),
                      SizedBox(width: 12),
                      Container(
                        width: 20,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}