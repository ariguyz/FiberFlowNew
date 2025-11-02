import 'package:flutter/material.dart';

class FiberColors {
  static const List<String> names = [
    'น้ำเงิน', // 1
    'ส้ม', // 2
    'เขียว', // 3
    'น้ำตาล', // 4
    'เทา', // 5
    'ขาว', // 6
    'แดง', // 7
    'ดำ', // 8
    'เหลือง', // 9
    'ม่วง', // 10
    'ชมพู', // 11
    'ฟ้าอ่อน', // 12
  ];

  static const List<Color> flutterColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.brown,
    Colors.grey,
    Colors.white,
    Colors.red,
    Colors.black,
    Colors.yellow,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
  ];

  static String getName(int index) {
    return names[index % names.length];
  }

  static Color getFlutterColor(int index) {
    return flutterColors[index % flutterColors.length];
  }
}
