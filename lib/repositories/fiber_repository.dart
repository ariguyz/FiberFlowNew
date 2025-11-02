import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FiberRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// สร้างเอกสาร fibers ถ้ายังไม่มี (ค้นด้วย cableId)
  /// - ใส่ createdBy เพื่อให้ Rules อนุญาตเจ้าของแก้ไขของตัวเองได้
  Future<DocumentReference<Map<String, dynamic>>> upsertFiber({
    required String cableId,
  }) async {
    final q =
        await _db
            .collection('fibers')
            .where('cableId', isEqualTo: cableId)
            .limit(1)
            .get();

    if (q.docs.isNotEmpty) {
      return q.docs.first.reference;
    }

    final uid = _auth.currentUser?.uid ?? 'unknown';

    return _db.collection('fibers').add({
      'cableId': cableId,
      'createdBy': uid,
      'cores': {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// live doc ของสายตาม cableId (จะ auto-create ถ้าไม่มี)
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchFiberByCableId(
    String cableId,
  ) {
    final q = _db
        .collection('fibers')
        .where('cableId', isEqualTo: cableId)
        .limit(1);

    return q.snapshots().asyncExpand((snap) async* {
      if (snap.docs.isEmpty) {
        final ref = await upsertFiber(cableId: cableId);
        yield* ref.snapshots();
      } else {
        yield* snap.docs.first.reference.snapshots();
      }
    });
  }

  /// อ่านโครงสร้างสาย (ถ้ามี)
  Future<Map<String, dynamic>?> getCableStructure(String cableId) async {
    final q =
        await _db
            .collection('fibers')
            .where('cableId', isEqualTo: cableId)
            .limit(1)
            .get();
    if (q.docs.isEmpty) return null;
    final data = q.docs.first.data();
    return {
      'tubesCount': data['tubesCount'] ?? 0,
      'coresPerTube': data['coresPerTube'] ?? 0,
      'totalCores': data['totalCores'] ?? 0,
    };
    // หมายเหตุ: ถ้ายังไม่เคยเซ็ต จะคืนค่า 0 ทั้งหมด
  }

  /// บันทึกโครงสร้างสาย (จำนวนท่อ และคอร์/ท่อ)
  Future<void> setCableStructure({
    required String cableId,
    required int tubesCount,
    required int coresPerTube,
  }) async {
    final ref = await upsertFiber(cableId: cableId);
    final total = tubesCount * coresPerTube;
    await ref.set({
      'tubesCount': tubesCount,
      'coresPerTube': coresPerTube,
      'totalCores': total,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// อัปเดตสถานะ core (free/used/fault)
  Future<void> setCoreStatus({
    required String docId,
    required int coreNumber,
    required String status, // 'free' | 'used' | 'fault'
  }) async {
    final ref = _db.collection('fibers').doc(docId);
    await ref.set({
      'cores': {'$coreNumber': status},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// บันทึกจุด A, B และระยะห่าง (เมตร)
  Future<void> saveRoute({
    required String docId,
    required double latA,
    required double lngA,
    required double latB,
    required double lngB,
    required double distance,
  }) async {
    final ref = _db.collection('fibers').doc(docId);
    await ref.set({
      'startPoint': {'lat': latA, 'lng': lngA},
      'endPoint': {'lat': latB, 'lng': lngB},
      'distance': distance,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
