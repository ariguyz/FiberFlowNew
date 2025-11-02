import 'package:cloud_firestore/cloud_firestore.dart';

class FiberRepository {
  final _db = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> upsertFiber({
    required String cableId,
  }) async {
    final q =
        await _db
            .collection('fibers')
            .where('cableId', isEqualTo: cableId)
            .limit(1)
            .get();
    if (q.docs.isNotEmpty) return q.docs.first.reference;

    return _db.collection('fibers').add({
      'cableId': cableId,
      'cores': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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

// TODO Implement this library.
