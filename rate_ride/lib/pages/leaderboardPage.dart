import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  // For demonstration purposes, using dummy data
  // Replace this with actual data fetched from sqlite DB later
  final List<Map<String, dynamic>> leaderboardData = List.generate(
    10,
    (index) => {'name': 'User ${index + 1}', 'score': (1000 - index * 50)},
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.teal,
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: ListView.builder(
        itemCount: leaderboardData.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            shadowColor: Colors.tealAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child:
                    Text('${index + 1}', style: TextStyle(color: Colors.white)),
              ),
              title: Text(leaderboardData[index]['name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('${leaderboardData[index]['score']} pts',
                  style: TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.bold)),
              tileColor: index % 2 == 0
                  ? Colors.teal.withOpacity(0.1)
                  : Colors.transparent,
            ),
          );
        },
      ),
    );
  }
}
