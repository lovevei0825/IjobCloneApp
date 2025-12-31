// lib/jobs/jobs_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../user_state.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs Screen'),
        backgroundColor: Colors.cyan,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _auth.signOut();

            // Optional: pop current screen if needed
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            // Redirect to UserState which will show Login screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserState()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}