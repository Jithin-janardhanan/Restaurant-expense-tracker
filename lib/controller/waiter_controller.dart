import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotelexpenses/model/waiter_model.dart';

class WaiterController {
  final CollectionReference _waitersRef = FirebaseFirestore.instance.collection(
    'waiters',
  );

  Future<void> addWaiter(Waiter waiter) async {
    await _waitersRef.doc(waiter.id).set(waiter.toMap());
  }

  Stream<List<Waiter>> getWaiters() {
    return _waitersRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Waiter(
          id: data['id'] ?? doc.id, // ✅ fallback to doc.id
          name: data['name'] ?? '',
          nickname: data['nickname'] ?? '',
        );
      }).toList(),
    );
  }

  Future<void> updateWaiter(Waiter waiter) async {
    await _waitersRef.doc(waiter.id).update(waiter.toMap());
  }

  Future<void> deleteWaiter(String id) async {
    await _waitersRef.doc(id).delete();
  }
}
