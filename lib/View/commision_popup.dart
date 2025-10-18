import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showCommissionPopup(BuildContext context,
    {double? defaultPercent, double? thresholdAmount, double? higherPercent}) {
  final percentController =
      TextEditingController(text: defaultPercent?.toString() ?? '');
  final thresholdController =
      TextEditingController(text: thresholdAmount?.toString() ?? '');
  final higherPercentController =
      TextEditingController(text: higherPercent?.toString() ?? '');

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Set Commission Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: percentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Commission (%)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: thresholdController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Threshold Amount (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: higherPercentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Higher Commission (%) if threshold exceeded',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final percent = double.tryParse(percentController.text);
              final threshold = double.tryParse(thresholdController.text);
              final higher = double.tryParse(higherPercentController.text);

              if (percent == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid commission percentage'),
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'percent': percent,
                'threshold': threshold ?? 0,
                'higherPercent': higher ?? percent,
              });
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
