import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:adm/utils/utils.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('notification');
  final TextEditingController _textController = TextEditingController();
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() async {
    final snapshot = await _ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as List<dynamic>;
      setState(() {
        _notifications = List<String>.from(data); // Convert to growable list
      });
    }
  }

  void _addNotification() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _notifications.add(_textController.text);
        _textController.clear();
      });
      _saveNotifications();
    }
  }

  void _saveNotifications() {
    if (_notifications.isNotEmpty) {
      _ref.set(_notifications).then((_) {
        Utils().toastMessage(context, 'Notifications saved successfully!');
      }).catchError((error) {
        Utils().toastMessage(context, 'Error: ${error.toString()}');
      });
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    _saveNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notifications'),
        actions: [
          IconButton(
            onPressed: _saveNotifications,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _notifications.isNotEmpty
                  ? ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(_notifications[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteNotification(index),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('No notifications added')),
            ),
            TextField(
              controller: _textController,
              maxLines: 3, // Allow multiple lines
              decoration: const InputDecoration(
                labelText: 'Enter Notification',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addNotification,
              child: const Text('Add Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
