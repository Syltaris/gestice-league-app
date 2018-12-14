import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:app/gestureList.dart';


void main() => runApp(MyApp());

class Gesture {
  final bool isGestureTrained;
  final bool isGestureActive;
  final int gestureTrainingDuration;
  final String gestureName;

  Gesture(this.isGestureTrained, this.isGestureActive, this.gestureTrainingDuration, this.gestureName);
}

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
  bool _isLoading = false;

  FlutterBlue _flutterBlue = FlutterBlue.instance;

  var _scanSubscription;
  var _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  /// Device
  BluetoothDevice device;
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  bool deviceFound = false;
  bool sensorConnected = false;
  bool get isConnected => (device != null);
  var deviceConnection;
  var deviceStateSubscription;
  List<BluetoothService> services = new List();

  // BluetoothCharacteristics PUT INTO LISTS
  BluetoothCharacteristic accChar;
  var accCharSub;
  var valuesSubscription;

  // Gait sensor data
  List<int> sensorData = new List<int>(6);
  List<int> accData = new List<int>(6);
  List<int> gyrData = new List<int>(6);

  var gaX = 0; var gaY = 0; var gaZ = 0; var ggX = 0; var ggY = 0; var ggZ = 0;

  List<Gesture> _gesturesList = <Gesture>[
    Gesture( 
      false,
      false,
      5,
      "Telekineseis"
    ),
    Gesture( 
      true,
      true,
      15,
      "Woohoo!"
    ),
    Gesture( 
      false,
      false,
      0,
      "New Superpower"
    ),
    Gesture( 
      false,
      false,
      0,
      "New Superpower"
    )
  ];

  void _scanForDevice() {
    _scanSubscription = _flutterBlue
    .scan(
      timeout: const Duration(seconds: 3),
    )
    .listen((scanResult) {
      bool sensorFound = (scanResult.advertisementData.localName == "GaitSensor1");
      DeviceIdentifier id = scanResult.device.id;
      setState(() {
        deviceFound = deviceFound || sensorFound;
        if(sensorFound) {
          device = scanResult.device;
          print('Found!');
        }
      });
    }, 
    );
  }

  void _establishConnection() async {
    // Connect to device
    deviceConnection = _flutterBlue
    .connect(device, timeout: const Duration(seconds: 3))
    .listen((s) {
      if(s == BluetoothDeviceState.connected) {
        setState(() {       
          //sensorConnected = true;
          _isLoading = true;
        });
      }
    },
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
        device.discoverServices().then((services) {
          for(BluetoothService se in services) {
            if(se == null) {continue;}
            if(se.uuid.toString().substring(4, 8) == "0010") { //WARNING: perform the checks here pls, for each char 
              accChar = se.characteristics[0];
            }
          };

          // ensure all chars registered properly before proceeding, else wait
          if(accChar != null) { // && gyrChar 
            _setAllNotifyValues(true);
            //register handlers
            accCharSub = device.onValueChanged(accChar).listen((v) { 
              accData = _convert2ByteDataToIntList(v.sublist(0,6), 3); 
              gyrData = _convert4ByteDataToIntList(v.sublist(6,18), 3);
              setState(() {  });
            });
            setState(() {
              _isLoading = false;
              sensorConnected = true;
            });
          }
        });
      }
    });
  }

  int _convertDataToInt(List<int> values) {
    Uint8List buffer = Uint8List.fromList(values);
    var bdata = new ByteData.view(buffer.buffer);
    return bdata.getInt32(0, Endian.little);
  }

  List<int> _convert2ByteDataToIntList(List<int> values, int n) {
    List<int> output = new List<int>();
    print(values);
    for(int i = 0; i < n; i++) {
      Uint8List buffer = Uint8List.fromList(values.sublist(i*2, i*2+2));
      var bdata = new ByteData.view(buffer.buffer);
      output.add(bdata.getInt16(0, Endian.big));
    }
    return output;
  }

  List<int> _convert4ByteDataToIntList(List<int> values, int n) {
    List<int> output = new List<int>();
    print(values);
    for(int i = 0; i < n; i++) {
      Uint8List buffer = Uint8List.fromList(values.sublist(i*4, i*4+4));
      var bdata = new ByteData.view(buffer.buffer);
      output.add(bdata.getInt32(0, Endian.big));
    }
    return output;
  }

  _setAllNotifyValues(bool x) async {
    accChar != null ? await _setNotifyValue(accChar, x) : null;
    //gyrChar != null ? await _setNotifyValue(gyrChar, x) : null;
  }

  _setNotifyValue(BluetoothCharacteristic c, bool x) async {
    device != null ? await device.setNotifyValue(c, x) : null;
  }

  // _readCharacteristic(BluetoothCharacteristic c) async {
  //   List<int> values = await device.readCharacteristic(c);
  //   return _convertDataToIntList(values);
  // }

   _disconnect() {
    // Remove all value changed listeners
    _setAllNotifyValues(false);
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    valuesSubscription?.cancel();
    valuesSubscription = null;

    setState(() {
      device = null;
      sensorConnected = false;
      deviceFound = false;
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
    _setAllNotifyValues(false);
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    valuesSubscription?.cancel();
    valuesSubscription = null;
    super.dispose();
    setState(() {
      device = null;
      sensorConnected = false;
      deviceFound = false;
    });
  }

  _buildGesturesList() {
    return _gesturesList.map((x) => GestureItem(
      isGestureTrained: x.isGestureTrained,
      isGestureActive: x.isGestureActive,
      gestureTrainingDuration: x.gestureTrainingDuration,
      gestureName: x.gestureName,
      sensorData: sensorData //hate this way to pass down IMU data, super hacky
    )).toList();
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    List<Widget> tiles = new List<Widget>();
    tiles.add(Text("ACC: $accData GYR: $gyrData"));
    // tiles.add(
    //   RaisedButton.icon(
    //     icon: Icon(Icons.add) ,
    //     label: const Text('CHECK'),
    //     color: Colors.lightBlue,
    //     disabledColor: Colors.grey,
    //     textColor: Colors.white,
    //     onPressed: !deviceFound ? null : () => _printChars(),
    //   )
    // );
    tiles.addAll(_buildGesturesList());

    return Scaffold(
      appBar: AppBar( // MyHomePage object in App.build 's title ...?
        title: Text(widget.title),
        actions: <Widget>[
           IconButton(
            icon: Icon(Icons.bluetooth_disabled),
            tooltip: 'Disconnect',
            onPressed: _disconnect,
          ),
        ]
      ),
      body: Stack(
        children: <Widget>[
          _isLoading ? LinearProgressIndicator() : new Container(),
          Center(
            child: sensorConnected 
            ? ListView( //list of children vertically, fills parent, 
              //mainAxisAlignment: MainAxisAlignment.center, //mainAxis here is vertical axis, cross is hori
                children: tiles
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
        ]
      ),
    );
  }
}
