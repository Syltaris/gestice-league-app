import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:app/gestureList.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {   // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestice League',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: HomePage(title: 'Superpowers'),
    );
  }
}

class HomePage extends StatefulWidget { 
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/*
  Needs to take in a list of mini widgets, each representing a gesture.
  Gesture list to map!
*/
class _MyHomePageState extends State<HomePage> {
  FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Scanning
  var _scanSubscription;
  Map<DeviceIdentifier, ScanResult> scanResults = new Map();
  bool isScanning = false;

  /// State
  var _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  /// Device
  BluetoothDevice device;
  bool deviceFound = false;
  bool get isConnected => (device != null);
  var deviceConnection;
  var deviceStateSubscription;
  List<BluetoothService> services = new List();
  //Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  void _scanForDeviceAndConnect() {
    _scanSubscription = _flutterBlue
    .scan(
      timeout: const Duration(seconds: 5),
      /*withServices: [
          new Guid('0000180F-0000-1000-8000-00805F9B34FB')
        ]*/
    )
    .listen((scanResult) {
      print('localName: ${scanResult.advertisementData.localName}');
      print('manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      print('serviceData: ${scanResult.advertisementData.serviceData}');

      bool sensorFound = (scanResult.advertisementData.localName == "GaitSensor1");

      setState(() {
        scanResults[scanResult.device.id] = scanResult;
        deviceFound = sensorFound;
      });
    }, onDone: _stopScan);

  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  void initState() {
    super.initState();
    // Immediately get the state of FlutterBlue
    _flutterBlue.state.then((s) {
      setState(() {
        state = s;
      });
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      setState(() {
        state = s;
      });
    });
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    return Scaffold(
      appBar: AppBar( // MyHomePage object in App.build 's title ...?
        title: Text(widget.title),
      ),
      body: Center( 
        child: isConnected 
        ? ListView( //list of children vertically, fills parent, 
          //mainAxisAlignment: MainAxisAlignment.center, //mainAxis here is vertical axis, cross is hori
            children: <Widget>[
              GestureItem( 
                false,
                false,
                5,
                "Telekineseis"
              ),
              GestureItem( 
                true,
                true,
                15,
                "Woohoo!"
              ),
              GestureItem( 
                false,
                false,
                0,
                "New Superpower"
              ),
              GestureItem( 
                false,
                false,
                0,
                "New Superpower"
              ),
            ],
          )
        : Center(
            child:ButtonTheme.bar( // make buttons use the appropriate styles for cards
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton.icon(
                    icon: Icon(Icons.bluetooth) ,
                    label: const Text('CONNECT TO DEVICE'),
                    color: Colors.lightBlue,
                    disabledColor: Colors.grey,
                    textColor: Colors.white,
                    onPressed: !deviceFound ? null : () => {},
                  ),
                  RaisedButton.icon(
                    icon: Icon(Icons.autorenew) ,
                    label: const Text(''),
                    color: Colors.lightBlue,
                    disabledColor: Colors.grey,
                    textColor: Colors.white,
                    onPressed: state != BluetoothState.on ? null : () => _scanForDeviceAndConnect(),
                  ),
                ]
              ),
            ),
          ),
      ),
    );
  }
}
