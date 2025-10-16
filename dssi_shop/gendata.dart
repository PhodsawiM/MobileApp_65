import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

// --- CONFIGURATION ---
const String pocketbaseUrl = 'http://127.0.0.1:8090';
const String collectionName = 'products';
const int numberOfRecordsToCreate = 10;
const int maxExtraImages = 5; // จำนวนรูปเพิ่มเติมสูงสุดต่อ product
// ---------------------

Future<void> main() async {
  print('🚀 Starting DummyJSON → PocketBase data generator...');
  print('   - Target records: $numberOfRecordsToCreate');

  final pb = PocketBase(pocketbaseUrl);

  // 1. Fetch product data from DummyJSON
  final products = await _fetchDummyProducts(numberOfRecordsToCreate);
  if (products.isEmpty) {
    print('❌ Failed to fetch products from DummyJSON.');
    return;
  }

  int successCount = 0;

  for (int i = 0; i < products.length; i++) {
    final product = products[i];
    print('\n--- ⏳ Uploading product ${i + 1}/${products.length} ---');
    print('   - Name: ${product['title']}');

    try {
      // --- 2. Download main image (thumbnail) ---
      final mainImageUrl = product['thumbnail'];
      final mainImageFile =
          mainImageUrl != null ? await _downloadImage(mainImageUrl, 'image') : null;

      // --- 3. Prepare record body ---
      final body = {
        'name': product['title'],
        'description': product['description'],
        'price': product['price'],
        'stock': product['stock'],
        'brand': product['brand'] ?? '',
        'category': product['category'] ?? '',
        'rating': product['rating'] ?? 0,
        'discountPercentage': product['discountPercentage'] ?? 0,
      };

      // --- 4. Create record with main image only ---
      final record = await pb.collection(collectionName).create(
        body: body,
        files: mainImageFile != null ? [mainImageFile] : [],
      );
      print('   - ✅ Created record: ${record.id}');

      // --- 5. Download extra images ---
      final List<dynamic> extraImageUrls = product['images'] ?? [];
      final List<http.MultipartFile> extraImageFiles = [];

      for (var imgUrl in extraImageUrls.take(maxExtraImages)) {
        final imgFile = await _downloadImage(imgUrl, 'images');
        if (imgFile != null) extraImageFiles.add(imgFile);
      }

      // --- 6. Append extra images to 'images' field ---
      if (extraImageFiles.isNotEmpty) {
        await pb.collection(collectionName).update(
          record.id,
          body: {}, // ไม่มีข้อมูลใหม่
          files: extraImageFiles,
        );
        print('   - 📸 Uploaded ${extraImageFiles.length} extra images.');
      }

      successCount++;
    } catch (e) {
      print('   - ❌ Error uploading product: $e');
    }
  }

  print('\n========================================');
  print('✅ Upload complete!');
  print('   - Successfully created $successCount of ${products.length} records.');
  print('========================================');
}

// --- Helper functions ---

Future<List<dynamic>> _fetchDummyProducts(int limit) async {
  final url = Uri.parse('https://dummyjson.com/products?limit=$limit');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    return jsonData['products'] ?? [];
  } else {
    print('❌ Failed to fetch products: ${response.statusCode}');
    return [];
  }
}

Future<http.MultipartFile?> _downloadImage(String imageUrl, String fieldName) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final filename = Uri.parse(imageUrl).pathSegments.last;
      return http.MultipartFile.fromBytes(
        fieldName, // ระบุชื่อฟิลด์ให้ตรงกับ PocketBase
        response.bodyBytes,
        filename: filename,
      );
    } else {
      print('   - ⚠️ Failed to download image: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('   - ⚠️ Exception during image download: $e');
    return null;
  }
}
