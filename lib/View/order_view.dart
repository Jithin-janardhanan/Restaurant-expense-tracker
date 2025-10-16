import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:hotelexpenses/controller/waiter_controller.dart';
import 'package:hotelexpenses/controller/product_controller.dart';
import 'package:hotelexpenses/controller/order_controller.dart';
import 'package:hotelexpenses/model/waiter_model.dart';
import 'package:hotelexpenses/model/product_model.dart';
import 'package:hotelexpenses/model/order_model.dart';
import 'package:uuid/uuid.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final waiterController = WaiterController();
  final productController = ProductController();
  final orderController = OrderController();

  // 🔹 Move this here (outside the build method)
  String? selectedWaiterId;
  Product? selectedProduct;
  String? selectedPortion;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // ✅ Waiter Dropdown
            StreamBuilder<List<Waiter>>(
              stream: waiterController.getWaiters(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final waiters = snapshot.data!;

                return DropdownButton<String>(
                  hint: const Text('Select Waiter'),
                  value: selectedWaiterId,
                  onChanged: (id) => setState(() => selectedWaiterId = id),
                  items: waiters
                      .map(
                        (w) => DropdownMenuItem<String>(
                          value: w.id,
                          child: Text(w.name),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            SizedBox(height: 10),

            // 🔹 Select Product
            StreamBuilder<List<Product>>(
              stream: productController.getProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final products = snapshot.data!;

                // Ensure selectedProduct is in the new product list
                if (!products.contains(selectedProduct)) {
                  selectedProduct = null;
                }

                return DropdownButton<String>(
                  hint: Text('Select Product'),
                  value: selectedProduct?.id,
                  onChanged: (id) {
                    final product = products.firstWhere((p) => p.id == id);
                    setState(() => selectedProduct = product);
                  },
                  items: products
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                );
              },
            ),
            SizedBox(height: 10),

            // 🔹 Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                ),
                Text('$quantity', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),

            // 🔹 Add Order Button
            ElevatedButton(
              onPressed:
                  selectedWaiterId == null ||
                      selectedProduct == null ||
                      (selectedProduct!.portionPrice != null &&
                          selectedPortion == null)
                  ? null
                  : () async {
                      // 🔹 Determine correct price
                      final price = selectedProduct!.portionPrice != null
                          ? selectedProduct!.portionPrice![selectedPortion] ?? 0
                          : selectedProduct!.price ?? 0;

                      final totalPrice = price * quantity;

                      // 🔹 Create new order
                      final newOrder = Order(
                        id: const Uuid().v4(),
                        waiterId: selectedWaiterId!,
                        productId: selectedProduct!.id,
                        productName:
                            selectedProduct!.name +
                            (selectedPortion != null
                                ? ' (${selectedPortion!})'
                                : ''),
                        quantity: quantity,
                        totalPrice: totalPrice,
                      );

                      await orderController.addOrder(newOrder);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order added successfully!'),
                        ),
                      );
                    },
              child: const Text('Add Order'),
            ),

            Divider(),

            // 🔹 Orders List for Selected Waiter
            if (selectedWaiterId != null)
              Expanded(
                child: StreamBuilder<List<Order>>(
                  stream: orderController.getOrdersByWaiter(selectedWaiterId!),

                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final orders = snapshot.data!;
                    final total = orders.fold(
                      0.0,
                      (sum, order) => sum + order.totalPrice,
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return ListTile(
                                title: Text(order.productName),
                                subtitle: Text(
                                  'Qty: ${order.quantity} | ₹${order.totalPrice.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async => await orderController
                                      .deleteOrder(order.id),
                                ),
                              );
                            },
                          ),
                        ),
                        // 🔹 Total Amount
                        Text(
                          'Total: ₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
