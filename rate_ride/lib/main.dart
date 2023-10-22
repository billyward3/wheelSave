import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double score;

  CustomAppBar({required this.score});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Safety score',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          Text(
            '$score',
            style: TextStyle(color: Colors.black, fontSize: 36),
          ),
        ],
      ),
      elevation: 2,
      backgroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(100.0);
}

class SafetyInfo extends StatelessWidget {
  final String title;
  final dynamic value;

  SafetyInfo({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  final bool isStarted;
  final VoidCallback onPressed;

  ControlButton({required this.isStarted, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        isStarted ? 'STOP' : 'START',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        primary: isStarted ? Colors.red : Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
        elevation: 2,
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
  late Future<Position?> _locationData;
  Timer? timer;
  final GeolocatorService _geolocatorService = GeolocatorService();

  double safetyScore = 100.0;
  double totalDistance = 0.0;
  double speed = 0.0;
  double averageSpeed = 0.0;
  double totalSpeed = 0.0;
  int numUpdates = 0;
  Position? lastPosition;

  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;

  bool _isStarted = false;
  List<String> tripLogs = [];

  final StreamController<double> safetyScoreStream = StreamController<double>();

  double metersPerSecToMilesPerHour(double speedInMetersPerSec) =>
      speedInMetersPerSec * 2.23694;

  void updateSafetyScore(
      AccelerometerEvent accEvent, double speed, double averageSpeed) {
    if (speed > 0.5) {
      safetyScore = (safetyScore -
              ((0.3 * (accEvent.x.abs() + accEvent.y.abs() + accEvent.z.abs()) +
                      0.4 * speed +
                      0.3 * averageSpeed) /
                  100))
          .clamp(0.0, 100.0);
      safetyScoreStream.sink.add(safetyScore);
    }
  }

  void recordData() async {
    AccelerometerEvent accEvent = await accelerometerEvents.first;
    Position? position = await Geolocator.getCurrentPosition();
    if (lastPosition != null && position != null) {
      totalDistance += Geolocator.distanceBetween(
        lastPosition!.latitude,
        lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }
    lastPosition = position;
    speed = metersPerSecToMilesPerHour(position?.speed ?? 0);
    totalSpeed += speed;
    numUpdates++;
    averageSpeed = metersPerSecToMilesPerHour(totalSpeed / numUpdates);
    updateSafetyScore(accEvent, speed, averageSpeed);
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
        Position? position = await _geolocatorService.determinePosition();
        setState(() {
          _isStarted = true;
          _locationData = Future.value(position);
          timer = Timer.periodic(Duration(seconds: 1), (timer) async {
            recordData();
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void clearData() {
    setState(() {
      safetyScore = 100.0;
      totalDistance = 0.0;
      speed = 0.0;
      averageSpeed = 0.0;
      totalSpeed = 0.0;
      numUpdates = 0;
      lastPosition = null;
      tripLogs.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((event) {
      _accelerometerEvent = event;
    });
    magnetometerEvents.listen((event) {
      _magnetometerEvent = event;
    });
  }

  @override
  void dispose() {
    safetyScoreStream.close();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(score: safetyScore), // Use the CustomAppBar here
      body: StreamBuilder<double>(
        stream: safetyScoreStream.stream,
        initialData: safetyScore,
        builder: (context, snapshot) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SafetyInfo(
                    title: 'Safety Score',
                    value: snapshot.data?.toStringAsFixed(2) ??
                        "N/A"), // Use the SafetyInfo widget
                SafetyInfo(
                    title: 'Speed',
                    value: speed.toStringAsFixed(2) +
                        ' mph'), // Use the SafetyInfo widget
                SafetyInfo(
                    title: 'Average Speed',
                    value: averageSpeed.toStringAsFixed(2) +
                        ' mph'), // Use the SafetyInfo widget
                ControlButton(
                    isStarted: _isStarted,
                    onPressed: toggleTracking), // Use the ControlButton widget
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.trending_up), label: 'Improve'),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value),
      ),
    );
  }
}
