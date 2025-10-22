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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 107, 32, 32),
        foregroundColor: Colors.white,
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
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
      body: Column(
        children: [
          // Top Section - Fixed
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date Selector
                _buildDateSelector(),
                const SizedBox(height: 12),

                // Waiter Dropdown
                StreamBuilder<List<Waiter>>(
                  stream: waiterController.getWaiters(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final waiters = snapshot.data!;
                    return _buildMinimalDropdown(
                      hint: 'Select Waiter',
                      value: selectedWaiterId,
                      items: waiters
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        final waiter = waiters.firstWhere((w) => w.id == id);
                        setState(() {
                          selectedWaiterId = id;
                          selectedWaiterName = waiter.name;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Product Selector
                StreamBuilder<List<Product>>(
                  stream: productController.getProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final products = snapshot.data!;
                    return _buildProductSelector(products);
                  },
                ),

                // Portion Selector
                if (selectedProduct?.portionPrice != null) ...[
                  const SizedBox(height: 12),
                  _buildMinimalDropdown(
                    hint: 'Select Portion',
                    value: selectedPortion,
                    items: selectedProduct!.portionPrice!.keys
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (portion) =>
                        setState(() => selectedPortion = portion),
                  ),
                ],

                const SizedBox(height: 12),

                // Quantity Selector
                _buildQuantitySelector(),

                // Manual Price Input for Fish
                if (selectedProduct != null &&
                    selectedProduct!.name.toLowerCase().contains('fish')) ...[
                  const SizedBox(height: 12),
                  _buildPriceInput(),
                ],

                const SizedBox(height: 16),

                // Add Order Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        selectedWaiterId == null ||
                            selectedProduct == null ||
                            (selectedProduct!.portionPrice != null &&
                                selectedPortion == null)
                        ? null
                        : _addOrder,
                    child: const Text(
                      'Add Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Orders List
          if (selectedWaiterId != null)
            Expanded(
              child: StreamBuilder<List<Order>>(
                stream: orderController.getOrdersByWaiterAndDate(
                  selectedWaiterId!,
                  selectedDate,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  final orders = snapshot.data!;
                  final total = orders.fold<double>(
                    0.0,
                    (sum, order) => sum + order.totalPrice,
                  );

                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _buildOrderItem(order, index);
                          },
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    221,
                                    193,
                                    68,
                                    68,
                                  ),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: orders.isEmpty
                                    ? null
                                    : () => _saveDailySummary(orders),
                                child: const Text(
                                  'Save Data',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        onChanged: onChanged,
        items: items,
      ),
    );
  }

  Widget _buildProductSelector(List<Product> products) {
    return InkWell(
      onTap: () => _showProductSearch(products),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedProduct?.name ?? 'Select Product',
              style: TextStyle(
                fontSize: 15,
                color: selectedProduct == null
                    ? Colors.grey[600]
                    : Colors.black87,
                fontWeight: selectedProduct == null
                    ? FontWeight.w400
                    : FontWeight.w500,
              ),
            ),
            Icon(Icons.search, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showProductSearch(List<Product> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        List<Product> filteredProducts = List.from(products);

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setStateSheet(() {
                        filteredProducts = products
                            .where(
                              (p) => p.name.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  LimitedBox(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontSize: 15),
                          ),
                          subtitle: product.portionPrice != null
                              ? Text(
                                  'Portion-based',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : Text(
                                  '₹${product.price ?? 0}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
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
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Quantity', style: TextStyle(fontSize: 15)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => setState(() => quantity++),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput() {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Price per item',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {
          selectedProduct = Product(
            id: selectedProduct!.id,
            name: selectedProduct!.name,
            price: double.tryParse(value) ?? 0,
            portionPrice: selectedProduct!.portionPrice,
          );
        });
      },
    );
  }

  Widget _buildOrderItem(Order order, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${order.quantity}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _deleteOrder(order),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrder() async {
    try {
      double price;

      if (selectedProduct!.name.toLowerCase().contains('fish')) {
        price = selectedProduct!.price ?? 0;
        if (price <= 0) {
          _showSnackBar(
            'Please enter a valid price for ${selectedProduct!.name}',
            isError: true,
          );
          return;
        }
      } else if (selectedProduct!.portionPrice != null &&
          selectedPortion != null) {
        price = selectedProduct!.portionPrice![selectedPortion] ?? 0;
      } else {
        price = selectedProduct!.price ?? 0;
      }

      final totalPrice = price * quantity;

      final newOrder = Order(
        id: const Uuid().v4(),
        waiterId: selectedWaiterId!,
        productId: selectedProduct!.id,
        productName:
            selectedProduct!.name +
            (selectedPortion != null ? ' ($selectedPortion)' : ''),
        quantity: quantity,
        totalPrice: totalPrice,
        date: selectedDate,
      );

      await orderController.addOrder(newOrder);
      _resetForm();
      _showSnackBar('Order added');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text('Remove this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await orderController.deleteOrder(order.id);
    }
  }

  Future<void> _saveDailySummary(List<Order> orders) async {
    try {
      await orderController.saveDailySummary(
        waiterId: selectedWaiterId!,
        waiterName: selectedWaiterName!,
        date: selectedDate,
        orders: orders,
      );
      _showSnackBar('Data saved successfully');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
