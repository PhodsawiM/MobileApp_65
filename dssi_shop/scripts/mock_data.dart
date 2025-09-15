import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:faker/faker.dart';

class PocketBaseManager {
  final String pbUrl;
  final String collectionName;
  final String apiToken;
  final Faker faker = Faker();
  
  // Create a persistent HTTP client
  late final http.Client _httpClient;

  PocketBaseManager({
    required this.pbUrl,
    required this.collectionName,
    required this.apiToken,
  }) {
    // Initialize persistent HTTP client
    _httpClient = http.Client();
  }

  Map<String, dynamic> generateFakeProduct() {
    final user = {
      'name': faker.person.name(),
      'email': faker.internet.email(),
    };

    final reviews = List.generate(
        faker.randomGenerator.integer(5, min: 1), 
        (_) => {
              'user': faker.person.name(),
              'review': faker.lorem.sentence(),
              'rating': faker.randomGenerator.integer(5, min: 1),
            });

    return {
      'name': faker.food.restaurant(),
      'price': faker.randomGenerator.integer(200, min: 10),
      'description': faker.lorem.sentence(),
      'imageUrl': 'https://picsum.photos/200/200?random=${faker.randomGenerator.integer(1000)}',
      'user': user,
      'reviews': reviews,
    };
  }

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
        'Connection': 'keep-alive',
      };

  // Test connection method
  Future<void> testConnection() async {
    print('🔍 Testing connection to PocketBase...');
    try {
      final url = Uri.parse('$pbUrl/$collectionName/records?page=1&perPage=1');
      final response = await _httpClient.get(url, headers: headers);
      print('📡 Connection test status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final totalItems = data['totalItems'] ?? 0;
        print('✅ Connection successful! Found $totalItems total products');
        
        // Also check reviews collection
        final reviewUrl = Uri.parse('$pbUrl/reviews/records?page=1&perPage=1');
        final reviewResp = await _httpClient.get(reviewUrl, headers: headers);
        print('📝 Reviews collection status: ${reviewResp.statusCode}');
        
        if (reviewResp.statusCode == 200) {
          final reviewData = jsonDecode(reviewResp.body);
          final totalReviews = reviewData['totalItems'] ?? 0;
          print('✅ Reviews collection accessible! Found $totalReviews total reviews');
        }
      } else {
        print('❌ Connection failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Connection error: $e');
    }
  }

  // Count all items
  Future<void> countAll() async {
    print('📊 Counting all items...');
    try {
      // Count products
      final url = Uri.parse('$pbUrl/$collectionName/records?page=1&perPage=1');
      final response = await _httpClient.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final totalProducts = data['totalItems'] ?? 0;
        print('📦 Total products: $totalProducts');
      }

      // Count reviews
      final reviewUrl = Uri.parse('$pbUrl/reviews/records?page=1&perPage=1');
      final reviewResp = await _httpClient.get(reviewUrl, headers: headers);
      
      if (reviewResp.statusCode == 200) {
        final reviewData = jsonDecode(reviewResp.body);
        final totalReviews = reviewData['totalItems'] ?? 0;
        print('📝 Total reviews: $totalReviews');
      }
    } catch (e) {
      print('❌ Count error: $e');
    }
  }

  // Helper method with retry logic
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, 
    {int maxRetries = 3, Duration delay = const Duration(milliseconds: 100)}
  ) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await request();
        return response;
      } catch (e) {
        print('   🔄 Attempt $attempt failed: ${e.toString().substring(0, 50)}...');
        
        if (attempt == maxRetries) {
          rethrow;
        }
        
        await Future.delayed(delay * attempt);
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  // Helper method to delete reviews for a product
  Future<void> _deleteProductReviews(String productId) async {
    try {
      final reviewUrl = Uri.parse('$pbUrl/reviews/records?filter=(productId="$productId")&fields=id');
      final reviewResp = await _makeRequest(() => _httpClient.get(reviewUrl, headers: headers));
      
      if (reviewResp.statusCode == 200) {
        final reviewData = jsonDecode(reviewResp.body);
        final reviews = reviewData['items'] as List;
        
        if (reviews.isNotEmpty) {
          print('   📝 Deleting ${reviews.length} reviews');
          
          for (var review in reviews) {
            final delReviewUrl = Uri.parse('$pbUrl/reviews/records/${review['id']}');
            final delResponse = await _makeRequest(
              () => _httpClient.delete(delReviewUrl, headers: headers),
              delay: Duration(milliseconds: 100)
            );
            
            if (delResponse.statusCode == 200 || delResponse.statusCode == 204) {
              print('     ✅ Review deleted: ${review['id']}');
            } else {
              print('     ❌ Failed to delete review: ${review['id']} - ${delResponse.body}');
            }
            
            await Future.delayed(Duration(milliseconds: 50));
          }
        }
      }
    } catch (e) {
      print('   ⚠️  Error deleting reviews: $e');
    }
  }

  // Improved deleteAll method
  Future<void> deleteAll() async {
    print('🔥 Starting deleteAll operation...');
    int totalDeleted = 0;
    
    while (true) {
      print('📄 Fetching next batch...');
      
      try {
        // Always get page 1 since items shift after deletion
        final url = Uri.parse('$pbUrl/$collectionName/records?page=1&perPage=10&fields=id,name');
        final response = await _makeRequest(() => _httpClient.get(url, headers: headers));
        
        if (response.statusCode != 200) {
          print('❌ Failed to fetch products: ${response.statusCode} - ${response.body}');
          break;
        }
        
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        
        if (items.isEmpty) {
          print('✅ No more items to delete');
          break;
        }
        
        print('📦 Found ${items.length} items to process');
        
        for (var item in items) {
          final productId = item['id'];
          final productName = item['name'] ?? 'Unknown';
          
          print('🗑️  Deleting: $productName ($productId)');
          
          try {
            // Delete reviews first
            await _deleteProductReviews(productId);
            
            // Delete product
            final deleteUrl = Uri.parse('$pbUrl/$collectionName/records/$productId');
            final delResp = await _makeRequest(
              () => _httpClient.delete(deleteUrl, headers: headers),
              delay: Duration(milliseconds: 300)
            );
            
            if (delResp.statusCode == 200 || delResp.statusCode == 204) {
              totalDeleted++;
              print('   ✅ Product deleted successfully');
            } else {
              print('   ❌ Failed to delete product: ${delResp.statusCode} - ${delResp.body}');
            }
            
          } catch (e) {
            print('   ❌ Error deleting product: $e');
          }
          
          // Wait between each deletion
          await Future.delayed(Duration(milliseconds: 500));
        }
        
        // Wait before next batch
        await Future.delayed(Duration(seconds: 1));
        
      } catch (e) {
        print('❌ Error in deleteAll: $e');
        break;
      }
    }
    
    print('🎉 DeleteAll completed. Total deleted: $totalDeleted products');
  }

  // Delete only reviews (for testing)
  Future<void> deleteAllReviews() async {
    print('🔥 Starting deleteAllReviews operation...');
    int totalDeleted = 0;
    
    while (true) {
      try {
        final url = Uri.parse('$pbUrl/reviews/records?page=1&perPage=50&fields=id');
        final response = await _makeRequest(() => _httpClient.get(url, headers: headers));
        
        if (response.statusCode != 200) {
          print('❌ Failed to fetch reviews: ${response.statusCode} - ${response.body}');
          break;
        }
        
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        
        if (items.isEmpty) {
          print('✅ No more reviews to delete');
          break;
        }
        
        print('📝 Found ${items.length} reviews to delete');
        
        for (var item in items) {
          final reviewId = item['id'];
          
          try {
            final deleteUrl = Uri.parse('$pbUrl/reviews/records/$reviewId');
            final delResp = await _makeRequest(
              () => _httpClient.delete(deleteUrl, headers: headers),
              delay: Duration(milliseconds: 100)
            );
            
            if (delResp.statusCode == 200 || delResp.statusCode == 204) {
              totalDeleted++;
              print('   ✅ Review deleted: $reviewId');
            } else {
              print('   ❌ Failed to delete review: $reviewId - ${delResp.body}');
            }
            
          } catch (e) {
            print('   ❌ Error deleting review $reviewId: $e');
          }
          
          await Future.delayed(Duration(milliseconds: 100));
        }
        
        await Future.delayed(Duration(milliseconds: 500));
        
      } catch (e) {
        print('❌ Error in deleteAllReviews: $e');
        break;
      }
    }
    
    print('🎉 DeleteAllReviews completed. Total deleted: $totalDeleted reviews');
  }

  // Generate with improved error handling
  Future<void> generate(int count) async {
    print('📝 Generating $count fake products...');
    int successCount = 0;
    
    for (int i = 0; i < count; i++) {
      final product = generateFakeProduct();
      print('Creating product ${i + 1}/$count: ${product['name']}');

      try {
        // Insert product first
        final productUrl = Uri.parse('$pbUrl/$collectionName/records');
        final productResp = await _makeRequest(
          () => _httpClient.post(
            productUrl,
            headers: headers,
            body: jsonEncode({
              'name': product['name'],
              'price': product['price'],
              'description': product['description'],
              'imageUrl': product['imageUrl'],
              'user': product['user'],
            }),
          )
        );

        if (productResp.statusCode == 200 || productResp.statusCode == 201) {
          final insertedProduct = jsonDecode(productResp.body);
          final productId = insertedProduct['id'];
          print('   ✅ Product inserted: $productId');

          // Insert reviews
          final reviews = product['reviews'] as List;
          int reviewSuccessCount = 0;
          
          for (int j = 0; j < reviews.length; j++) {
            final review = reviews[j];
            
            try {
              final reviewUrl = Uri.parse('$pbUrl/reviews/records');
              final reviewResp = await _makeRequest(
                () => _httpClient.post(
                  reviewUrl,
                  headers: headers,
                  body: jsonEncode({
                    'user': review['user'],
                    'review': review['review'],
                    'rating': review['rating'],
                    'productId': productId,
                  }),
                )
              );

              if (reviewResp.statusCode == 200 || reviewResp.statusCode == 201) {
                reviewSuccessCount++;
              } else {
                print('   ❌ Review ${j + 1} failed: ${reviewResp.statusCode} - ${reviewResp.body}');
              }
              
              await Future.delayed(Duration(milliseconds: 100));
            } catch (e) {
              print('   ❌ Review ${j + 1} error: $e');
            }
          }
          
          print('   📝 Reviews inserted: $reviewSuccessCount/${reviews.length}');
          successCount++;

        } else {
          print('   ❌ Product insert failed: ${productResp.statusCode} - ${productResp.body}');
        }
        
      } catch (e) {
        print('   ❌ Error creating product: $e');
      }
      
      await Future.delayed(Duration(milliseconds: 300));
    }
    
    print('🎉 Generation completed! Success: $successCount/$count products');
  }

  // Delete specific number of records
  Future<void> deleteSome(int count) async {
    print('🗑️  Deleting $count products...');
    
    final url = Uri.parse('$pbUrl/$collectionName/records?perPage=$count&fields=id,name');
    final response = await _httpClient.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List;
      
      print('📦 Found ${items.length} items to delete');
      
      for (var item in items) {
        final productId = item['id'];
        final productName = item['name'] ?? 'Unknown';
        print('🗑️  Deleting: $productName');
        
        await _deleteProductReviews(productId);
        
        final deleteUrl = Uri.parse('$pbUrl/$collectionName/records/$productId');
        final delResp = await _httpClient.delete(deleteUrl, headers: headers);
        
        if (delResp.statusCode == 200 || delResp.statusCode == 204) {
          print('   ✅ Deleted: $productId');
        } else {
          print('   ❌ Failed to delete: $productId - ${delResp.body}');
        }
        
        await Future.delayed(Duration(milliseconds: 200));
      }
    } else {
      print('❌ Failed to fetch items for deletion: ${response.statusCode} - ${response.body}');
    }
  }


  // Update a specific product by ID
  Future<void> updateProduct(String productId, Map<String, dynamic> updatedData) async {
    try {
      final url = Uri.parse('$pbUrl/$collectionName/records/$productId');
      final response = await _makeRequest(
        () => _httpClient.patch(
          url,
          headers: headers,
          body: jsonEncode(updatedData),
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Product updated successfully: $productId');
      } else {
        print('❌ Failed to update product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error updating product: $e');
    }
  }

  // Update a specific review by ID
  Future<void> updateReview(String reviewId, Map<String, dynamic> updatedData) async {
    try {
      final url = Uri.parse('$pbUrl/reviews/records/$reviewId');
      final response = await _makeRequest(
        () => _httpClient.patch(
          url,
          headers: headers,
          body: jsonEncode(updatedData),
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Review updated successfully: $reviewId');
      } else {
        print('❌ Failed to update review: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error updating review: $e');
    }
  }

  // Update product and its reviews (optional)
  Future<void> updateProductWithReviews(
    String productId,
    Map<String, dynamic> productData,
    List<Map<String, dynamic>> reviewsData,
  ) async {
    await updateProduct(productId, productData);

    for (var review in reviewsData) {
      if (review.containsKey('id')) {
        final reviewId = review['id'];
        final reviewUpdate = Map<String, dynamic>.from(review)..remove('id');
        await updateReview(reviewId, reviewUpdate);
      }
    }
  }



  // Clean up resources
  void dispose() {
    _httpClient.close();
  }
}

// CLI example
Future<void> main(List<String> args) async {
  final manager = PocketBaseManager(
    pbUrl: 'http://127.0.0.1:8090/api/collections',
    collectionName: 'product',
    apiToken: 'YOUR_API_TOKEN_HERE', // Make sure to update this!
  );

  try {
    if (args.isEmpty) {
      print('Usage: dart run ./scripts/mock_data.dart [command] [count]');
      print('Commands:');
      print('  test          - Test connection and show counts');
      print('  count         - Count all items');
      print('  generate [n]  - Generate n products (default: 10)');
      print('  deleteAll     - Delete all products and reviews');
      print('  deleteAllReviews - Delete all reviews only');
      print('  deleteSome [n] - Delete n products (default: 10)');
      return;
    }

  final command = args[0];
  switch (command) {
    case 'test':
      await manager.testConnection();
      break;

    case 'count':
      await manager.countAll();
      break;

    case 'generate':
      final count = args.length > 1 ? int.parse(args[1]) : 10;
      await manager.generate(count);
      break;

    case 'deleteAll':
      await manager.deleteAll();
      break;

    case 'deleteAllReviews':
      await manager.deleteAllReviews();
      break;

    case 'deleteSome':
      final count = args.length > 1 ? int.parse(args[1]) : 10;
      await manager.deleteSome(count);
      break;

    case 'update':
      if (args.length < 3) {
        print('Usage: dart run ./scripts/mock_data.dart update <productId> <jsonData>');
        return;
      }
      final productId = args[1];
      final updatedData = jsonDecode(args[2]);
      await manager.updateProduct(productId, updatedData);
      break;

    case 'updateWithReviews':
      if (args.length < 3) {
        print('Usage: dart run ./scripts/mock_data.dart updateWithReviews <productId> <jsonData>');
        return;
      }
      final productId2 = args[1];
      final jsonData = jsonDecode(args[2]);
      final productData = jsonData['product'] ?? {};
      final reviewsData = (jsonData['reviews'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      await manager.updateProductWithReviews(productId2, productData, reviewsData);
      break;

    default:
      print('❌ Unknown command: $command');
      print('Use: dart run ./scripts/mock_data.dart --help');
  }

  } finally {
    manager.dispose();
  }
}