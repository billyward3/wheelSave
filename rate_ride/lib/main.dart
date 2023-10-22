import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Service to handle Geolocator permissions and position.
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
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const MyHomePage(title: 'Rate Ride'),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Variables for tracking.
  late Future<Position?> _locationData;
  Timer? timer;
  final GeolocatorService _geolocatorService = GeolocatorService();

  // Variables for calculating safety score and speed.
  double safetyScore = 100.0;
  double totalDistance = 0.0;
  double speed = 0.0;
  double averageSpeed = 0.0;
  double totalSpeed = 0.0;
  int numUpdates = 0;
  Position? lastPosition;

  // Variables for sensor data.
  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;

  // Variables for logs and state.
  bool _isStarted = false;
  List<String> tripLogs = [];

  // Convert speed to mph.
  double metersPerSecToMilesPerHour(double speedInMetersPerSec) =>
      speedInMetersPerSec * 2.23694;

  // Calculate and update safety score.
  void updateSafetyScore(
      AccelerometerEvent accEvent, double speed, double averageSpeed) {
    if (speed > 0.5) {
      safetyScore = (safetyScore -
              ((0.3 * (accEvent.x.abs() + accEvent.y.abs() + accEvent.z.abs()) +
                      0.4 * speed +
                      0.3 * averageSpeed) /
                  100))
          .clamp(0.0, 100.0);
    }
  }

  // Record sensor and position data, and update variables.
  void recordData() async {
    AccelerometerEvent accEvent = await accelerometerEvents.first;
    Position? position = await Geolocator.getCurrentPosition();

    if (lastPosition != null && position != null) {
      totalDistance += Geolocator.distanceBetween(lastPosition!.latitude,
          lastPosition!.longitude, position.latitude, position.longitude);
    }
    lastPosition = position;
    speed = metersPerSecToMilesPerHour(position?.speed ?? 0);
    totalSpeed += speed;
    numUpdates++;
    averageSpeed = metersPerSecToMilesPerHour(totalSpeed / numUpdates);
    updateSafetyScore(accEvent, speed, averageSpeed);
  }

  // Start or stop tracking.
  void toggleTracking() async {
    if (_isStarted) {
      setState(() {
        _isStarted = false;
        timer?.cancel();
        tripLogs.add(
            'Safety Score: ${safetyScore.toStringAsFixed(2)}, Speed: ${speed.toStringAsFixed(2)} mph, Average Speed: ${averageSpeed.toStringAsFixed(2)} mph, Total Distance: ${totalDistance.toStringAsFixed(2)} meters');
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
            setState(() {});
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Clear the recorded data.
  void clearData() => setState(() {
        safetyScore = 100.0;
        totalDistance = 0.0;
        speed = 0.0;
        averageSpeed = 0.0;
        totalSpeed = 0.0;
        numUpdates = 0;
        lastPosition = null;
        tripLogs.clear();
      });

  @override
  void initState() {
    super.initState();
    accelerometerEvents
        .listen((event) => setState(() => _accelerometerEvent = event));
    magnetometerEvents
        .listen((event) => setState(() => _magnetometerEvent = event));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            ElevatedButton(onPressed: clearData, child: Text("Clear Data"))
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Safety Score: ${safetyScore.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white)),
              Text('Speed: ${speed.toStringAsFixed(2)} mph',
                  style: TextStyle(color: Colors.white)),
              Text('Average Speed: ${averageSpeed.toStringAsFixed(2)} mph',
                  style: TextStyle(color: Colors.white)),
              Text(
                  'Accelerometer Data: x: ${_accelerometerEvent?.x ?? 0}, y: ${_accelerometerEvent?.y ?? 0}, z: ${_accelerometerEvent?.z ?? 0}',
                  style: TextStyle(color: Colors.white)),
              Text(
                  'Magnetometer Data: x: ${_magnetometerEvent?.x ?? 0}, y: ${_magnetometerEvent?.y ?? 0}, z: ${_magnetometerEvent?.z ?? 0}',
                  style: TextStyle(color: Colors.white)),
              Text('Total Distance: ${totalDistance.toStringAsFixed(2)} meters',
                  style: TextStyle(color: Colors.white)),
              ElevatedButton(
                  onPressed: toggleTracking,
                  child: Text(_isStarted ? 'Stop' : 'Start')),
              ...tripLogs.map(
                  (log) => Text(log, style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
}
