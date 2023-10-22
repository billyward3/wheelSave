import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'homePage.dart'; // Import to get the database instance

class TripHistoryPage extends StatelessWidget {
  // Fetch trips from the database
  Future<List<Trip>> fetchTripsFromDatabase() async {
    final Database db = await openDatabase('trip_database.db');
    final List<Map<String, dynamic>> maps = await db.query('trips');

    return List.generate(maps.length, (i) {
      return Trip(
        safetyScore: maps[i]['safetyScore'],
        speed: maps[i]['speed'],
        avgSpeed: maps[i]['avgSpeed'],
        distance: maps[i]['distance'],
        maxGs: maps[i]['maxGs'],
        minGs: maps[i]['minGs'],
        timestamp: maps[i]['timestamp'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.teal,
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: FutureBuilder<List<Trip>>(
        future: fetchTripsFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Trip trip = snapshot.data![index];
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
                    title: Text('Trip ${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Safety Score: ${trip.safetyScore}'),
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
