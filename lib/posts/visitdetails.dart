import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VisitDetailsScreen extends StatelessWidget {
  final String busName;
  final String routeName;

  const VisitDetailsScreen({super.key, required this.busName, required this.routeName});

  // Function to pick and upload an image
  Future<void> _uploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      try {
        // Create a reference to the Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('Routes/$routeName/$busName/images/${DateTime.now().millisecondsSinceEpoch}.jpg');

        // Upload the image
        await storageRef.putFile(imageFile);

        // Get the download URL
        final downloadUrl = await storageRef.getDownloadURL();

        // Save the image URL to Firebase Database
        DatabaseReference imagesRef = FirebaseDatabase.instance.ref('Routes/$routeName/$busName/images');
        await imagesRef.push().set(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _editVisit(BuildContext context, String visitKey, Map<dynamic, dynamic> visitDetails, bool isReturnVisit) {
    TextEditingController timeController = TextEditingController(text: visitDetails['visitTime']);
    TextEditingController placeController = TextEditingController(text: visitDetails['visitPlace']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${isReturnVisit ? 'Return ' : ''}Visit Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Visit Time')),
            TextField(controller: placeController, decoration: const InputDecoration(labelText: 'Visit Place')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update visit details in Firebase
              visitDetails['visitTime'] = timeController.text;
              visitDetails['visitPlace'] = placeController.text;

              DatabaseReference ref = FirebaseDatabase.instance.ref('Routes/$routeName/$busName/${isReturnVisit ? 'returnVisits' : 'visits'}');
              ref.child(visitKey).set(visitDetails);

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteVisit(BuildContext context, String visitKey, bool isReturnVisit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isReturnVisit ? 'Return ' : ''}Visit'),
        content: Text('Are you sure you want to delete this ${isReturnVisit ? 'return ' : ''}visit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete visit from Firebase
              DatabaseReference ref = FirebaseDatabase.instance.ref('Routes/$routeName/$busName/${isReturnVisit ? 'returnVisits' : 'visits'}');
              ref.child(visitKey).remove();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addVisit(BuildContext context, bool isReturnVisit) {
    TextEditingController timeController = TextEditingController();
    TextEditingController placeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New ${isReturnVisit ? 'Return ' : ''}Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Visit Time')),
            TextField(controller: placeController, decoration: const InputDecoration(labelText: 'Visit Place')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Add new visit to Firebase
              DatabaseReference ref = FirebaseDatabase.instance.ref('Routes/$routeName/$busName/${isReturnVisit ? 'returnVisits' : 'visits'}');
              ref.push().set({
                'visitTime': timeController.text,
                'visitPlace': placeController.text,
              });

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visits for $busName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addVisit(context, false),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addVisit(context, true),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _uploadImage(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('Routes/$routeName/$busName/images').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  var data = snapshot.data!.snapshot.value;
                  List<dynamic> images = data is Map ? data.values.toList() : data as List<dynamic>;

                  return Column(
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: images.map((imageUrl) {
                          return Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        }).toList(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: StreamBuilder(
                                stream: FirebaseDatabase.instance.ref('Routes/$routeName/$busName/visits').onValue,
                                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                                    Map<dynamic, dynamic> visits = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                                    List<Map<String, String>> visitList = visits.entries.map((entry) {
                                      String visitKey = entry.key;
                                      Map<dynamic, dynamic> visitDetails = entry.value;
                                      return {
                                        'visitKey': visitKey,
                                        'visitTime': visitDetails['visitTime'].toString(),
                                        'visitPlace': visitDetails['visitPlace'].toString(),
                                      };
                                    }).toList();

                                    return ListView.builder(
                                      itemCount: visitList.length,
                                      itemBuilder: (context, index) {
                                        var visit = visitList[index];
                                        return ListTile(
                                          title: Text('Place: ${visit['visitPlace']}'),
                                          subtitle: Text('Time: ${visit['visitTime']}'),
                                          onTap: () => _editVisit(context, visit['visitKey'] ?? '', visits[visit['visitKey']], false),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteVisit(context, visit['visitKey'] ?? '', false),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return const Center(child: Text('No visits available.'));
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: StreamBuilder(
                                stream: FirebaseDatabase.instance.ref('Routes/$routeName/$busName/returnVisits').onValue,
                                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                                    Map<dynamic, dynamic> returnVisits = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                                    List<Map<String, String>> returnVisitList = returnVisits.entries.map((entry) {
                                      String visitKey = entry.key;
                                      Map<dynamic, dynamic> visitDetails = entry.value;
                                      return {
                                        'visitKey': visitKey,
                                        'visitTime': visitDetails['visitTime'].toString(),
                                        'visitPlace': visitDetails['visitPlace'].toString(),
                                      };
                                    }).toList();

                                    return ListView.builder(
                                      itemCount: returnVisitList.length,
                                      itemBuilder: (context, index) {
                                        var visit = returnVisitList[index];
                                        return ListTile(
                                          title: Text('Return Place: ${visit['visitPlace']}'),
                                          subtitle: Text('Return Time: ${visit['visitTime']}'),
                                          onTap: () => _editVisit(context, visit['visitKey'] ?? '', returnVisits[visit['visitKey']], true),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteVisit(context, visit['visitKey'] ?? '', true),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return const Center(child: Text('No return visits available.'));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: Text('No images available.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
