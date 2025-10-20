import 'package:flutter/material.dart';
import 'package:hotelexpenses/View/preview_page.dart';
import 'package:hotelexpenses/controller/waiter_controller.dart';
import 'package:hotelexpenses/controller/product_controller.dart';
import 'package:hotelexpenses/controller/order_controller.dart';
import 'package:hotelexpenses/model/waiter_model.dart';
import 'package:hotelexpenses/model/product_model.dart';
import 'package:hotelexpenses/model/order_model.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final waiterController = WaiterController();
  final productController = ProductController();
  final orderController = OrderController();

  String? selectedWaiterId;
  String? selectedWaiterName;
  Product? selectedProduct;
  String? selectedPortion;
  int quantity = 1;
  DateTime selectedDate = DateTime.now();

  // Reset form after adding order
  void _resetForm() {
    setState(() {
      selectedProduct = null;
      selectedPortion = null;
      quantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View All Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderPreviewPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Date Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd-MM-yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Waiter Dropdown
            StreamBuilder<List<Waiter>>(
              stream: waiterController.getWaiters(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final waiters = snapshot.data!;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    hint: const Text('Select Waiter'),
                    value: selectedWaiterId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (id) {
                      final waiter = waiters.firstWhere((w) => w.id == id);
                      setState(() {
                        selectedWaiterId = id;
                        selectedWaiterName = waiter.name;
                      });
                    },
                    items: waiters
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Product Dropdown
            // 🔍 Product Search + Select
            StreamBuilder<List<Product>>(
              stream: productController.getProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        TextEditingController searchController =
                            TextEditingController();
                        List<Product> filteredProducts = List.from(products);

                        return StatefulBuilder(
                          builder: (context, setStateSheet) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Select Product',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: searchController,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search),
                                      hintText: 'Search products...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setStateSheet(() {
                                        filteredProducts = products
                                            .where(
                                              (p) =>
                                                  p.name.toLowerCase().contains(
                                                    value.toLowerCase(),
                                                  ),
                                            )
                                            .toList();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = filteredProducts[index];
                                        return ListTile(
                                          title: Text(product.name),
                                          subtitle: product.portionPrice != null
                                              ? const Text(
                                                  'Portion-based product',
                                                )
                                              : Text('₹${product.price ?? 0}'),
                                          onTap: () {
                                            setState(() {
                                              selectedProduct = product;
                                              selectedPortion = null;
                                            });
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedProduct?.name ?? 'Select Product',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Portion (if applicable)
            if (selectedProduct?.portionPrice != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  hint: const Text('Select Portion'),
                  value: selectedPortion,
                  isExpanded: true,
                  underline: const SizedBox(),
                  onChanged: (portion) =>
                      setState(() => selectedPortion = portion),
                  items: selectedProduct!.portionPrice!.keys
                      .map(
                        (portion) => DropdownMenuItem(
                          value: portion,
                          child: Text(portion),
                        ),
                      )
                      .toList(),
                ),
              ),

            if (selectedProduct?.portionPrice != null)
              const SizedBox(height: 10),

            // Quantity (only for count-based)
            // Quantity (always visible)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Quantity: '),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Manual Price Input (only for "Fish")
            if (selectedProduct != null &&
                selectedProduct!.name.toLowerCase().contains('fish'))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Enter Price (per item or portion)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Store custom price in the product temporarily
                        selectedProduct = Product(
                          id: selectedProduct!.id,
                          name: selectedProduct!.name,
                          price: double.tryParse(value) ?? 0,
                          portionPrice: selectedProduct!.portionPrice,
                        );
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // Add Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add Order'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed:
                    selectedWaiterId == null ||
                        selectedProduct == null ||
                        (selectedProduct!.portionPrice != null &&
                            selectedPortion == null)
                    ? null
                    : () async {
                        try {
                          double price;

                          // 🔹 Case 1: Fish → manual input
                          // 🔹 Case 1: If product name contains "fish" (Fish, Fish Fry, Fish Curry, etc.)
                          if (selectedProduct!.name.toLowerCase().contains(
                            'fish',
                          )) {
                            price = selectedProduct!.price ?? 0;
                            if (price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a valid price for ${selectedProduct!.name}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                          // 🔹 Case 2: Portion-based → use portion price
                          else if (selectedProduct!.portionPrice != null &&
                              selectedPortion != null) {
                            price =
                                selectedProduct!
                                    .portionPrice![selectedPortion] ??
                                0;
                          }
                          // 🔹 Case 3: Normal → use product base price
                          else {
                            price = selectedProduct!.price ?? 0;
                          }

                          final totalPrice = price * quantity;

                          final newOrder = Order(
                            id: const Uuid().v4(),
                            waiterId: selectedWaiterId!,
                            productId: selectedProduct!.id,
                            productName:
                                selectedProduct!.name +
                                (selectedPortion != null
                                    ? ' ($selectedPortion)'
                                    : ''),
                            quantity: quantity,
                            totalPrice: totalPrice,
                            date: selectedDate,
                          );

                          await orderController.addOrder(newOrder);

                          _resetForm(); // Reset form after adding

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order added successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding order: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              ),
            ),

            const Divider(height: 30),

            // Orders List + Save Day Button
            if (selectedWaiterId != null)
              Expanded(
                child: StreamBuilder<List<Order>>(
                  stream: orderController.getOrdersByWaiterAndDate(
                    selectedWaiterId!,
                    selectedDate,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders = snapshot.data!;
                    final total = orders.fold<double>(
                      0.0,
                      (sum, order) => sum + order.totalPrice,
                    );

                    if (orders.isEmpty) {
                      return const Center(
                        child: Text(
                          'No orders yet for this date',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          "Today's Orders",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(
                                    order.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text('Quantity: ${order.quantity}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${order.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Confirm Delete',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this order?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await orderController.deleteOrder(
                                              order.id,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Data'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: orders.isEmpty
                                ? null
                                : () async {
                                    try {
                                      await orderController.saveDailySummary(
                                        waiterId: selectedWaiterId!,
                                        waiterName: selectedWaiterName!,
                                        date: selectedDate,
                                        orders: orders,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Day data saved successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error saving: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
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
