# MobileApp_65

cd ./MobileApp_65/hello_app

flutter pub get

flutter run -d Chrome


หากพบ error เรื่อง version
====
The current Dart SDK version is 3.8.1.

Because teambuli requires SDK version ^3.9.0, version solving failed.


You can try the following suggestion to make the pubspec resolve:
* Try using the Flutter SDK version: 3.35.3.
===

ให้แก้ไข file pubspec.yaml

เป็น version ที่ใช้ปัจจุบัน อย่างตัวอนี้ให้แก้

environment:
  sdk: ^3.9.0

ให้เป็น

environment:
  sdk: ^3.8.1
