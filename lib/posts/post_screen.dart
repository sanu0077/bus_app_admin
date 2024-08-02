import 'package:adm/posts/busdetail.dart';
import 'package:adm/posts/insert_data_page.dart'; // Import the new page
import 'package:adm/posts/notificationpage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:adm/ui/auth/login_screen.dart';
import 'package:adm/utils/utils.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final auth = FirebaseAuth.instance;
  final ref = FirebaseDatabase.instance.ref('Routes');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              auth.signOut().then((value) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }).catchError((error) {
                Utils().toastMessage(context, error.toString());
              });
            },
            icon: Icon(Icons.logout),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No data available.'));
          } else {
            Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<String> routeNames = map.keys.cast<String>().toList();

            return ListView.builder(
              itemCount: routeNames.length,
              itemBuilder: (context, index) {
                String routeName = routeNames[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusDetailsScreen(
                          routeName: routeName,
                          buses: map[routeName] as Map<dynamic, dynamic>,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      routeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RealTimeDatabase()),
                );
              },
              child: Icon(CupertinoIcons.add),
              heroTag: null,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 96, // Adjust this to position the second button as needed
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()), // Navigate to the new page
                );
              },
              child: Icon(CupertinoIcons.bell),
              heroTag: null,
            ),
          ),
        ],
      ),
    );
  }
}
