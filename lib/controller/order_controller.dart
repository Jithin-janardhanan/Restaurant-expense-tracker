import 'package:cloud_firestore/cloud_firestore.dart'
    hide Order; // hide Firestore's Order
import '../model/order_model.dart'; // import your own Order model

class OrderController {
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );

  // Add order
  Future<void> addOrder(Order order) async {
    await _ordersRef.doc(order.id).set(order.toMap());
  }

  // Get orders by waiter
  Stream<List<Order>> getOrdersByWaiter(String waiterId) {
    return _ordersRef
        .where('waiterId', isEqualTo: waiterId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Order.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
