import 'package:flutter/material.dart';

class ExportPage extends StatelessWidget {
  const ExportPage({Key? key}) : super(key: key);

  void _exportData() {
    // Export data functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.teal,
        elevation: 5,
        shadowColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Export Your Data Here',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _exportData,
              child: Text('Export'),
              style: ElevatedButton.styleFrom(
                primary: Colors.teal, // Set button color to teal
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
