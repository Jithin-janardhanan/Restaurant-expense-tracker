import 'package:flutter/material.dart';
import 'package:hotelexpenses/controller/item_controll.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final String _type = 'Expense';
  final _controller = CategoryController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 16),
       
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await _controller.addCategory(_nameController.text, _type);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category added!')),
                  );
                  _nameController.clear();
                }
              },
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
