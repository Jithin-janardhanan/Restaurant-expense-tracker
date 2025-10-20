import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: selectedStartDate,
        end: selectedEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Sales Summary'),
            Tab(icon: Icon(Icons.percent), text: 'Commission History'),
            Tab(icon: Icon(Icons.trending_up), text: 'Profit & Loss'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesSummaryTab(),
                _buildCommissionHistoryTab(),
                _buildProfitLossTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.date_range),
        title: Text(
          '${DateFormat('dd MMM yyyy').format(selectedStartDate)} - ${DateFormat('dd MMM yyyy').format(selectedEndDate)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${selectedEndDate.difference(selectedStartDate).inDays + 1} days',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: const Text('Change'),
          onPressed: _selectDateRange,
        ),
      ),
    );
  }

  // 📊 SALES SUMMARY TAB (Now includes expenses)
  Widget _buildSalesSummaryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotel_summary')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(selectedStartDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(
              selectedEndDate.add(const Duration(days: 1)),
            ),
          )
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, summarySnapshot) {
        if (summarySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (summarySnapshot.hasError) {
          return Center(child: Text('Error: ${summarySnapshot.error}'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(selectedStartDate),
              )
              .where(
                'date',
                isLessThanOrEqualTo: Timestamp.fromDate(
                  selectedEndDate.add(const Duration(days: 1)),
                ),
              )
              .snapshots(),
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final summaryDocs = summarySnapshot.data?.docs ?? [];
            final expenseDocs = expenseSnapshot.data?.docs ?? [];

            if (summaryDocs.isEmpty && expenseDocs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('No data available for this period'),
                  ],
                ),
              );
            }

            double totalSales = 0;
            double totalCommission = 0;
            double totalNetIncome = 0;
            double totalExpenses = 0;

            for (final doc in summaryDocs) {
              final data = doc.data() as Map<String, dynamic>;
              totalSales += (data['totalSales'] ?? 0.0).toDouble();
              totalCommission += (data['totalCommission'] ?? 0.0).toDouble();
              totalNetIncome += (data['netIncome'] ?? 0.0).toDouble();
            }

            for (final doc in expenseDocs) {
              final data = doc.data() as Map<String, dynamic>;
              totalExpenses += (data['amount'] ?? 0.0).toDouble();
            }

            final actualProfit = totalNetIncome - totalExpenses;

            return Column(
              children: [
                _buildEnhancedSummaryCards(
                  totalSales,
                  totalCommission,
                  totalNetIncome,
                  totalExpenses,
                  actualProfit,
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Daily Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildDailyBreakdownList(summaryDocs, expenseDocs),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDailyBreakdownList(
    List<QueryDocumentSnapshot> summaryDocs,
    List<QueryDocumentSnapshot> expenseDocs,
  ) {
    // Group expenses by date
    Map<String, double> expensesByDate = {};
    for (final doc in expenseDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      expensesByDate[dateKey] =
          (expensesByDate[dateKey] ?? 0) + (data['amount'] ?? 0.0).toDouble();
    }

    return ListView.builder(
      itemCount: summaryDocs.length,
      itemBuilder: (context, index) {
        final data = summaryDocs[index].data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final sales = (data['totalSales'] ?? 0.0).toDouble();
        final commission = (data['totalCommission'] ?? 0.0).toDouble();
        final netIncome = (data['netIncome'] ?? 0.0).toDouble();
        final dailyExpenses = expensesByDate[dateKey] ?? 0.0;
        final actualProfit = netIncome - dailyExpenses;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                DateFormat('dd').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              DateFormat('EEEE, dd MMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Actual Profit: ₹${actualProfit.toStringAsFixed(2)}',
              style: TextStyle(
                color: actualProfit >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildDetailRow('Sales', sales, Colors.blue),
                    _buildDetailRow('Commission', commission, Colors.orange),
                    _buildDetailRow('Net Income', netIncome, Colors.green),
                    if (dailyExpenses > 0)
                      _buildDetailRow('Expenses', dailyExpenses, Colors.red),
                    const Divider(),
                    _buildDetailRow(
                      'Actual Profit',
                      actualProfit,
                      actualProfit >= 0 ? Colors.green : Colors.red,
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

  Widget _buildDetailRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCards(
    double sales,
    double commission,
    double net,
    double expenses,
    double actualProfit,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Sales',
                  '₹${sales.toStringAsFixed(2)}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Commission',
                  '₹${commission.toStringAsFixed(2)}',
                  Icons.payments,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Net Income',
                  '₹${net.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Expenses',
                  '₹${expenses.toStringAsFixed(2)}',
                  Icons.money_off,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatCard(
            'Actual Profit',
            '₹${actualProfit.toStringAsFixed(2)}',
            Icons.trending_up,
            actualProfit >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 💰 COMMISSION HISTORY TAB (Unchanged)
  Widget _buildCommissionHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('commission_history')
          .orderBy('effectiveFrom', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.percent, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No commission history found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final percent = (data['percent'] ?? 0.0).toDouble();
            final threshold = (data['threshold'] ?? 0.0).toDouble();
            final higherPercent = (data['higherPercent'] ?? 0.0).toDouble();
            final effectiveFrom = (data['effectiveFrom'] as Timestamp).toDate();

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Effective from: ${DateFormat('dd MMM yyyy, hh:mm a').format(effectiveFrom)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Base Commission: $percent%'),
                    Text('Threshold: ₹${threshold.toStringAsFixed(2)}'),
                    Text(
                      'Higher Commission: $higherPercent% (above threshold)',
                    ),
                  ],
                ),
                trailing: index == 0
                    ? Chip(
                        label: const Text('Current'),
                        backgroundColor: Colors.green.shade100,
                        labelStyle: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // 📈 PROFIT & LOSS TAB (Enhanced with expenses)
  Widget _buildProfitLossTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotel_summary')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(selectedStartDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(
              selectedEndDate.add(const Duration(days: 1)),
            ),
          )
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, summarySnapshot) {
        if (summarySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (summarySnapshot.hasError) {
          return Center(child: Text('Error: ${summarySnapshot.error}'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(selectedStartDate),
              )
              .where(
                'date',
                isLessThanOrEqualTo: Timestamp.fromDate(
                  selectedEndDate.add(const Duration(days: 1)),
                ),
              )
              .snapshots(),
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final summaryDocs = summarySnapshot.data?.docs ?? [];
            final expenseDocs = expenseSnapshot.data?.docs ?? [];

            if (summaryDocs.isEmpty && expenseDocs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_chart, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No profit & loss data available'),
                  ],
                ),
              );
            }

            double totalRevenue = 0;
            double totalCommission = 0;
            double totalNetIncome = 0;
            double totalExpenses = 0;

            for (final doc in summaryDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final sales = (data['totalSales'] ?? 0.0).toDouble();
              final commission = (data['totalCommission'] ?? 0.0).toDouble();
              final netIncome = (data['netIncome'] ?? 0.0).toDouble();

              totalRevenue += sales;
              totalCommission += commission;
              totalNetIncome += netIncome;
            }

            for (final doc in expenseDocs) {
              final data = doc.data() as Map<String, dynamic>;
              totalExpenses += (data['amount'] ?? 0.0).toDouble();
            }

            final actualProfit = totalNetIncome - totalExpenses;
            final profitMargin = totalRevenue > 0
                ? (actualProfit / totalRevenue * 100)
                : 0.0;

            // Group expenses by date
            Map<String, double> expensesByDate = {};
            Map<String, List<Map<String, dynamic>>> expenseDetailsByDate = {};

            for (final doc in expenseDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final amount = (data['amount'] ?? 0.0).toDouble();

              expensesByDate[dateKey] = (expensesByDate[dateKey] ?? 0) + amount;

              if (!expenseDetailsByDate.containsKey(dateKey)) {
                expenseDetailsByDate[dateKey] = [];
              }
              expenseDetailsByDate[dateKey]!.add({
                'category': data['category_name'] ?? 'Unknown',
                'amount': amount,
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Period Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildPLRow(
                            'Total Revenue',
                            totalRevenue,
                            Colors.green,
                          ),
                          _buildPLRow(
                            'Commission',
                            totalCommission,
                            Colors.orange,
                          ),
                          _buildPLRow(
                            'Net Income',
                            totalNetIncome,
                            Colors.green,
                          ),
                          _buildPLRow(
                            'Hotel Expenses',
                            totalExpenses,
                            Colors.red,
                          ),
                          const Divider(thickness: 2),
                          _buildPLRow(
                            'Actual Profit',
                            actualProfit,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profit Margin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${profitMargin.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: profitMargin > 50
                                      ? Colors.green
                                      : profitMargin > 25
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Profit & Loss',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...summaryDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final sales = (data['totalSales'] ?? 0.0).toDouble();
                    final commission = (data['totalCommission'] ?? 0.0)
                        .toDouble();
                    final netIncome = (data['netIncome'] ?? 0.0).toDouble();
                    final dailyExpenses = expensesByDate[dateKey] ?? 0.0;
                    final actualDailyProfit = netIncome - dailyExpenses;
                    final margin = sales > 0
                        ? (actualDailyProfit / sales * 100)
                        : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Text(
                            DateFormat('dd').format(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          DateFormat('EEEE, dd MMM yyyy').format(date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Profit: ₹${actualDailyProfit.toStringAsFixed(2)} | Margin: ${margin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: actualDailyProfit >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPLRow('Revenue', sales, Colors.green),
                                _buildPLRow(
                                  'Commission',
                                  commission,
                                  Colors.orange,
                                ),
                                _buildPLRow(
                                  'Net Income',
                                  netIncome,
                                  Colors.green,
                                ),
                                if (dailyExpenses > 0) ...[
                                  const Divider(),
                                  const Text(
                                    'Hotel Expenses:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...?expenseDetailsByDate[dateKey]?.map(
                                    (expense) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            expense['category'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '₹${expense['amount'].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildPLRow(
                                    'Total Expenses',
                                    dailyExpenses,
                                    Colors.red,
                                  ),
                                ],
                                const Divider(thickness: 2),
                                _buildPLRow(
                                  'Actual Profit',
                                  actualDailyProfit,
                                  actualDailyProfit >= 0
                                      ? Colors.blue
                                      : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPLRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
