import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hotelexpenses/View/commision_popup.dart';
import 'package:hotelexpenses/controller/comission_controller.dart';

import 'package:hotelexpenses/controller/preview_controller.dart';
import 'package:hotelexpenses/model/preview_model.dart';
import 'package:intl/intl.dart';

class OrderPreviewPage extends StatefulWidget {
  const OrderPreviewPage({super.key});

  @override
  State<OrderPreviewPage> createState() => _OrderPreviewPageState();
}

class _OrderPreviewPageState extends State<OrderPreviewPage> {
  final controller = OrderPreviewController();

  double _commissionPercent = 0;
  double _thresholdAmount = 0;
  double _higherCommissionPercent = 0;

  final commissionController = CommissionController(); // 👈 add this

  @override
  void initState() {
    super.initState();
    _loadCommission(); // 👈 load the saved commission when the page opens
  }

  Future<void> _loadCommission() async {
    final data = await commissionController.getLatestCommission();

    if (data != null) {
      setState(() {
        _commissionPercent = (data['percent'] ?? 0).toDouble();
        _thresholdAmount = (data['threshold'] ?? 0).toDouble();
        _higherCommissionPercent = (data['higherPercent'] ?? 0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.percent),
            tooltip: 'Set Commission',
            onPressed: () async {
              final result = await showCommissionPopup(
                context,
                defaultPercent: _commissionPercent,
                thresholdAmount: _thresholdAmount,
                higherPercent: _higherCommissionPercent,
              );

              if (result != null) {
                setState(() {
                  _commissionPercent = result['percent'];
                  _thresholdAmount = result['threshold'];
                  _higherCommissionPercent = result['higherPercent'];
                });

                //  Save to Firestore
                await commissionController.saveCommissionSettings(
                  percent: _commissionPercent,
                  threshold: _thresholdAmount,
                  higherPercent: _higherCommissionPercent,
                );
              }
            },
          ),
          PopupMenuButton<String>(
            initialValue: controller.filterType,
            onSelected: (value) {
              setState(() => controller.filterType = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'daily', child: Text('Daily')),
              PopupMenuItem(value: 'weekly', child: Text('Weekly')),
              PopupMenuItem(value: 'monthly', child: Text('Monthly')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: StreamBuilder<List<OrderReport>>(
              stream: controller.getReportsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No reports found for this period'),
                      ],
                    ),
                  );
                }

                // final grandTotal = reports.fold<double>(
                //   0.0,
                //   (sum, r) => sum + r.totalAmount,
                // );
                double grandTotal = 0.0;
                double totalCommission = 0.0;

                for (final r in reports) {
                  grandTotal += r.totalAmount;

                  // Get commission per waiter for this report
                  final commissionRate = (r.totalAmount > _thresholdAmount)
                      ? _higherCommissionPercent
                      : _commissionPercent;

                  // Calculate based on waiter’s total
                  final commissionEarned = r.totalAmount * commissionRate / 100;
                  totalCommission += commissionEarned;
                }

                final netIncome = grandTotal - totalCommission;

                return Column(
                  children: [
                    _buildGrandTotalCard(
                      grandTotal,
                      totalCommission,
                      netIncome,
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) =>
                            _buildReportTile(reports[index]),
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
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_sharp),
              onPressed: () {
                setState(() => controller.moveDate(false));
              },
            ),
            Column(
              children: [
                Text(
                  controller.getDateRangeText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  controller.filterType.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_sharp),
              onPressed: () {
                setState(() => controller.moveDate(true));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(
    double total,
    double commission,
    double netIncome,
  ) {
    // Save daily summary to Firestore for Profit & Loss
    _saveDailySummary(total, commission, netIncome);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total (Sales):',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Commission:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  '- ₹${commission.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Income (AC):',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${netIncome.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDailySummary(
    double total,
    double commission,
    double netIncome,
  ) async {
    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);

    final summaryRef = FirebaseFirestore.instance
        .collection('hotel_summary')
        .doc(dateKey); // one doc per day

    await summaryRef.set({
      'date': Timestamp.fromDate(today),
      'totalSales': total,
      'totalCommission': commission,
      'netIncome': netIncome,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _buildReportTile(OrderReport report) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: commissionController.getCommissionForDate(report.date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return ListTile(
            title: Text(report.waiterName),
            subtitle: const Text('No commission data found for this date'),
          );
        }

        final commissionPercent = (data['percent'] ?? 0).toDouble();
        final threshold = (data['threshold'] ?? 0).toDouble();
        final higherPercent = (data['higherPercent'] ?? commissionPercent)
            .toDouble();

        final commissionRate = (report.totalAmount > threshold)
            ? higherPercent
            : commissionPercent;
        final commissionEarned = report.totalAmount * commissionRate / 100;
        final netAmount = report.totalAmount - commissionEarned;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                report.waiterName.isNotEmpty
                    ? report.waiterName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              report.waiterName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy').format(report.date),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${report.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '- ₹${commissionEarned.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '= ₹${netAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...report.orders.map(
                      (o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(o.productName)),
                            Expanded(child: Text('Qty: ${o.quantity}')),
                            Expanded(
                              child: Text(
                                '₹${o.totalPrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items: ${report.orders.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total: ₹${report.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Commission (${commissionRate.toStringAsFixed(1)}%): -₹${commissionEarned.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Net Total: ₹${netAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
