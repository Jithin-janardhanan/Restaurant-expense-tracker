import 'package:flutter/material.dart';
import 'package:hotelexpenses/controller/product_controller.dart';
import 'package:hotelexpenses/model/product_model.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtrController = TextEditingController();
  final halfController = TextEditingController();
  final fullController = TextEditingController();

  final ProductController productController = ProductController();

  void clearControllers() {
    nameController.clear();
    priceController.clear();
    qtrController.clear();
    halfController.clear();
    fullController.clear();
  }

  void showProductDialog({Product? product}) {
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price?.toString() ?? '';
      qtrController.text = product.portionPrice?['qtr']?.toString() ?? '';
      halfController.text = product.portionPrice?['half']?.toString() ?? '';
      fullController.text = product.portionPrice?['full']?.toString() ?? '';
    } else {
      clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Update Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per item (optional)',
                ),
              ),
              SizedBox(height: 20),
              Text('Portion Prices (optional):'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtrController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Qtr Price'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: halfController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Half Price'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fullController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Full Price'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearControllers();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;

              Map<String, double>? portionPrice;
              if ((qtrController.text.isNotEmpty) ||
                  (halfController.text.isNotEmpty) ||
                  (fullController.text.isNotEmpty)) {
                portionPrice = {
                  'qtr': double.tryParse(qtrController.text) ?? 0,
                  'half': double.tryParse(halfController.text) ?? 0,
                  'full': double.tryParse(fullController.text) ?? 0,
                };
              }

              Product newProduct = Product(
                id:
                    product?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                price: priceController.text.isNotEmpty
                    ? double.tryParse(priceController.text)
                    : null,
                portionPrice: portionPrice,
              );

              if (product == null) {
                productController.addProduct(newProduct);
              } else {
                productController.updateProduct(newProduct);
              }

              clearControllers();
              Navigator.pop(context);
            },
            child: Text(product == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => showProductDialog(),
              child: Text('Add New Product'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: productController.getProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  final products = snapshot.data!;
                  if (products.isEmpty)
                    return Center(child: Text('No products added'));

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.price != null)
                                Text('Price: ₹${product.price}'),
                              if (product.portionPrice != null)
                                Text(
                                  'Qtr: ₹${product.portionPrice!['qtr']} | Half: ₹${product.portionPrice!['half']} | Full: ₹${product.portionPrice!['full']}',
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () =>
                                    showProductDialog(product: product),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () =>
                                    productController.deleteProduct(product.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
