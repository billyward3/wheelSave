// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'tripHistory.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double score;
  const CustomAppBar({super.key, required this.score, required BuildContext context});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            'Safety score',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          Text(
            '$score',
            style: const TextStyle(color: Colors.black, fontSize: 36),
          ),
        ],
      ),
      elevation: 2,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignOutPage()),
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

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Out')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Are you sure you want to sign out?'),
            ElevatedButton(
              onPressed: () {
                // Handle sign out logic here
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
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

  List<String> tripLogs = [];

  void updateSafetyMetrics(Position? currentPosition) {
    if (lastPosition != null && currentPosition != null) {
      totalDistance += Geolocator.distanceBetween(
        lastPosition!.latitude,
        lastPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
      speed = currentPosition.speed * 2.23694;
      totalSpeed += speed;
      numUpdates++;
      averageSpeed = totalSpeed / numUpdates;
      safetyScore -= 0.1;
    }
    lastPosition = currentPosition;
    safetyScoreStream.sink.add(safetyScore);
  }

  void recordData() async {
    Position? position = await Geolocator.getCurrentPosition();
    updateSafetyMetrics(position);
  }

  void toggleTracking() async {
    if (_isStarted) {
      setState(() {
        _isStarted = false;
        timer?.cancel();
        tripLogs.add(
          'Safety Score: ${safetyScore.toStringAsFixed(2)}, Speed: ${speed.toStringAsFixed(2)} mph, Average Speed: ${averageSpeed.toStringAsFixed(2)} mph, Total Distance: ${totalDistance.toStringAsFixed(2)} meters',
        );
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
  void initState() {
    super.initState();
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
                SafetyInfo(
                    title: 'Speed', value: '${speed.toStringAsFixed(2)} mph'),
                SafetyInfo(
                    title: 'Average Speed',
                    value: '${averageSpeed.toStringAsFixed(2)} mph'),
                ControlButton(isStarted: _isStarted, onPressed: toggleTracking),
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
              icon: Icon(Icons.trending_up), label: 'Improve'),
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
