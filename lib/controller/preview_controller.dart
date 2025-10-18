import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotelexpenses/model/preview_model.dart';
import 'package:intl/intl.dart';

class OrderPreviewController {
  String filterType = 'daily';
  DateTime selectedDate = DateTime.now();

  /// 🔹 Format date range text for the top card
  String getDateRangeText() {
    if (filterType == 'daily') {
      return DateFormat('dd MMM yyyy').format(selectedDate);
    } else if (filterType == 'weekly') {
      final startOfWeek = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM yyyy').format(endOfWeek)}';
    } else {
      return DateFormat('MMMM yyyy').format(selectedDate);
    }
  }

  /// 🔹 Get the date range based on filter type
  (DateTime start, DateTime end) getDateRange() {
    DateTime startDate;
    DateTime endDate;

    if (filterType == 'daily') {
      startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      endDate = startDate.add(const Duration(days: 1));
    } else if (filterType == 'weekly') {
      startDate = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = startDate.add(const Duration(days: 7));
    } else {
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      endDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    }

    return (startDate, endDate);
  }

  /// 🔹 Stream of reports from Firestore
  Stream<List<OrderReport>> getReportsStream() {
    final (startDate, endDate) = getDateRange();

    return FirebaseFirestore.instance
        .collection('daily_reports')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderReport.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// 🔹 Move to previous/next period
  void moveDate(bool forward) {
    if (filterType == 'daily') {
      selectedDate = selectedDate.add(Duration(days: forward ? 1 : -1));
    } else if (filterType == 'weekly') {
      selectedDate = selectedDate.add(Duration(days: forward ? 7 : -7));
    } else {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + (forward ? 1 : -1), selectedDate.day);
    }
  }
}
