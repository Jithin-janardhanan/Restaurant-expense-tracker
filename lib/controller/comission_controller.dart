
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class CommissionController {
  final _ref = FirebaseFirestore.instance.collection('commission_history');

  /// ✅ Save a new commission entry instead of overwriting
  Future<void> saveCommissionSettings({
    required double percent,
    required double threshold,
    required double higherPercent,
  }) async {
    try {
      final now = DateTime.now();
      await _ref.add({
        'percent': percent,
        'threshold': threshold,
        'higherPercent': higherPercent,
        'effectiveFrom': now,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log("✅ New commission settings saved ($percent%) effective from $now");
    } catch (e) {
      log("❌ Failed to save commission: $e");
      rethrow;
    }
  }

  /// ✅ Get the most recent commission settings (for UI default)
  Future<Map<String, dynamic>?> getLatestCommission() async {
    try {
      final snapshot = await _ref
          .orderBy('effectiveFrom', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
    } catch (e) {
      log("❌ Failed to load latest commission: $e");
    }
    return null;
  }

  /// ✅ Get commission applicable at a specific date (for report calculation)
  Future<Map<String, dynamic>?> getCommissionForDate(DateTime date) async {
    try {
      final snapshot = await _ref
          .where('effectiveFrom', isLessThanOrEqualTo: date)
          .orderBy('effectiveFrom', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
    } catch (e) {
      log("❌ Failed to get commission for date $date: $e");
    }
    return null;
  }
}
