// filepath: lib/service/global_method.dart

import 'package:flutter/material.dart';

class GlobalMethod {
  static void showErrorDialog({
    required String error,
    required BuildContext ctx,
  }) {
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.logout,
                  color: Colors.grey,
                  size: 35,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Error Occurred'),
              ),
            ],
          ),
          content: Text(
            error,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}