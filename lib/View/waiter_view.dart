import 'package:flutter/material.dart';
import 'package:hotelexpenses/controller/waiter_controller.dart';
import 'package:hotelexpenses/model/waiter_model.dart';

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key});

  @override
  _WaiterScreenState createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();

  final WaiterController waiterController = WaiterController();

  void clearControllers() {
    nameController.clear();
    nicknameController.clear();
  }

  void showWaiterDialog({Waiter? waiter}) {
    if (waiter != null) {
      nameController.text = waiter.name;
      nicknameController.text = waiter.nickname;
    } else {
      clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(waiter == null ? 'Add Waiter' : 'Update Waiter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(labelText: 'Nickname'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearControllers();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || nicknameController.text.isEmpty) return;

              Waiter newWaiter = Waiter(
                id: waiter?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                nickname: nicknameController.text,
              );

              if (waiter == null) {
                waiterController.addWaiter(newWaiter);
              } else {
                waiterController.updateWaiter(newWaiter);
              }

              clearControllers();
              Navigator.pop(context);
            },
            child: Text(waiter == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Waiters')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => showWaiterDialog(),
              child: Text('Add New Waiter'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Waiter>>(
                stream: waiterController.getWaiters(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final waiters = snapshot.data!;
                  if (waiters.isEmpty) {
                    return Center(child: Text('No waiters added'));
                  }

                  return ListView.builder(
                    itemCount: waiters.length,
                    itemBuilder: (context, index) {
                      final waiter = waiters[index];
                      return Card(
                        child: ListTile(
                          title: Text(waiter.name),
                          subtitle: Text('Nickname: ${waiter.nickname}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => showWaiterDialog(waiter: waiter),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () =>
                                    waiterController.deleteWaiter(waiter.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
