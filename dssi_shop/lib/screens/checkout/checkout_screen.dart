import 'dart:io';
import 'package:flutter/foundation.dart'; // สำหรับ Uint8List
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  // State สำหรับเก็บข้อมูลรูปภาพและชื่อไฟล์
  Uint8List? _slipImageBytes;
  String? _slipImageName;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _slipImageBytes = bytes;
        _slipImageName = pickedFile.name;
      });
    }
  }

  Future<void> _placeOrder() async {
    // [แก้ไข] ตรวจสอบจาก _slipImageBytes แทน
    if (_slipImageBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a payment slip.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final cart = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final PocketBase pb = userProvider.pb;

    try {
      final orderItems = cart.items.values
          .map((item) => {
                'productId': item.id,
                'title': item.title,
                'quantity': item.quantity,
                'price': item.price,
              })
          .toList();

      final shippingInfo = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
      };

      await pb.collection('orders').create(
        body: {
          'user': userProvider.user!.id,
          'items': orderItems,
          'totalAmount': cart.totalAmount,
          'shippingInfo': shippingInfo,
          'status': 'pending',
        },
        files: [
          // [แก้ไข] ส่งไฟล์โดยใช้ fromBytes
          http.MultipartFile.fromBytes(
            'slip',
            _slipImageBytes!,
            filename: _slipImageName ?? 'payment-slip.jpg', // ใส่ชื่อไฟล์สำรอง
          ),
        ],
      );

      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Failed to place order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... ส่วน Order Summary และ Shipping Info (เหมือนเดิม) ...
            Text('Shipping Information',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                   TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Full Name', border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: 'Address', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your address'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your phone number'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- ส่วนแสดง Slip ที่แก้ไขแล้ว ---
            Text('Payment Slip',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              // [แก้ไข] ตรวจสอบและแสดงรูปจาก _slipImageBytes
              child: _slipImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_slipImageBytes!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Slip Image'),
                        onPressed: _pickImage,
                      ),
                    ),
            ),
            // [แก้ไข] ตรวจสอบจาก _slipImageBytes
            if (_slipImageBytes != null)
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: const Text('Change Image'),
                ),
              ),
            const SizedBox(height: 24),
            // --- สิ้นสุดส่วนที่แก้ไข ---
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: cart.items.isEmpty ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18)),
                child: const Text('Place Order'),
              ),
          ],
        ),
      ),
    );
  }
}