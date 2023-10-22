import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class LeaderboardPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchLeaderboardData() async {
    final Database db = await openDatabase('path_to_your_database');
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM your_table_name ORDER BY score DESC');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.teal,
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchLeaderboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No data available');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
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
                    title: Text(snapshot.data![index]['name'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${snapshot.data![index]['score']} pts',
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
      ),
    );
  }
}
