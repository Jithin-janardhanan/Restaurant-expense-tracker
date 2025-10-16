import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:hotelexpenses/model/order_model.dart';

class OrderController {
  final CollectionReference _ordersRef =
      FirebaseFirestore.instance.collection('orders');

  Future<void> addOrder(Order order) async {
    await _ordersRef.doc(order.id).set(order.toMap());
  }

  Stream<List<Order>> getOrdersByWaiter(String waiterId) {
    return _ordersRef
        .where('waiterId', isEqualTo: waiterId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> deleteOrder(String id) async {
    await _ordersRef.doc(id).delete();
  }
}
