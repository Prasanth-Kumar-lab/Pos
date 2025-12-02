/*
class CategoryModel {
  final String categoryName;
  final String businessId;

  CategoryModel({required this.categoryName, required this.businessId});

  Map<String, String> toJson() => {
    'category_name': categoryName,
    'business_id': businessId,
  };
}
*/
class CategoryModel {
  final String categoryName;
  final String businessId;

  CategoryModel({required this.categoryName, required this.businessId});

  // For sending data to API
  Map<String, String> toJson() => {
    'category_name': categoryName,
    'business_id': businessId,
  };

  // For reading data from API
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryName: json['cat_name'] ?? '',
      businessId: json['business_id'] ?? '',
    );
  }
}
