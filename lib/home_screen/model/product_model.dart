/*
class Product {
  String? itemName;
  double? sellingPrice;
  String? itemImage;
  String? productId; // Assuming product_id is separate from itemName
  String? cartItemId; // New field to store cart_item_id
  int quantity;

  Product({
    this.itemName,
    this.sellingPrice,
    this.itemImage,
    this.productId,
    this.cartItemId,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemName: json['item_name']?.toString(),
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? ''),
      itemImage: json['item_image']?.toString(),
      productId: json['product_id']?.toString(),
      cartItemId: json['cart_item_id']?.toString(), // Optional, if provided by products API
      quantity: 0,
    );
  }
}*/
class Product {
  String? itemName;
  double? sellingPrice;
  String? itemImage;
  String? productId; // Assuming product_id is separate from itemName
  String? cartItemId; // New field to store cart_item_id
  int quantity;

  Product({
    this.itemName,
    this.sellingPrice,
    this.itemImage,
    this.productId,
    this.cartItemId,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemName: json['item_name']?.toString(),
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? ''),
      itemImage: json['item_image']?.toString(),
      productId: json['product_id']?.toString(),
      cartItemId: json['cart_item_id']?.toString(), // Optional, if provided by products API
      quantity: 0,
    );
  }

  factory Product.fromCartJson(Map<String, dynamic> json) {
    return Product(
      itemName: json['product_name']?.toString() ?? json['item_name']?.toString(),
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0.0,
      itemImage: json['item_image']?.toString(),
      productId: json['product_id']?.toString(),
      cartItemId: json['cart_item_id']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }
}