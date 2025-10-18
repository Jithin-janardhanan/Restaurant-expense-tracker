// import 'package:flutter/material.dart';
// import 'package:hotelexpenses/View/commision_popup.dart';
// import 'package:hotelexpenses/controller/comission_controller.dart';
// // your showCommissionPopup

// final CommissionController _commissionController = CommissionController();

// Future<void> openCommissionPopup(BuildContext context) async {
//   // Get existing data from Firebase
//   final existing = await _commissionController.getCurrentCommission();

//   final result = await showCommissionPopup(
//     context,
//     defaultPercent: existing?['percent']?.toDouble(),
//     thresholdAmount: existing?['threshold']?.toDouble(),
//     higherPercent: existing?['higherPercent']?.toDouble(),
//   );

//   if (result != null) {
//     await _commissionController.saveCommissionSettings(
//       percent: result['percent'],
//       threshold: result['threshold'],
//       higherPercent: result['higherPercent'],
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Commission settings saved successfully'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
// }
