import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _ref = FirebaseStorage.instance.ref();

  Future<String> uploadProductImage(File file, String filename) async {
    final snapshot = await _ref.child('product_images/$filename').putFile(file);
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }
}
