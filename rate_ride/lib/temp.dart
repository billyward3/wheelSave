// ... [your previous imports here]

class _MyHomePageState extends State<MyHomePage> {
  late Future<Position> _locationData;
  Stream<AccelerometerEvent>? _accelerometerStream;
  bool _isStarted = false; // Control the display of data

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
            // Display accelerometer data if _isStarted is true
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
                : Container(), // Empty container when not started

            // Fetch and display geolocation data if _isStarted is true
            _isStarted
                ? FutureBuilder<Position>(
                    future: _locationData,
                    builder:
                        (BuildContext context, AsyncSnapshot<Position> snapshot) {
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
                : Container(), // Empty container when not started

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isStarted = true;
                  // Fetch current position when button is pressed
                  _locationData = Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high);
                });
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
