import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RealTimeDatabase extends StatefulWidget {
  const RealTimeDatabase({super.key});

  @override
  State<RealTimeDatabase> createState() => _RealTimeDatabaseState();
}

class _RealTimeDatabaseState extends State<RealTimeDatabase> {
  final routeNameController = TextEditingController();
  final busNameController = TextEditingController();
  final busTimeController = TextEditingController();
  final busReturnTimeController = TextEditingController(); // New controller for bus return time
  final busMobileNumberController = TextEditingController();
  final visitTimeController = TextEditingController();
  final visitPlaceController = TextEditingController();
  final returnVisitTimeController = TextEditingController();
  final returnVisitPlaceController = TextEditingController();
  final databaseReference = FirebaseDatabase.instance.ref("Routes");
  final ImagePicker _picker = ImagePicker();
  final List<File> _busImages = [];
  final List<File> _routeImages = [];
  List<Map<String, String>> visits = [];
  List<Map<String, String>> returnVisits = [];

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    routeNameController.dispose();
    busNameController.dispose();
    busTimeController.dispose();
    busReturnTimeController.dispose(); // Dispose the new controller
    busMobileNumberController.dispose();
    visitTimeController.dispose();
    visitPlaceController.dispose();
    returnVisitTimeController.dispose();
    returnVisitPlaceController.dispose();
    super.dispose();
  }

  Future<void> pickBusImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _busImages.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)).toList());
      });
    }
  }

  Future<void> pickRouteImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _routeImages.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)).toList());
      });
    }
  }

  Future<String> uploadImage(File image, String folder) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child(folder).child(fileName);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> addData() async {
    if (routeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the route name"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Create a reference for the specific route
      DatabaseReference routeRef = databaseReference.child(routeNameController.text);

      // Create a reference for the specific bus
      DatabaseReference busRef = routeRef.child(busNameController.text);

      // Upload bus images and get URLs
      List<String> busImageUrls = [];
      for (var image in _busImages) {
        String imageUrl = await uploadImage(image, 'bus_images');
        busImageUrls.add(imageUrl);
      }

      // Upload route images and get URLs
      List<String> routeImageUrls = [];
      for (var image in _routeImages) {
        String imageUrl = await uploadImage(image, 'route_images');
        routeImageUrls.add(imageUrl);
      }

      // Store route images under a separate node
      await FirebaseDatabase.instance.ref('route_images/${routeNameController.text}').set({
        'images': routeImageUrls,
      });

      // Use the unique key to store the bus data
      await busRef.set({
        'busTime': busTimeController.text,
        'busReturnTime': busReturnTimeController.text, // Add the new bus return time field
        'busMobileNumber': busMobileNumberController.text,
        'images': busImageUrls,
      });

      // Add visits to the bus entry
      for (var visit in visits) {
        await busRef.child('visits').push().set(visit);
      }

      // Add return visits to the bus entry
      for (var returnVisit in returnVisits) {
        await busRef.child('returnVisits').push().set(returnVisit);
      }

      // Clear text controllers and images
      routeNameController.clear();
      busNameController.clear();
      busTimeController.clear();
      busReturnTimeController.clear(); // Clear the new controller
      busMobileNumberController.clear();
      _busImages.clear();
      _routeImages.clear();
      visits.clear(); // Clear visits list
      returnVisits.clear(); // Clear return visits list

      // Dismiss the keyboard after adding items
      FocusScope.of(context).unfocus();

      // Optional: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data added successfully"),
        ),
      );
    } catch (e) {
      // Handle errors here, e.g., display an error message
      print('Error adding data: $e');
    }
  }

  void addVisit() {
    if (visitTimeController.text.isEmpty || visitPlaceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter visit time and visit place"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      visits.add({
        'visitTime': visitTimeController.text,
        'visitPlace': visitPlaceController.text,
      });
      visitTimeController.clear();
      visitPlaceController.clear();
    });
  }

  void addReturnVisit() {
    if (returnVisitTimeController.text.isEmpty || returnVisitPlaceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter return visit time and return visit place"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      returnVisits.add({
        'returnVisitTime': returnVisitTimeController.text,
        'returnVisitPlace': returnVisitPlaceController.text,
      });
      returnVisitTimeController.clear();
      returnVisitPlaceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text("Add Bus Route Information"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 25,
            ),
            commonTestField("Route Name", routeNameController, false),
            commonTestField("Bus Name", busNameController, false),
            commonTestField("Bus Time", busTimeController, false),
            commonTestField("Bus Return Time", busReturnTimeController, false), // Add new field in UI
            commonTestField("Bus Mobile Number", busMobileNumberController, false),
            const SizedBox(
              height: 25,
            ),
            ElevatedButton(
              onPressed: pickBusImages,
              child: const Text("Select Bus Images"),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _busImages.map((image) {
                return Stack(
                  children: [
                    Image.file(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _busImages.remove(image);
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: pickRouteImages,
              child: const Text("Select Route Images"),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _routeImages.map((image) {
                return Stack(
                  children: [
                    Image.file(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _routeImages.remove(image);
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            // Visit details section
            commonTestField("Visit Time", visitTimeController, false),
            commonTestField("Visit Place", visitPlaceController, false),
            ElevatedButton(
              onPressed: addVisit,
              child: const Text("Add Visit"),
            ),
            const SizedBox(height: 10),
            // Display added visits
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: visits.map((visit) {
                return Chip(
                  label: Text("${visit['visitTime']} - ${visit['visitPlace']}"),
                  onDeleted: () {
                    setState(() {
                      visits.remove(visit);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            // Return visit details section
            commonTestField("Return Visit Time", returnVisitTimeController, false),
            commonTestField("Return Visit Place", returnVisitPlaceController, false),
            ElevatedButton(
              onPressed: addReturnVisit,
              child: const Text("Add Return Visit"),
            ),
            const SizedBox(height: 10),
            // Display added return visits
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: returnVisits.map((returnVisit) {
                return Chip(
                  label: Text("${returnVisit['returnVisitTime']} - ${returnVisit['returnVisitPlace']}"),
                  onDeleted: () {
                    setState(() {
                      returnVisits.remove(returnVisit);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: addData,
              child: const Text("Add Data"),
            ),
          ],
        ),
      ),
    );
  }

  Widget commonTestField(String hint, TextEditingController controller, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
