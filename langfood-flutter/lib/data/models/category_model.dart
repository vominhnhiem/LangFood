class CategoryModel {
  final int id;
  final String name;
  final String? iconUrl;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? json['Id'] ?? 0,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      iconUrl: json['iconUrl'] ?? json['IconUrl'] ?? json['imageUrl'] ?? json['ImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
    };
  }
}
