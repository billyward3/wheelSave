import 'package:flutter/material.dart';

class Trip {
  final String startLocation;
  final String endLocation;
  final double distanceTraveled; // in kilometers
  final double averageSpeed; // in km/h

  Trip(this.startLocation, this.endLocation, this.distanceTraveled,
      this.averageSpeed);
}

class TripHistoryPage extends StatelessWidget {
  // Mock trip data
  final List<Trip> trips = [
    Trip('Los Angeles', 'San Francisco', 600, 85),
    Trip('New York', 'Washington DC', 360, 75),
    Trip('Dallas', 'Austin', 320, 80),
    Trip('Chicago', 'Detroit', 450, 90),
    Trip('Seattle', 'Portland', 280, 70),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.teal,
        elevation: 5,
        shadowColor: Colors.tealAccent,
      ),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _showTripDetails(context, trips[index]);
            },
            child: Card(
              elevation: 2,
              shadowColor: Colors.tealAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text('${index + 1}',
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(
                    '${trips[index].startLocation} to ${trips[index].endLocation}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${trips[index].distanceTraveled} miles at ${trips[index].averageSpeed} mph',),
                tileColor: index % 2 == 0
                    ? Colors.teal.withOpacity(0.1)
                    : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTripDetails(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Trip Details'),
          content: Text(
              'From: ${trip.startLocation}\nTo: ${trip.endLocation}\nDistance: ${trip.distanceTraveled} km\nAverage Speed: ${trip.averageSpeed} km/h'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
