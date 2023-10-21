import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GeolocatorService {
  Future<Position?> determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied. Please enable them in settings.');
      }
    } else if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.');
    }
    return await Geolocator.getCurrentPosition();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MyHomePage(title: 'Rate Ride'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Position?>
      _locationData; // Changed to Position? since determinePosition may return null
  Stream<AccelerometerEvent>? _accelerometerStream;
  bool _isStarted = false;
  final GeolocatorService _geolocatorService =
      GeolocatorService(); // Instantiate GeolocatorService

  @override
  void initState() {
    super.initState();
    _accelerometerStream = accelerometerEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _isStarted
                ? StreamBuilder<AccelerometerEvent>(
                    stream: _accelerometerStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          'Accelerometer: ${snapshot.data}',
                          style: TextStyle(color: Colors.white),
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                        );
                      }
                      return const Text('Waiting for accelerometer data...');
                    },
                  )
                : Container(),
            _isStarted
                ? FutureBuilder<Position?>(
                    future: _locationData,
                    builder: (BuildContext context,
                        AsyncSnapshot<Position?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          return Text(
                            'Location Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          );
                        }
                        return Text(
                          'Location: ${snapshot.data}',
                          style: TextStyle(color: Colors.white),
                        );
                      } else {
                        return const Text('Fetching location data...');
                      }
                    },
                  )
                : Container(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  Position? position =
                      await _geolocatorService.determinePosition();
                  setState(() {
                    _isStarted = true;
                    _locationData = Future.value(
                        position); // Convert Position? into a Future<Position?>
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
