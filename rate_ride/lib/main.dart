import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "TripDatabase.db";
  static const _databaseVersion = 1;

  static const tableTrips = 'trips';

  static const columnId = '_id';
  static const columnSafetyScore = 'safetyScore';
  static const columnSpeed = 'speed';
  static const columnAvgSpeed = 'avgSpeed';
  static const columnDistance = 'distance';
  static const columnMaxGs = 'maxGs';
  static const columnMinGs = 'minGs';

  // singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // single database instance
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database or create one if it doesn't exist
  _initDatabase() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableTrips (
            $columnId INTEGER PRIMARY KEY,
            $columnSafetyScore REAL,
            $columnSpeed REAL,
            $columnAvgSpeed REAL,
            $columnDistance REAL,
            $columnMaxGs REAL,
            $columnMinGs REAL
          )
          ''');
  }

  // Database insert operation
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableTrips, row);
  }

  // Database retrieve all operation
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(tableTrips);
  }

  // Database get number of records operation
  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTrips')) as int;
  }
}
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
  double maxGs = 0.0;
  double minGs = 0.0;
  int numUpdates = 0;
  Position? lastPosition;

  // Variables for sensor data.
  AccelerometerEvent? _accelerometerEvent;

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
      if (accEvent.x > 4) {
        double decrement = (0.2 * (accEvent.x - 3).clamp(0, 7));
        // If the total distance is greater than 1 mile (you can adjust this as you see fit)
        // normalize the decrement by dividing it by totalDistance (providing that totalDistance is greater than 1)
        if (totalDistance > 1.0) {
          decrement /= totalDistance;
        }
        
        safetyScore -= decrement;
      }
      if (accEvent.x < 5) {
        double decrement = (0.2 * (accEvent.x - 4).clamp(0, 11));
        // If the total distance is greater than 1 mile (you can adjust this as you see fit)
        // normalize the decrement by dividing it by totalDistance (providing that totalDistance is greater than 1)
        if (totalDistance > 1.0) {
          decrement /= totalDistance;
        }
        
        safetyScore -= decrement;
      }
      safetyScore.clamp(0, 100);
    }
  }

  // Record sensor and position data, and update variables.
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
    if (accEvent.x > maxGs) {
      maxGs = accEvent.x;
    }
    if (accEvent.x < minGs) {
      minGs = accEvent.x;
    }
    averageSpeed = totalSpeed / numUpdates;
    updateSafetyScore(accEvent, speed, averageSpeed);
  }

  // Start or stop tracking.
  void toggleTracking() async {
    if (_isStarted) {
      setState(() {
        _isStarted = false;
        timer?.cancel();
        DatabaseHelper.instance.insert({
        DatabaseHelper.columnSafetyScore: safetyScore,
        DatabaseHelper.columnSpeed: speed,
        DatabaseHelper.columnAvgSpeed: averageSpeed,
        DatabaseHelper.columnDistance: totalDistance,
        DatabaseHelper.columnMaxGs: maxGs,
        DatabaseHelper.columnMinGs: minGs
        });
        tripLogs.add(
            'Safety Score: ${safetyScore.toStringAsFixed(2)}, Speed: ${speed.toStringAsFixed(2)} mph, Average Speed: ${averageSpeed.toStringAsFixed(2)} mph, Total Distance: ${totalDistance.toStringAsFixed(2)} miles');
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
          timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
              Text('Total Distance: ${totalDistance.toStringAsFixed(2)} miles',
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
