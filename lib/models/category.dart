class Category {
  final String id;
  final String name;
  final String color; // Hex string (e.g. '#2196F3')

  Category({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Other',
      color: json['color'] as String? ?? '#607D8B',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}
