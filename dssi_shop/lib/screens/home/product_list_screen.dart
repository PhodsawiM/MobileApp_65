import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import 'product_detail_screen.dart';
import '../auth/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductListScreen extends StatelessWidget {
  final ProductService _service;

  ProductListScreen({required PocketBase pb}) : _service = ProductService(pb: pb);

  @override
  Widget build(BuildContext context) {
    // ใช้ Consumer เพื่อให้ Widget rebuild เมื่อ cart เปลี่ยนแปลง
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        return Scaffold(
          appBar: AppBar(
            title: Text('Products'),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                  if (cart.items.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          // ใช้ totalQuantity เพื่อนับจำนวนสินค้าทั้งหมด
                          '${cart.totalQuantity}',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    )
                ],
              ),
              if (userProvider.isLoggedIn)
                IconButton(
                  icon: Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () => userProvider.logout(),
                )
              else
                IconButton(
                  icon: Icon(Icons.login),
                  tooltip: 'Login',
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => LoginScreen())),
                ),
            ],
          ),
          body: StreamBuilder<List<Product>>(
            stream: _service.streamProducts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              final products = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // ปรับเป็น 2 คอลัมน์เพื่อให้สวยงามขึ้น
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.7, // ปรับสัดส่วน
                ),
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final p = products[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            productId: p.id,
                            pb: _service.pb,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Hero(
                              tag: p.id,
                              child: CachedNetworkImage(
                                imageUrl: p.imageUrl,
                                placeholder: (_, __) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) => Icon(Icons.error),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text('฿${p.price.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: ElevatedButton(
                              child: Text('Add'),
                              onPressed: () {
                                if (!userProvider.isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please login to add items.')),
                                  );
                                  return;
                                }
                                cart.addItem(
                                  productId: p.id,
                                  title: p.name,
                                  price: p.price,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
