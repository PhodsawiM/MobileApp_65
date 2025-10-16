import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ใช้ Consumer เพื่อให้ Widget rebuild เมื่อ cart เปลี่ยนแปลง
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Your Cart'),
            // เพิ่มปุ่มสำหรับล้างตะกร้าทั้งหมด
            actions: [
              if (cart.items.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep),
                  tooltip: 'Clear Cart',
                  onPressed: () {
                    // แสดง dialog ยืนยันก่อนล้างตะกร้า
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Are you sure?'),
                        content: Text('Do you want to remove all items from the cart?'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('No'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: Text('Yes'),
                            onPressed: () {
                              cart.clear();
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: cart.items.isEmpty
                    ? Center(child: Text('Your cart is empty.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) {
                          final productId = cart.items.keys.toList()[i];
                          final cartItem = cart.items.values.toList()[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: FittedBox(
                                          child: Text(
                                              '฿${cartItem.price.toStringAsFixed(0)}')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cartItem.title, style: Theme.of(context).textTheme.titleMedium),
                                        Text(
                                          'Total: ฿${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // --- ส่วนควบคุมจำนวนสินค้า ---
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed: () => cart.removeSingleItem(productId),
                                      ),
                                      Text(cartItem.quantity.toString(), style: const TextStyle(fontSize: 18)),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed: () => cart.addItem(
                                          productId: productId,
                                          title: cartItem.title,
                                          price: cartItem.price,
                                        ),
                                      ),
                                      // --- ปุ่มลบสินค้าออกจากตะกร้า ---
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                        onPressed: () => cart.removeItem(productId),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // --- ส่วนสรุปยอดและปุ่ม Checkout ---
              if (cart.items.isNotEmpty)
                _buildSummaryCard(context, cart),
            ],
          ),
        );
      },
    );
  }

  // Widget สำหรับสร้าง Card สรุปยอด
  Widget _buildSummaryCard(BuildContext context, CartProvider cart) {
    return Card(
      margin: const EdgeInsets.all(15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Total', style: Theme.of(context).textTheme.headlineSmall),
                Chip(
                  label: Text(
                    '฿${cart.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18)
              ),
              child: const Text('CHECKOUT NOW'),
              onPressed: () {
                Navigator.of(context).pushNamed('/checkout');
              },
            )
          ],
        ),
      ),
    );
  }
}

