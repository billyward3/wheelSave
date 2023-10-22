import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.teal, // Color consistent with the other pages
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the length of your leaderboard data
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
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                'User ${index + 1}', // Replace with user names or data
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Score: ${100 - index}', // Replace with user scores or data
              ),
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
