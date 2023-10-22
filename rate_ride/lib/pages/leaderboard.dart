import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class LeaderboardPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchLeaderboardData() async {
    // Replace with actual database fetching logic
    // For demonstration, returning dummy data
    return List.generate(
      10,
      (index) => {'name': 'User ${index + 1}', 'score': (1000 - index * 50)},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchLeaderboardData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No trips reported');
        } else {
          final leaderboardData = snapshot.data!;
          return ListView.builder(
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
                    child: Text('${index + 1}',
                        style: TextStyle(color: Colors.white)),
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
          );
        }
      },
    );
  }
}
