import 'package:flutter/material.dart';

class TripHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.teal, // Color consistent with the other page
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the length of your trip data
        itemBuilder: (context, index) {
          return Card(
            // Wrapping ListTile with Card for a neat UI
            elevation: 2,
            shadowColor: Colors.tealAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                // Adding an icon for a better UI
                backgroundColor: Colors.teal,
                child:
                    Text('${index + 1}', style: TextStyle(color: Colors.white)),
              ),
              title: Text('Trip ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Details for Trip ${index + 1}'),
              tileColor: index % 2 == 0
                  ? Colors.teal.withOpacity(
                      0.1) // Alternating colors for better differentiation
                  : Colors.transparent,
            ),
          );
        },
      ),
    );
  }
}
