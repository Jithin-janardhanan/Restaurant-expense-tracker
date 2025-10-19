import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryController {
  final CollectionReference _categoryRef =
      FirebaseFirestore.instance.collection('categories');

  // Add a new category
  Future<void> addCategory(String name, String type) async {
    await _categoryRef.add({
      'name': name,
      'type': type, // 'Expense' or 'Income'
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Fetch all categories
  Stream<List<Map<String, dynamic>>> getCategories() {
    return _categoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'type': doc['type'],
        };
      }).toList();
    });
  }
}
