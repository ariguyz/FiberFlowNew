// lib/services/firestore_service.dart
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// บริการกลางสำหรับคุยกับ Firestore/Auth/Storage + เพิ่ม log แบบละเอียด
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// helper เอา uid ผู้ใช้ปัจจุบัน
  String? _uid() => _auth.currentUser?.uid;

  // ===========================================================================
  // USER PROFILE / SESSION
  // ===========================================================================

  /// สร้าง/อัปเดตเอกสารผู้ใช้ทุกครั้งที่ล็อกอิน/สมัคร
  /// - เก็บสถานะ emailVerified ให้ตรงกับ FirebaseAuth เสมอ
  /// - **จะไม่เขียนทับฟิลด์ role เดิม** ถ้ามีอยู่แล้ว
  Future<void> ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[ensureUserDoc] no currentUser -> skip');
      return;
    }

    final uid = user.uid;
    final email = user.email ?? '';
    final ref = _db.collection('users').doc(uid);

    debugPrint(
      '[ensureUserDoc] uid=$uid email=$email verified=${user.emailVerified}',
    );

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);

        final base = <String, dynamic>{
          'email': email,
          'emailLower': email.toLowerCase(),
          'emailVerified': user.emailVerified,
          'lastLoginAt': FieldValue.serverTimestamp(),
        };

        if (!snap.exists) {
          debugPrint('[ensureUserDoc] create new user doc');
          tx.set(ref, {
            ...base,
            'role': 'user',
            'calcCount': 0,
            'displayName': user.displayName ?? '',
            'phone': user.phoneNumber ?? '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          debugPrint('[ensureUserDoc] merge existing user doc (keep role)');
          tx.set(ref, {
            ...base,
            if (user.displayName != null) 'displayName': user.displayName,
            if (user.photoURL != null) 'photoUrl': user.photoURL,
          }, SetOptions(merge: true));
        }
      });
      debugPrint('[ensureUserDoc] DONE');
    } catch (e) {
      debugPrint('[ensureUserDoc] ERROR: $e');
      rethrow;
    }
  }

  /// สตรีมโปรไฟล์ผู้ใช้ปัจจุบัน
  Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserDocStream() {
    final uid = _uid();
    if (uid == null) {
      debugPrint('[currentUserDocStream] no uid -> empty stream');
      return const Stream.empty();
    }
    debugPrint('[currentUserDocStream] listen users/$uid');
    return _db.collection('users').doc(uid).snapshots();
  }

  /// ✅ สตรีม role ของผู้ใช้ปัจจุบัน ('admin' | 'user' | null)
  Stream<String?> currentUserRoleStream() {
    return _auth.authStateChanges().asyncExpand((u) {
      if (u == null) return Stream.value(null);
      final ref = _db.collection('users').doc(u.uid);
      return ref.snapshots().map((snap) {
        final role = (snap.data()?['role'] as String?)?.toLowerCase();
        debugPrint('[currentUserRoleStream] role=$role');
        return role;
      });
    });
  }

  Future<String?> getCurrentUserRoleOnce() async {
    final uid = _uid();
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    final role = (snap.data()?['role'] as String?)?.toLowerCase();
    debugPrint('[getCurrentUserRoleOnce] role=$role');
    return role;
  }

  Future<void> setMyRole(String role) async {
    final uid = _uid();
    if (uid == null) return;
    final r = role.toLowerCase();
    if (r != 'user' && r != 'admin') {
      throw Exception('role ไม่ถูกต้อง: $role');
    }
    debugPrint('[setMyRole] $uid -> $r');
    await _db.collection('users').doc(uid).set({
      'role': r,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// อัปเดตโปรไฟล์ (Firestore + Auth)
  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ยังไม่มีผู้ใช้ล็อกอิน');

    final uid = user.uid;

    debugPrint(
      '[updateProfile] uid=$uid displayName="$displayName" phone="$phone" '
      'photoUrlHead="${photoUrl == null ? null : photoUrl.substring(0, photoUrl.length.clamp(0, 48))}"',
    );

    await _db.collection('users').doc(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (displayName != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await user.updatePhotoURL(photoUrl);
    }
    await user.reload();

    debugPrint('[updateProfile] DONE');
  }

  /// อัปเดตข้อมูลบริษัท (เก็บในฟิลด์ company ของ users/{uid})
  Future<void> updateCompanyInfo({
    String? companyName,
    String? department,
    String? position,
    String? employeeId,
    String? site,
    String? supervisorName,
    String? supervisorPhone,
    String? lineId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ยังไม่มีผู้ใช้ล็อกอิน');

    final uid = user.uid;

    final Map<String, dynamic> company = {
      if (companyName != null) 'companyName': companyName,
      if (department != null) 'department': department,
      if (position != null) 'position': position,
      if (employeeId != null) 'employeeId': employeeId,
      if (site != null) 'site': site,
      if (supervisorName != null) 'supervisorName': supervisorName,
      if (supervisorPhone != null) 'supervisorPhone': supervisorPhone,
      if (lineId != null) 'lineId': lineId,
    };

    debugPrint('[updateCompanyInfo] uid=$uid payload=$company');

    await _db.collection('users').doc(uid).set({
      'company': company,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('[updateCompanyInfo] DONE');
  }

  // ===========================================================================
  // AVATAR / STORAGE
  // ===========================================================================

  Future<String> uploadAvatar({
    required String fileName,
    File? file,
    Uint8List? bytes,
    String contentType = 'image/jpeg',
  }) async {
    final uid = _uid();
    if (uid == null) throw Exception('ยังไม่มีผู้ใช้ล็อกอิน');

    final ref = _storage.ref().child('avatars/$uid/$fileName');

    debugPrint(
      '[uploadAvatar] start uid=$uid path=${ref.fullPath} kIsWeb=$kIsWeb file?=${file != null} bytes?=${bytes != null}',
    );

    try {
      if (!kIsWeb && file != null) {
        await ref.putFile(file, SettableMetadata(contentType: contentType));
      } else if (bytes != null) {
        await ref.putData(bytes, SettableMetadata(contentType: contentType));
      } else {
        throw Exception('ไม่พบข้อมูลรูปสำหรับอัปโหลด');
      }

      final url = await ref.getDownloadURL();
      debugPrint('[uploadAvatar] SUCCESS -> $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint(
        '[uploadAvatar] FirebaseException code=${e.code} message=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[uploadAvatar] ERROR: $e');
      rethrow;
    }
  }

  Future<void> deleteAvatarByUrl(String photoUrl) async {
    if (photoUrl.isEmpty) return;
    try {
      debugPrint('[deleteAvatarByUrl] try delete $photoUrl');
      await _storage.refFromURL(photoUrl).delete();
      debugPrint('[deleteAvatarByUrl] DONE');
    } catch (e) {
      debugPrint('[deleteAvatarByUrl] ignore ERROR: $e');
    }
  }

  // ===========================================================================
  // ADMIN TOOLS
  // ===========================================================================

  Future<int> normalizeUserDocs() async {
    debugPrint('[normalizeUserDocs] start');
    int updated = 0;
    final users = await _db.collection('users').get();

    WriteBatch batch = _db.batch();
    for (final d in users.docs) {
      final data = d.data();
      final email = (data['email'] as String?) ?? '';
      final emailLower = (data['emailLower'] as String?) ?? email.toLowerCase();
      final role = (data['role'] as String?) ?? 'user';
      final calcCount = (data['calcCount'] as int?) ?? 0;
      final emailVerified = (data['emailVerified'] as bool?) ?? false;

      batch.set(d.reference, {
        'emailLower': emailLower,
        'role': role,
        'calcCount': calcCount,
        'emailVerified': emailVerified,
      }, SetOptions(merge: true));

      updated++;
      if (updated % 400 == 0) {
        debugPrint('[normalizeUserDocs] commit chunk ($updated)');
        await batch.commit();
        batch = _db.batch();
      }
    }
    await batch.commit();
    debugPrint('[normalizeUserDocs] DONE total=$updated');
    return updated;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersStream() {
    debugPrint('[getAllUsersStream] listen users');
    return _db.collection('users').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> searchUsersByEmailPrefix(
    String query,
  ) {
    if (query.isEmpty) {
      debugPrint('[searchUsersByEmailPrefix] empty -> empty stream');
      return const Stream.empty();
    }
    final q = query.toLowerCase();
    debugPrint('[searchUsersByEmailPrefix] q="$q"');
    return _db
        .collection('users')
        .where('emailLower', isGreaterThanOrEqualTo: q)
        .where('emailLower', isLessThan: '$q\uf8ff')
        .snapshots();
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final r = role.toLowerCase();
    if (r != 'user' && r != 'admin') {
      throw Exception('role ไม่ถูกต้อง: $role');
    }
    debugPrint('[updateUserRole] $userId -> $r');
    await _db.collection('users').doc(userId).set({
      'role': r,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===========================================================================
  // CALCULATIONS (HISTORY)
  // ===========================================================================

  /// สตรีมประวัติของผู้ใช้ตาม userId (ใช้ในหน้าแอดมิน)
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserCalculationsStream(
    String userId,
  ) {
    debugPrint('[getUserCalculationsStream] listen users/$userId/calculations');
    return _db
        .collection('users')
        .doc(userId)
        .collection('calculations')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// สตรีมประวัติของ "ผู้ใช้ปัจจุบัน"
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserHistoryStream() {
    final uid = _uid();
    if (uid == null) {
      debugPrint('[getUserHistoryStream] no uid -> empty');
      return const Stream.empty();
    }
    return getUserCalculationsStream(uid);
  }

  /// ลบหนึ่งรายการประวัติ + ลด calcCount (ฝั่ง client)
  Future<void> deleteHistory({
    required String ownerUid,
    required String docId,
  }) async {
    final calcRef = _db
        .collection('users')
        .doc(ownerUid)
        .collection('calculations')
        .doc(docId);
    final userRef = _db.collection('users').doc(ownerUid);

    debugPrint('[deleteHistory] owner=$ownerUid doc=$docId');
    await _db.runTransaction((tx) async {
      tx.delete(calcRef);
      tx.update(userRef, {'calcCount': FieldValue.increment(-1)});
    });
    debugPrint('[deleteHistory] DONE');
  }

  /// บันทึกผลการคำนวณ (เพิ่ม 1 ลง calcCount) — รองรับ calcType แต่ตั้งค่าเริ่มต้นเป็น 'unknown'
  Future<void> saveCalculationHistory({
    required int inputValue,
    required String result,
    String calcType = 'unknown', // <-- เพิ่มเพื่อไม่กระทบของเดิม
  }) async {
    final uid = _uid();
    final email = _auth.currentUser?.email ?? '';
    if (uid == null) throw Exception('ยังไม่ได้ล็อกอิน');

    final userRef = _db.collection('users').doc(uid);
    final calcRef = userRef.collection('calculations').doc();

    debugPrint(
      '[saveCalculationHistory] uid=$uid input=$inputValue type=$calcType result="$result"',
    );
    await _db.runTransaction((tx) async {
      tx.set(calcRef, {
        'inputValue': inputValue,
        'result': result,
        'calcType': calcType, // <-- บันทึกชนิด
        'timestamp': FieldValue.serverTimestamp(),
      });
      tx.set(userRef, {
        'email': email,
        'emailLower': email.toLowerCase(),
        'calcCount': FieldValue.increment(1),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    debugPrint('[saveCalculationHistory] DONE');
  }
}
