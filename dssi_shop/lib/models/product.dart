import 'package:pocketbase/pocketbase.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  factory Product.fromPocketbase(RecordModel record, PocketBase pb) {
    final data = record.data;
    return Product(
      id: record.id,
      name: data['name'] ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
      imageUrl:
          "${pb.baseUrl}/api/files/${record.collectionId}/${record.id}/${data['image']}",
      description: data['description'] ?? '',
    );
  }
}
