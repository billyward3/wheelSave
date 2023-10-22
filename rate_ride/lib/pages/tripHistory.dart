import 'package:flutter/material.dart';

class TripHistoryPage extends StatelessWidget {
  final double totalDistance;
  final int numUpdates;
  final double averageSpeed;
  final double safetyScore;

  TripHistoryPage({
    required this.totalDistance,
    required this.numUpdates,
    required this.averageSpeed,
    required this.safetyScore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.teal,
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Total Distance'),
            subtitle: Text('$totalDistance miles'),
          ),
          ListTile(
            title: Text('Number of Updates'),
            subtitle: Text('$numUpdates'),
          ),
          ListTile(
            title: Text('Average Speed'),
            subtitle: Text('$averageSpeed mph'),
          ),
          ListTile(
            title: Text('Safety Score'),
            subtitle: Text('$safetyScore'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
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
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      'Trip ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Details for Trip ${index + 1}'),
                    tileColor: index % 2 == 0
                        ? Colors.teal.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
