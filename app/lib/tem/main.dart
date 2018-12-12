import 'dart:async';
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
  bool sensorConnected = false;
  DeviceIdentifier gaitSensorId;
  bool get isConnected => (device != null);
  var deviceConnection;
  var deviceStateSubscription;
  List<BluetoothService> services = new List();
  List<BluetoothCharacteristic> characs = new List();
  //Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  var valuesSubscription;

  // Gait sensor data
  var gaX = 0;
  var gaY = 0;
  var gaZ = 0;
  var ggX = 0;
  var ggY = 0;
  var ggZ = 0;

  void _scanForDevice() {
    _scanSubscription = _flutterBlue
    .scan(
      timeout: const Duration(seconds: 5),
      /*withServices: [
          new Guid('0000180F-0000-1000-8000-00805F9B34FB')
        ]*/
    )
    .listen((scanResult) {
      // print('localName: ${scanResult.advertisementData.localName}');
      // print('manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      // print('serviceData: ${scanResult.advertisementData.serviceData}');

      bool sensorFound = (scanResult.advertisementData.localName == "GaitSensor1");
      DeviceIdentifier id = scanResult.device.id;
      setState(() {
        scanResults[id] = scanResult;
        deviceFound = deviceFound || sensorFound;
        gaitSensorId = sensorFound ? id : gaitSensorId;
        if(sensorFound) {
          device = scanResult.device;
          print('Found!');
        }
      });
    }, onDone: _stopScan);

  }

  void _establishConnection() async {
    // Connect to device
    deviceConnection = _flutterBlue
    .connect(device, timeout: const Duration(seconds: 10))
    .listen(
      null,
      onDone: _disconnect,
    );

    // Update the connection state immediately
    device.state.then((s) {
      setState(() {
        deviceState = s;
      });
    });

    // Subscribe to connection changes
    deviceStateSubscription = device.onStateChanged().listen((s) {
        setState(() {
          deviceState = s;
        });
        if (s == BluetoothDeviceState.connected) {
          device.discoverServices().then((s) {
            setState(() {
              characs = s[0].characteristics;

              sensorConnected = true;
            });

            _printChars(s);
          });
      }
    });
  }

  _printChars(var services) async {
    var characteristics = services[0].characteristics;
    for(BluetoothCharacteristic c in characteristics) {
        List<int> value = await device.readCharacteristic(c);
        print(value);
    }
    print('should have liao');

    characteristics = services[1].characteristics;
    for(BluetoothCharacteristic c in characteristics) {
        List<int> value = await device.readCharacteristic(c);
        print(value);
    }
    print('should have leh');
  }

  _readCharacteristic(BluetoothCharacteristic c) async {
    await device.readCharacteristic(c);
    setState(() {});
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

   _disconnect() {
    // Remove all value changed listeners
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    valuesSubscription?.cancel();
    valuesSubscription = null;
    setState(() {
      device = null;
    });
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
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    valuesSubscription?.cancel();
    valuesSubscription = null;
    super.dispose();
    setState(() {
      device = null;
      sensorConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    var temp = characs != null && sensorConnected ? characs[0].uuid : 'neh';
    return Scaffold(
      appBar: AppBar( // MyHomePage object in App.build 's title ...?
        title: Text(widget.title),
      ),
      body: Center( 
        child: sensorConnected 
        ? ListView( //list of children vertically, fills parent, 
          //mainAxisAlignment: MainAxisAlignment.center, //mainAxis here is vertical axis, cross is hori
            children: <Widget>[
              characs != null ? Text("$temp") : Text("nullh"),
              Text("AX: $gaX, AY: $gaY, AZ: $gaZ, GX: $ggX, GY: $ggY, GZ: $ggZ"),
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
                    onPressed: !deviceFound ? null : () => _establishConnection(),
                  ),
                  RaisedButton.icon(
                    icon: Icon(Icons.autorenew) ,
                    label: const Text(''),
                    color: Colors.lightBlue,
                    disabledColor: Colors.grey,
                    textColor: Colors.white,
                    onPressed: state != BluetoothState.on ? null : () => _scanForDevice(),
                  ),
                ]
              ),
            ),
          ),
        ),
    );
  }
}
