class Receipt {
  const Receipt({required this.id, required this.imageUrl, required this.createdAt});

  final int id;
  final String imageUrl;
  final DateTime createdAt;

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as int,
      imageUrl: json['image'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
