import 'package:flutter/material.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: const Center(
        child: Text('Expenses details will appear here.'),
      ),
    );
  }
}
