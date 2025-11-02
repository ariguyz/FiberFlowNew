import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// ขอสิทธิ์ + บังคับเปิด Location + ใส่ timeout กันค้าง
  Future<Position?> getCurrentPosition() async {
    // 1) เปิด Location service หรือยัง
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings(); // ชวนผู้ใช้เปิด
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
    }

    // 2) เช็ก/ขอสิทธิ์
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // ผู้ใช้บล็อกสิทธิ์ → ส่งกลับ null แล้วให้หน้าจอแจ้งเตือนเอง
      return null;
    }

    // 3) ดึงตำแหน่ง พร้อม timeLimit กันค้าง
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } on TimeoutException {
      // 4) ไม่ทันเวลา → ใช้ last known position เป็น fallback
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}
