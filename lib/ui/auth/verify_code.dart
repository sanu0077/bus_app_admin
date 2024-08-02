import 'package:flutter/material.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Column(
        children: [
          // Add your widgets here
        ],
      ),
    );
  }
}
