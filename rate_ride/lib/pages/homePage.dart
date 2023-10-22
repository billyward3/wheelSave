import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rate_ride/pages/export.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'tripHistory.dart';

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
        scaffoldBackgroundColor: Colors.white,
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

  List<String> tripLogs = [];

  double metersPerSecToMilesPerHour(double speedInMetersPerSec) =>
      speedInMetersPerSec * 2.23694;

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

  StreamController<double> speedStream = StreamController<double>.broadcast();

  void updateSpeed() async {
    while (_isStarted) {
      try {
        AccelerometerEvent accEvent = await accelerometerEvents.first;
        Position? position = await Geolocator.getCurrentPosition();

        if (lastPosition != null) {
          totalDistance += (Geolocator.distanceBetween(
                  lastPosition!.latitude,
                  lastPosition!.longitude,
                  position.latitude,
                  position.longitude) /
              1609.34);
        }
        lastPosition = position;
        speed = metersPerSecToMilesPerHour(position.speed);
        totalSpeed += speed;
        numUpdates++;
        averageSpeed = totalSpeed / numUpdates;

        speedStream.add(speed);
        updateSafetyScore(accEvent, speed, averageSpeed);

        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  StreamController averageSpeedStream = StreamController<double>.broadcast();
  void recordData() async {
    AccelerometerEvent accEvent = await accelerometerEvents.first;
    Position? position = await Geolocator.getCurrentPosition();

    if (lastPosition != null) {
      totalDistance += (Geolocator.distanceBetween(lastPosition!.latitude,
              lastPosition!.longitude, position.latitude, position.longitude) /
          1609.34);
    }
    lastPosition = position;
    speed = metersPerSecToMilesPerHour(position.speed);
    totalSpeed += speed;
    numUpdates++;
    averageSpeed = totalSpeed / numUpdates;
    speedStream.add(speed);
    averageSpeedStream.add(averageSpeed);
    updateSafetyScore(accEvent, speed, averageSpeed);
  }

  void toggleTracking() async {
    if (_isStarted) {
      setState(() {
        _isStarted = false;
        timer?.cancel();
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

          updateSpeed();
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(image: AssetImage('assets/Logo.png')),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'Safety Score',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${safetyScore.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SafetyInfo(
              title: 'Speed',
              value: '${speed.toStringAsFixed(2)} mph',
            ),
            SafetyInfo(
              title: 'Average Speed',
              value: '${averageSpeed.toStringAsFixed(2)} mph',
            ),
            ElevatedButton(
              onPressed: toggleTracking,
              child: Text(_isStarted ? 'STOP' : 'START'),
              style: ElevatedButton.styleFrom(
                primary: _isStarted ? Colors.red : Colors.teal,
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                shadowColor: _isStarted ? Colors.redAccent : Colors.tealAccent,
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: 'Trips'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Export',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TripHistoryPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExportPage(),
              ),
            );
          }
        },
      ),
    );
  }
}
