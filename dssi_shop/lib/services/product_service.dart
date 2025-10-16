import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import '../models/product.dart';

class ProductService {
  final PocketBase pb;

  ProductService({required this.pb});

  // FutureBuilder method (no changes needed)
  Future<List<Product>> getProducts() async {
    final records = await pb.collection('products').getFullList(
      sort: '-created', // Sort by creation date
    );
    // Assumes Product.fromPocketBase handles URL construction
    return records.map((r) => Product.fromPocketbase(r, pb)).toList();
  }

  Future<Product?> getProduct(String id) async {
    try {
      final record = await pb.collection('products').getOne(id);
      return Product.fromPocketbase(record, pb);
    } catch (e) {
      return null;
    }
  }

  // For StreamBuilder using REAL-TIME subscription (recommended)
  Stream<List<Product>> streamProducts() {
    // Create a StreamController to manage the stream
    final controller = StreamController<List<Product>>();

    // Helper function to fetch and add the latest list to the stream
    void fetchAndAdd() {
      getProducts().then((products) {
        if (!controller.isClosed) {
          controller.add(products);
        }
      }).catchError((error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      });
    }

    // 1. Fetch the initial data
    fetchAndAdd();

    // 2. Subscribe to any changes in the 'products' collection
    pb.collection('products').subscribe('*', (e) {
      // When an event (create, update, delete) occurs,
      // refetch the entire list to get the updated data.
      print('Real-time event received: ${e.action}');
      fetchAndAdd();
    });

    // When the stream is cancelled (e.g., widget is disposed),
    // unsubscribe from the real-time events.
    controller.onCancel = () {
      pb.collection('products').unsubscribe();
    };

    return controller.stream;
  }
}