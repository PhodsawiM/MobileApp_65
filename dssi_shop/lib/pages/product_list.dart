import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class RealTimeListPage extends StatefulWidget {
  const RealTimeListPage({super.key});

  @override
  State<RealTimeListPage> createState() => _RealTimeListPageState();
}

class _RealTimeListPageState extends State<RealTimeListPage> {
  final String pbUrl = 'http://127.0.0.1:8090/api/collections/product/records';
  final String wsUrl = 'ws://127.0.0.1:8090/api/realtime';
  final String apiToken = 'YOUR_API_TOKEN_HERE';

  List<Map<String, dynamic>> products = [];
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    fetchInitialProducts();
    connectWebSocket();
  }

  // 1️⃣ Fetch initial data
  Future<void> fetchInitialProducts() async {
    final response = await http.get(Uri.parse(pbUrl), headers: {
      'Authorization': 'Bearer $apiToken',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        products = (data['items'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } else {
      print('Failed to load products: ${response.body}');
    }
  }

  // 2️⃣ Connect to PocketBase realtime
  void connectWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('$wsUrl/products'));

    channel.stream.listen((message) {
      final event = jsonDecode(message);
      final record = event['record'] as Map<String, dynamic>?;
      final action = event['action'];

      if (record != null) {
        setState(() {
          switch (action) {
            case 'create':
              products.add(record);
              break;
            case 'update':
              final index = products.indexWhere((p) => p['id'] == record['id']);
              if (index >= 0) products[index] = record;
              break;
            case 'delete':
              products.removeWhere((p) => p['id'] == record['id']);
              break;
          }
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  // 3️⃣ CRUD methods
  Future<void> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(pbUrl),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Product created!');
    } else {
      print('Failed to create: ${response.body}');
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$pbUrl/$id'),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      print('Product updated!');
    } else {
      print('Failed to update: ${response.body}');
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$pbUrl/$id'),
      headers: {'Authorization': 'Bearer $apiToken'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('Product deleted!');
    } else {
      print('Failed to delete: ${response.body}');
    }
  }

  // 4️⃣ Dialogs for Create/Update
  void showProductDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name']);
    final priceController = TextEditingController(text: product?['price']?.toString());
    final descController = TextEditingController(text: product?['description']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? 'Create Product' : 'Update Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'price': int.tryParse(priceController.text) ?? 0,
                'description': descController.text,
              };
              if (product == null) {
                await createProduct(data);
              } else {
                await updateProduct(product['id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Products')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: product['imageUrl'] != null
                      ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.shopping_bag),
                  title: Text(product['name'] ?? 'Unknown'),
                  subtitle: Text("\$${product['price']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => showProductDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteProduct(product['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
