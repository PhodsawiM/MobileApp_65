
/**
 
 create an e-commerce home page with top shops, top products, and popular reviews sections.

*/


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> topShops = [];
  List<Map<String, dynamic>> topProducts = [];
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  final ScrollController _shopScrollController = ScrollController();
  final ScrollController _productScrollController = ScrollController();

  final double _shopCardWidth = 120;
  final double _productCardWidth = 160;
  final int _visibleCards = 3;

  final String pbToken = 'YOUR_API_TOKEN_HERE';
  final String baseUrl = 'http://127.0.0.1:8090/api/collections';

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    await Future.wait([fetchShops(), fetchProducts(), fetchReviews()]);
    setState(() {
      isLoading = false;
    });
  }

  // Fetch shops
  Future<void> fetchShops() async {
    final url = Uri.parse('$baseUrl/shops/records');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $pbToken'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      topShops = (data['items'] as List).map((shop) {
        return {
          'id': shop['id'],
          'name': shop['name'],
          'image': shop['imageUrl'],
        };
      }).toList();
    }
  }

  // Fetch products (linked to shop)
  Future<void> fetchProducts() async {
    final url = Uri.parse('$baseUrl/product/records');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $pbToken'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      topProducts = (data['items'] as List).map((product) {
        // Find shop info
        final shop = topShops.firstWhere(
          (s) => s['id'] == product['shopId'],
          orElse: () => {'name': 'Unknown', 'image': ''},
        );
        return {
          'name': product['name'],
          'price': product['price'],
          'image': product['imageUrl'],
          'shopName': shop['name'],
        };
      }).toList();
    }
  }

  // Fetch reviews (linked to product)
  Future<void> fetchReviews() async {
    final url = Uri.parse('$baseUrl/reviews/records');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $pbToken'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      reviews = (data['items'] as List).map((review) {
        // Find product info
        final product = topProducts.firstWhere(
          (p) => p['id'] == review['productId'],
          orElse: () => {'name': 'Unknown'},
        );
        return {
          'user': review['user'],
          'review': review['review'],
          'productName': product['name'],
        };
      }).toList();
    }
  }

  void _scrollRight(ScrollController controller, double cardWidth) {
    final double offset = controller.offset + cardWidth * _visibleCards;
    controller.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
  }

  void _scrollLeft(ScrollController controller, double cardWidth) {
    final double offset = controller.offset - cardWidth * _visibleCards;
    controller.animateTo(offset < 0 ? 0 : offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
  }

  @override
  void dispose() {
    _shopScrollController.dispose();
    _productScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E-Commerce Shop")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Shops
                    const Text("Top Shops", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () => _scrollLeft(_shopScrollController, _shopCardWidth),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 140,
                            child: ListView.builder(
                              controller: _shopScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: topShops.length,
                              itemBuilder: (context, index) {
                                final shop = topShops[index];
                                return Card(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    width: _shopCardWidth,
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Image.network(
                                            shop['image'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) => const Icon(Icons.store, size: 40),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(shop['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () => _scrollRight(_shopScrollController, _shopCardWidth),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Top Products
                    const Text("Top Products", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () => _scrollLeft(_productScrollController, _productCardWidth),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 250,
                            child: ListView.builder(
                              controller: _productScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: topProducts.length,
                              itemBuilder: (context, index) {
                                final product = topProducts[index];
                                return Card(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    width: _productCardWidth,
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Image.network(
                                            product['image'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) => const Icon(Icons.shopping_bag, size: 40),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                                        const SizedBox(height: 5),
                                        Text(product['shopName'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 5),
                                        Text("\$${product['price']}", style: const TextStyle(color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () => _scrollRight(_productScrollController, _productCardWidth),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reviews linked to product
                    const Text("Popular Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Column(
                      children: reviews.map((review) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Colors.blue),
                            title: Text(review['user']),
                            subtitle: Text("${review['review']} (Product: ${review['productName']})"),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
