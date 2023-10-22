import 'package:flutter/material.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.teal, // Color consistent with the other pages
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Export Your Data Here',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Add export functionality here
          ],
        ),
      ),
    );
  }
}
