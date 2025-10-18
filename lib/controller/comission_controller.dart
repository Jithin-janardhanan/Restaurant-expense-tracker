// import 'package:cloud_firestore/cloud_firestore.dart';

// class CommissionController {
//   final _commissionRef =
//       FirebaseFirestore.instance.collection('commission_settings');

//   /// Save or update commission settings in Firestore
//   Future<void> saveCommissionSettings({
//     required double percent,
//     required double threshold,
//     required double higherPercent,
//   }) async {
//     try {
//       // You can keep only one document if it’s global settings
//       await _commissionRef.doc('default').set({
//         'percent': percent,
//         'threshold': threshold,
//         'higherPercent': higherPercent,
//         'updatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     } catch (e) {
//       print('Error saving commission: $e');
//       rethrow;
//     }
//   }

//   /// Fetch current commission settings
//   Future<Map<String, dynamic>?> getCommissionSettings() async {
//     final doc = await _commissionRef.doc('default').get();
//     if (doc.exists) {
//       return doc.data();
//     }
//     return null;
//   }
// }
