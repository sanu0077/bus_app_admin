import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'visitdetails.dart';

class BusDetailsScreen extends StatefulWidget {
  final String routeName;
  final Map<dynamic, dynamic> buses;

  BusDetailsScreen({required this.routeName, required this.buses});

  @override
  _BusDetailsScreenState createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  late DatabaseReference _busRef;

  @override
  void initState() {
    super.initState();
    _busRef = FirebaseDatabase.instance.ref('Routes/${widget.routeName}');
  }

  void _editBus(BuildContext context, String busName, Map<dynamic, dynamic> busDetails) {
    TextEditingController nameController = TextEditingController(text: busName);
    TextEditingController timeController = TextEditingController(text: busDetails['busTime']);
    TextEditingController returnTimeController = TextEditingController(text: busDetails['busReturnTime']);
    TextEditingController mobileController = TextEditingController(text: busDetails['busMobileNumber']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Bus Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Bus Name')),
            TextField(controller: timeController, decoration: InputDecoration(labelText: 'Bus Time')),
            TextField(controller: returnTimeController, decoration: InputDecoration(labelText: 'Bus Return Time')),
            TextField(controller: mobileController, decoration: InputDecoration(labelText: 'Mobile Number')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update bus details in Firebase
              String newName = nameController.text;
              busDetails['busTime'] = timeController.text;
              busDetails['busReturnTime'] = returnTimeController.text;
              busDetails['busMobileNumber'] = mobileController.text;

              _busRef.child(busName).remove();
              _busRef.child(newName).set(busDetails);

              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBus(BuildContext context, String busName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bus'),
        content: Text('Are you sure you want to delete this bus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete bus from Firebase
              _busRef.child(busName).remove();
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addBus(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    TextEditingController returnTimeController = TextEditingController();
    TextEditingController mobileController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Bus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Bus Name')),
            TextField(controller: timeController, decoration: InputDecoration(labelText: 'Bus Time')),
            TextField(controller: returnTimeController, decoration: InputDecoration(labelText: 'Bus Return Time')),
            TextField(controller: mobileController, decoration: InputDecoration(labelText: 'Mobile Number')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Add new bus to Firebase
              _busRef.child(nameController.text).set({
                'busTime': timeController.text,
                'busReturnTime': returnTimeController.text,
                'busMobileNumber': mobileController.text,
              });

              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.add),
            onPressed: () => _addBus(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _busRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> buses = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<Map<String, String>> busList = buses.entries.map((entry) {
              String busName = entry.key;
              Map<dynamic, dynamic> busDetails = entry.value;
              return {
                'busName': busName,
                'busTime': busDetails['busTime'].toString(),
                'busReturnTime': busDetails['busReturnTime'].toString(),
                'busMobileNumber': busDetails['busMobileNumber'].toString(),
              };
            }).toList();

            // Sort the list by bus time
            busList.sort((a, b) => a['busTime']!.compareTo(b['busTime']!));

            return ListView.builder(
              itemCount: busList.length,
              itemBuilder: (context, index) {
                var bus = busList[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Icon(CupertinoIcons.bus),
                    title: Text(bus['busName'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time: ${bus['busTime']}'),
                        Text('Return Time: ${bus['busReturnTime']}'), // Display the return time
                        Text('Mobile: ${bus['busMobileNumber']}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitDetailsScreen(
                            busName: bus['busName'] ?? '',
                            routeName: widget.routeName,
                          ),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(CupertinoIcons.pencil_ellipsis_rectangle),
                          onPressed: () => _editBus(context, bus['busName'] ?? '', buses[bus['busName']]!),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.delete),
                          onPressed: () => _deleteBus(context, bus['busName'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No buses available.'));
          }
        },
      ),
    );
  }
}
