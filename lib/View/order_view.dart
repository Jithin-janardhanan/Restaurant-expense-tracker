import 'package:flutter/material.dart';
import 'package:hotelexpenses/model/waiter_model.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String? selectedWaiter;
  List<Waiter> waitersList = []; // load from Firestore or your WaiterController

  TextEditingController itemNameController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  String? selectedPortion;

  List<Map<String, dynamic>> tempItemsList = [];
  double totalAmount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Select Waiter
            DropdownButton(
              value: selectedWaiter,
              hint: Text('Select Waiter'),
              items: waitersList
                  .map(
                    (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => selectedWaiter = val as String?),
            ),

            // Add Item Name
            TextField(
              controller: itemNameController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),

            // Add Quantity
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),

            // Select Portion (if applicable)
            DropdownButton(
              value: selectedPortion,
              hint: Text('Select Portion'),
              items: [
                'qtr',
                'half',
                'full',
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) =>
                  setState(() => selectedPortion = val as String?),
            ),

            SizedBox(height: 10),

            // Button to add item to temp list
            ElevatedButton(
              onPressed: () {
                if (itemNameController.text.isEmpty ||
                    quantityController.text.isEmpty)
                  return;

                double price = 0; // fetch price from product or leave 0
                tempItemsList.add({
                  'name': itemNameController.text,
                  'portion': selectedPortion,
                  'quantity': int.parse(quantityController.text),
                  'price': price,
                });

                // Update total
                totalAmount = tempItemsList.fold(
                  0,
                  (sum, item) => sum + (item['price'] * item['quantity']),
                );

                // Clear fields
                itemNameController.clear();
                quantityController.clear();
                selectedPortion = null;

                setState(() {});
              },
              child: Text('Add Item'),
            ),

            SizedBox(height: 20),

            // Display added items
            Expanded(
              child: ListView.builder(
                itemCount: tempItemsList.length,
                itemBuilder: (context, index) {
                  final item = tempItemsList[index];
                  return ListTile(
                    title: Text(
                      '${item['name']} (${item['portion'] ?? 'N/A'})',
                    ),
                    subtitle: Text(
                      'Quantity: ${item['quantity']} | Price: ${item['price']}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        tempItemsList.removeAt(index);
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),

            Text('Total: ₹$totalAmount'),

            SizedBox(height: 10),

            // Button to save order
            ElevatedButton(
              onPressed: () {
                if (selectedWaiter == null || tempItemsList.isEmpty) return;

                // Create Order object and save using OrderController
              },
              child: Text('Save Order'),
            ),
          ],
        ),
      ),
    );
  }
}
