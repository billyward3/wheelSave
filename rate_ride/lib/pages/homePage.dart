// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'tripHistory.dart';
import 'register.dart';

class Trip {
  final double safetyScore;
  final double speed;
  final double avgSpeed;
  final double distance;
  final double maxGs;
  final double minGs;
  final String timestamp;

  Trip({
    required this.safetyScore,
    required this.speed,
    required this.avgSpeed,
    required this.distance,
    required this.maxGs,
    required this.minGs,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'safetyScore': safetyScore,
      'speed': speed,
      'avgSpeed': avgSpeed,
      'distance': distance,
      'maxGs': maxGs,
      'minGs': minGs,
      'timestamp': timestamp,
    };
  }
}

// CustomAppBar now has the Sign Out button at the top and lowers the safety score
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double score;
  const CustomAppBar(
      {super.key, required this.score, required BuildContext context});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        // Add leading IconButton to fix invisible hamburger icon
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      centerTitle: true,
      elevation: 2,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout,
              color: Colors.black), // Update icon color
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100.0);
}

class SafetyInfo extends StatelessWidget {
  final String title;
  final dynamic value;

  const SafetyInfo({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  final bool isStarted;
  final VoidCallback onPressed;

  const ControlButton(
      {super.key, required this.isStarted, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isStarted ? Colors.red : Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
        elevation: 2,
      ),
      child: Text(
        isStarted ? 'STOP' : 'START',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

class GeolocatorService {
  Future<Position?> determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied. Enable them in settings.');
      }
    }
    return await Geolocator.getCurrentPosition();
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Change background to white
      ),
      home: const MyHomePage(title: 'Rate Ride'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? timer;
  bool _isStarted = false;
  double safetyScore = 100.0;
  double totalDistance = 0.0;
  double speed = 0.0;
  double averageSpeed = 0.0;
  double totalSpeed = 0.0;
  int numUpdates = 0;
  Position? lastPosition;
  StreamController<double> safetyScoreStream =
      StreamController<double>.broadcast();

  // Convert speed to mph.
  double metersPerSecToMilesPerHour(double speedInMetersPerSec) =>
      speedInMetersPerSec * 2.23694;

  // Calculate and update safety score.
  void updateSafetyScore(
      AccelerometerEvent accEvent, double speed, double averageSpeed) {
    if (speed > 0.5) {
      if (accEvent.x > 4) {
        safetyScore -= (0.2 * (accEvent.x - 3).clamp(0, 5));
      }
      if (accEvent.x < 5) {
        safetyScore -= (0.3 * (accEvent.x - 4).clamp(0, 5));
      }
      safetyScore.clamp(0, 100);
    }
  }

  void recordData() async {
    AccelerometerEvent accEvent = await accelerometerEvents.first;
    Position? position = await Geolocator.getCurrentPosition();

    if (lastPosition != null) {
      // converted from meters to miles
      totalDistance += (Geolocator.distanceBetween(lastPosition!.latitude,
              lastPosition!.longitude, position.latitude, position.longitude) /
          1609.34);
    }
    lastPosition = position;
    speed = metersPerSecToMilesPerHour(position.speed);
    totalSpeed += speed;
    numUpdates++;
    averageSpeed = totalSpeed / numUpdates;
    updateSafetyScore(accEvent, speed, averageSpeed);
  }

  Future<void> saveTripToDatabase() async {
    final trip = Trip(
      safetyScore: safetyScore,
      speed: speed,
      avgSpeed: averageSpeed,
      distance: totalDistance,
      maxGs: 0.0, // Replace with actual value
      minGs: 0.0, // Replace with actual value
      timestamp: DateTime.now().toIso8601String(),
    );

    // SQLite database write operation
    final Database db = await openDatabase('trip_database.db');
    await db.insert('trips', trip.toMap());
  }

  void toggleTracking() async {
    if (_isStarted) {
      setState(() {
        _isStarted = false;
        timer?.cancel();
        saveTripToDatabase();
        safetyScoreStream.close();
        totalDistance = 0.0;
        speed = 0.0;
        averageSpeed = 0.0;
        totalSpeed = 0.0;
        totalDistance = 0.0;
        numUpdates = 0;
      });
    } else {
      try {
        setState(() {
          _isStarted = true;
          timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
            recordData();
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    safetyScoreStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(score: safetyScore, context: context),
      drawer: const Drawer(
          // Unchanged
          ),
      body: StreamBuilder<double>(
        stream: safetyScoreStream.stream,
        initialData: safetyScore,
        builder: (context, snapshot) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Safety Score',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${snapshot.data?.toStringAsFixed(2)}',
                    style:
                        TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                SafetyInfo(
                    title: 'Speed', value: '${speed.toStringAsFixed(2)} mph'),
                SafetyInfo(
                    title: 'Average Speed',
                    value: '${averageSpeed.toStringAsFixed(2)} mph'),
                ElevatedButton(
                  onPressed: toggleTracking,
                  child: Text(_isStarted ? 'STOP' : 'START'),
                  style: ElevatedButton.styleFrom(
                    primary: _isStarted
                        ? Colors.red
                        : Colors.teal, // Conditional color change
                    onPrimary: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    shadowColor: _isStarted
                        ? Colors.redAccent
                        : Colors.tealAccent, // Conditional shadow color change
                    elevation: 5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_up), label: 'Leaderboard'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TripHistoryPage()),
            );
          }
        },
      ),
    );
  }
}
