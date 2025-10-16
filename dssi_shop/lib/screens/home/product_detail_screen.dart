import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:cached_network_image/cached_network_image.dart';
// แนะนำ: เพิ่ม dependency 'photo_view' ใน pubspec.yaml เพื่อการซูมรูปภาพ
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../services/product_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final PocketBase pb;

  const ProductDetailScreen({Key? key, required this.productId, required this.pb})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductService _service;
  late Future<RecordModel> _recordFuture;

  // State สำหรับจัดการรูปภาพที่ถูกเลือก
  String? _selectedImageUrl;
  List<String> _allImageViewerUrls = [];

  @override
  void initState() {
    super.initState();
    _service = ProductService(pb: widget.pb);
    _recordFuture = _service.pb.collection('products').getOne(widget.productId);
  }

  // ฟังก์ชันสำหรับเตรียม URL ของรูปภาพทั้งหมด
  void _prepareImageUrls(RecordModel record) {
    if (_allImageViewerUrls.isNotEmpty) return; // ทำงานแค่ครั้งเดียว

    final mainImageFile = record.getStringValue('image');
    final galleryImageFiles = record.getListValue<String>('images');

    // เพิ่มรูปหลักเข้าไปในลิสต์เป็นรูปแรก
    if (mainImageFile.isNotEmpty) {
      _allImageViewerUrls.add(_service.pb.getFileUrl(record, mainImageFile).toString());
    }

    // เพิ่มรูปจากแกลเลอรี
    for (var filename in galleryImageFiles) {
      _allImageViewerUrls.add(_service.pb.getFileUrl(record, filename).toString());
    }

    // ตั้งค่ารูปที่เลือกไว้เป็นรูปแรก
    if (_allImageViewerUrls.isNotEmpty) {
      _selectedImageUrl = _allImageViewerUrls.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecordModel>(
      future: _recordFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Product not found.')));
        }

        final record = snapshot.data!;
        // เตรียม URL รูปภาพหลังจากได้ข้อมูล record
        _prepareImageUrls(record);

        return Scaffold(
          appBar: AppBar(title: Text(record.getStringValue('name'))),
          body: _buildProductContent(context, record),
          bottomNavigationBar: _buildBottomBar(context, record),
        );
      },
    );
  }

  Widget _buildProductContent(BuildContext context, RecordModel record) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Main Image Viewer ---
          if (_selectedImageUrl != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  // เปิดหน้าดูรูปภาพแบบเต็มจอ
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return FullScreenImageViewer(
                      imageUrls: _allImageViewerUrls,
                      initialIndex: _allImageViewerUrls.indexOf(_selectedImageUrl!),
                    );
                  }));
                },
                child: Hero(
                  tag: 'productImage_${record.id}',
                  child: CachedNetworkImage(
                    imageUrl: _selectedImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => AspectRatio(
                      aspectRatio: 1,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => AspectRatio(
                      aspectRatio: 1,
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          
          // --- Thumbnails Horizontal List ---
          if (_allImageViewerUrls.length > 1)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: _allImageViewerUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = _allImageViewerUrls[index];
                  final isSelected = imageUrl == _selectedImageUrl;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImageUrl = imageUrl;
                      });
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
          // --- Product Details ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.getStringValue('name'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '฿${record.getDoubleValue('price').toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text('Description', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  record.getStringValue('description'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, RecordModel record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -4)),
        ],
      ),
      child: _AddToCartControls(record: record),
    );
  }
}

class _AddToCartControls extends StatelessWidget {
  final RecordModel record;
  const _AddToCartControls({required this.record});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final isInCart = cart.items.containsKey(record.id);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        if (!isInCart) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (!userProvider.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to add items.')));
                return;
              }
              cart.addItem(
                productId: record.id,
                title: record.getStringValue('name'),
                price: record.getDoubleValue('price'),
              );
            },
          );
        } else {
          final quantity = cart.items[record.id]!.quantity;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('In Cart:', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  _buildQuantityButton(
                      context: context,
                      icon: Icons.remove,
                      onPressed: () => cart.removeSingleItem(record.id)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$quantity', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  _buildQuantityButton(
                    context: context,
                    icon: Icons.add,
                    onPressed: () => cart.addItem(
                      productId: record.id,
                      title: record.getStringValue('name'),
                      price: record.getDoubleValue('price'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuantityButton(
      {required BuildContext context,
      required IconData icon,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Icon(icon),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

// --- Widget สำหรับแสดงรูปภาพเต็มจอ ---
class FullScreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        itemCount: imageUrls.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
          );
        },
        pageController: PageController(initialPage: initialIndex),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}

