import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseController {
  final CollectionReference _expensesRef = FirebaseFirestore.instance
      .collection('expenses');

  Future<void> addExpense({
    required String categoryId,
    required String categoryName,
    required String type,
    required double amount,
    required DateTime date,
  }) async {
    await _expensesRef.add({
      'category_id': categoryId,
      'category_name': categoryName,
      'type': type, // Expense or Income
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  Future<void> deleteExpense(String id) async {
  await _expensesRef.doc(id).delete();
}


  // Fetch expenses for a specific month
  Stream<List<Map<String, dynamic>>> getExpensesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _expensesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'category_name': data['category_name'],
              'amount': data['amount'],
              'type': data['type'],
              'date': (data['date'] as Timestamp).toDate(),
            };
          }).toList(),
        );
  }
}
