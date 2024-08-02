import 'package:adm/posts/post_screen.dart';
import 'package:adm/ui/auth/login_with_phone_number.dart';
import 'package:adm/ui/auth/signup_screen.dart';
import 'package:adm/utils/utils.dart';
import 'package:adm/widgets/round_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    setState(() {
      loading = true;
    });
    _auth.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    ).then((userCredential) {
      Navigator.push(context,
       MaterialPageRoute(builder: (context) => PostScreen())
       );
       setState(() {
      loading = false;
    });
      Utils().toastMessage(context, 'Login Successful');
    }).catchError((error) {
      // Handle error more gracefully
      String errorMessage;
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        default:
          errorMessage = 'An undefined error occurred.';
      }
      Utils().toastMessage(context, errorMessage);
      setState(() {
      loading = false;
    });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter Email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter Password';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            RoundButton(
              title: 'Log in',
              loading: loading,
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  login();
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.black),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupScreen(),
                      ),
                    );
                  },
                  child: const Text('Sign up'),
                ),
              ],
            ),
            InkWell(
              onTap: (){
                Navigator.push(context, 
                MaterialPageRoute(builder: (context) => LoginWithPhoneNumber()));
              },
              child: Container(
                height: 50,  // Reduced height
                width: double.infinity,  // Ensures it takes full width of parent
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),  // Added margin for spacing
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black,
                  ),
                ),
                child: const Center(
                  child: Text('Log in with phone number'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
