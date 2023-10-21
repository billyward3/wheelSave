// Required Flutter import
import 'package:flutter/material.dart';

// Main entry point for the Flutter app
void main() {
  runApp(const MyApp());
}

// Represents the overall Flutter application structure
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Builds and returns the main app layout
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

// Represents the main screen or home page of the app
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  // Creates the mutable state for this widget
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Contains the mutable state and UI logic for the MyHomePage widget
class _MyHomePageState extends State<MyHomePage> {
  // The main layout builder for MyHomePage
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
            // Displays placeholder text for accelerometer data
            const Text(
              'Accelerometer Data Goes Here',
              style: TextStyle(color: Colors.white),
            ),
            // Displays placeholder text for real-time location data
            const Text(
              'Real-Time Location Data Goes Here',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            // A button which will be used to start data collection (to be implemented)
            ElevatedButton(
              onPressed: () {
                // Placeholder for logic to start accelerometer and location data collection
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
      // No floating action button, as the counter functionality has been removed
    );
  }
}
