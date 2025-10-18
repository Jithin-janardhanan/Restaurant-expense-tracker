import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart'
    show CollectionReference, FirebaseFirestore, Timestamp;
import '../model/order_model.dart';

class OrderController {
  final CollectionReference _ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );
  final CollectionReference _dailyReportsRef = FirebaseFirestore.instance
      .collection('daily_reports');

  Future<void> addOrder(Order order) async {
    try {
      log('OrderController: Adding order with ID: ${order.id}');
      await _ordersRef.doc(order.id).set(order.toMap());
      log('OrderController: Order successfully written to Firestore');
    } catch (e) {
      log('OrderController: Error adding order: $e');
      rethrow;
    }
  }

  Stream<List<Order>> getOrdersByWaiter(String waiterId) {
    log('OrderController: Getting orders for waiter: $waiterId');
    return _ordersRef.where('waiterId', isEqualTo: waiterId).snapshots().map((
      snapshot,
    ) {
      log(
        'OrderController: Received ${snapshot.docs.length} orders for waiter',
      );
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // ✅ FIXED: Filter by waiter first, then filter date in app (no composite index needed)
  Stream<List<Order>> getOrdersByWaiterAndDate(String waiterId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    log('OrderController: Querying orders for:');
    log('  - Waiter ID: $waiterId');
    log('  - Date range: $startOfDay to $endOfDay');

    // Query only by waiterId (simple index), then filter by date in the app
    return _ordersRef.where('waiterId', isEqualTo: waiterId).snapshots().map((
      snapshot,
    ) {
      log('OrderController: Query returned ${snapshot.docs.length} documents');

      // Filter by date in the app
      final orders = snapshot.docs
          .map((doc) {
            try {
              final order = Order.fromMap(doc.data() as Map<String, dynamic>);
              return order;
            } catch (e) {
              log('  - Error parsing order: $e');
              return null;
            }
          })
          .where((order) => order != null)
          .cast<Order>()
          .where((order) {
            // Filter by date
            final orderDate = DateTime(
              order.date.year,
              order.date.month,
              order.date.day,
            );
            final selectedDate = DateTime(date.year, date.month, date.day);
            return orderDate.isAtSameMomentAs(selectedDate);
          })
          .toList();

      log('OrderController: Filtered to ${orders.length} orders for date');

      return orders;
    });
  }

  Future<void> deleteOrder(String id) async {
    try {
      log('OrderController: Deleting order: $id');

      // Get the order before deleting (to know its date and waiter)
      final orderDoc = await _ordersRef.doc(id).get();

      if (!orderDoc.exists) {
        log('OrderController: No order found with ID: $id');
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final order = Order.fromMap(orderData);

      // Delete the order from orders collection
      await _ordersRef.doc(id).delete();
      log('OrderController: Order deleted successfully');

      // Identify the related daily report ID
      final reportId =
          '${order.waiterId}_${order.date.year}_${order.date.month}_${order.date.day}';

      // Get the related daily report document
      final reportDoc = await _dailyReportsRef.doc(reportId).get();

      if (reportDoc.exists) {
        final reportData = reportDoc.data() as Map<String, dynamic>;
        final List<dynamic> reportOrders = reportData['orders'] ?? [];

        // Remove the deleted order from the report list
        reportOrders.removeWhere((o) => o['id'] == id);

        double updatedTotal = 0.0;
        for (var o in reportOrders) {
          updatedTotal += (o['totalPrice'] ?? 0.0).toDouble();
        }

        if (reportOrders.isEmpty) {
          // If no orders remain for that day, delete the report document
          await _dailyReportsRef.doc(reportId).delete();
          log('OrderController: Daily report deleted (no remaining orders)');
        } else {
          // Otherwise, update the report with the remaining orders and new total
          await _dailyReportsRef.doc(reportId).update({
            'orders': reportOrders,
            'totalAmount': updatedTotal,
          });
          log('OrderController: Daily report updated (order removed)');
        }
      } else {
        log('OrderController: No daily report found for this order');
      }
    } catch (e) {
      log('OrderController: Error deleting order: $e');
      rethrow;
    }
  }

  Future<void> saveDailySummary({
    required String waiterId,
    required String waiterName,
    required DateTime date,
    required List<Order> orders,
  }) async {
    try {
      final total = orders.fold<double>(0.0, (sum, o) => sum + o.totalPrice);
      final reportId = '${waiterId}_${date.year}_${date.month}_${date.day}';

      log('OrderController: Saving daily summary');
      log('  - Report ID: $reportId');
      log('  - Waiter: $waiterName');
      log('  - Total orders: ${orders.length}');
      log('  - Total amount: $total');

      await _dailyReportsRef.doc(reportId).set({
        'waiterId': waiterId,
        'waiterName': waiterName,
        'date': Timestamp.fromDate(date),
        'totalAmount': total,
        'orders': orders.map((o) => o.toMap()).toList(),
      });

      log('OrderController: Daily summary saved successfully');
    } catch (e) {
      log('OrderController: Error saving daily summary: $e');
      rethrow;
    }
  }
}
