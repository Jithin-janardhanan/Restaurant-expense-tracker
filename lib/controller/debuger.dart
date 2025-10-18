import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Temporary debug widget to check Firestore connection
/// Add this to your OrderPage to debug
class FirestoreDebugWidget extends StatelessWidget {
  const FirestoreDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: ExpansionTile(
        leading: const Icon(Icons.bug_report),
        title: const Text('Debug Info'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Check all orders
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final snapshot = await FirebaseFirestore.instance
                          .collection('orders')
                          .get();

                      log('=== FIRESTORE DEBUG ===');
                      log('Total orders in database: ${snapshot.docs.length}');

                      if (snapshot.docs.isEmpty) {
                        log('❌ No orders found in Firestore!');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No orders found in Firestore'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        log('✅ Orders found!');
                        for (var doc in snapshot.docs) {
                          final data = doc.data();
                          log('Order: ${doc.id}');
                          log('  Waiter ID: ${data['waiterId']}');
                          log('  Product: ${data['productName']}');
                          log(
                            '  Date: ${(data['date'] as Timestamp).toDate()}',
                          );
                          log('  Price: ${data['totalPrice']}');
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Found ${snapshot.docs.length} orders. Check logs!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      log('=====================');
                    } catch (e) {
                      log('❌ Error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Check All Orders'),
                ),

                const SizedBox(height: 8),

                // Check Firestore connection
                ElevatedButton(
                  onPressed: () async {
                    try {
                      log('Testing Firestore connection...');
                      final testDoc = await FirebaseFirestore.instance
                          .collection('test')
                          .doc('connection_test')
                          .set({'timestamp': FieldValue.serverTimestamp()});

                      log('✅ Firestore write successful');

                      final doc = await FirebaseFirestore.instance
                          .collection('test')
                          .doc('connection_test')
                          .get();

                      if (doc.exists) {
                        log('✅ Firestore read successful');
                        log('Data: ${doc.data()}');

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Firestore connection OK!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      log('❌ Firestore error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Connection error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Test Firestore Connection'),
                ),

                const SizedBox(height: 8),

                // Stream test
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        '❌ Stream Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Text('⏳ Loading stream...');
                    }

                    return Text(
                      '✅ Stream active: ${snapshot.data!.docs.length} orders',
                      style: const TextStyle(color: Colors.green),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add this to your OrderPage widget tree:
// const FirestoreDebugWidget(),
