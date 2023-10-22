// ignore_for_file: file_names, use_key_in_widget_constructors

import 'package:flutter/material.dart';

class TripHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: ListView.builder(
        itemCount: 10, // Replace with the length of your trip data
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Trip $index'),
            subtitle: Text('Details for Trip $index'),
          );
        },
      ),
    );
  }
}
