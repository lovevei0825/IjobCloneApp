// lib/user_state.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'LoginPage/login_screen.dart';
import 'jobs/jobs_screen.dart';

class UserState extends StatelessWidget {
  const UserState({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('An error has occurred. Try again')),
          );
        }

        if (snapshot.data == null) {
          print('User is not logged in yet');
          return Login();
        } else {
          print('User is already logged in');
          return const JobsScreen();
        }
      },
    );
  }
}