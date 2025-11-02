// lib/utils/role_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// อ่าน role ของผู้ใช้ปัจจุบันจาก Firestore (users/{uid}.role)
Future<String?> fetchCurrentUserRole() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return doc.data()?['role'] as String?;
}
