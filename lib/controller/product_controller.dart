import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotelexpenses/model/product_model.dart';



class ProductController {
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');
  
  

  // CREATE
 Future<void> addProduct(Product product) async {
  await _productsRef.doc(product.id).set(product.toMap());
}


  // READ
  Stream<List<Product>> getProducts() {
    return _productsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // UPDATE
  Future<void> updateProduct(Product product) async {
    await _productsRef.doc(product.id).update(product.toMap());
  }

  // DELETE
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }
}
