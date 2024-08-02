import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:adm/utils/utils.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('notification');
  final TextEditingController _textController = TextEditingController();
  final List<String> _notifications = [];

  void _addNotification() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _notifications.add(_textController.text);
        _textController.clear();
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Notifications'),
        actions: [
          IconButton(
            onPressed: _saveNotifications,
            icon: Icon(Icons.save),
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
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(_notifications[index]),
                          ),
                        );
                      },
                    )
                  : Center(child: Text('No notifications added')),
            ),
            TextField(
              controller: _textController,
              maxLines: 3, // Allow multiple lines
              decoration: InputDecoration(
                labelText: 'Enter Notification',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addNotification,
              child: Text('Add Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
