class Product {
  String? itemName;
  double? sellingPrice;
  String? itemImage; // New field for image URL
  int quantity;

  Product({
    this.itemName,
    this.sellingPrice,
    this.itemImage,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemName: json['item_name']?.toString(),
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? ''),
      itemImage: json['item_image']?.toString(), // Parse item_image
      quantity: 0,
    );
  }
}