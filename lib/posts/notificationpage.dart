import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:adm/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('notification');
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _notifications = []; // Store notifications with images

  File? _selectedImage;

  void _addNotification() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _notifications.add({
          'text': _textController.text,
          'image': _selectedImage,
        });
        _textController.clear();
        _selectedImage = null; // Reset image selection
      });
    }
  }

  void _saveNotifications() {
    if (_notifications.isNotEmpty) {
      _ref.set(_notifications.map((notif) {
        return {
          'text': notif['text'],
          'image': notif['image']?.path,
        };
      }).toList()).then((_) {
        Utils().toastMessage(context, 'Notifications saved successfully!');
      }).catchError((error) {
        Utils().toastMessage(context, 'Error: ${error.toString()}');
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
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
                        final notification = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: notification['image'] != null
                                ? Image.file(
                                    notification['image']!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            title: Text(notification['text']),
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}
