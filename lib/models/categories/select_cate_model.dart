// Whole API response: { "categories": [...], "message": "..." }
class CategoryResponse {
  final List<CategoryModel> categories;
  final String message;

  CategoryResponse({required this.categories, required this.message});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categories: (json['categories'] as List)
          .map((item) => CategoryModel.fromJson(item))
          .toList(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
        'message': message,
      };
}

// One category: { "id": 1, "name": "Study" }
class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}