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
  BluetoothCharacteristic accXChar;
  BluetoothCharacteristic accYChar;
  BluetoothCharacteristic accZChar;
  BluetoothCharacteristic gyrXChar;
  BluetoothCharacteristic gyrYChar;
  BluetoothCharacteristic gyrZChar;
  var accXCharSub;
  var accYCharSub;
  var accZCharSub;
  var gyrXCharSub;
  var gyrYCharSub;
  var gyrZCharSub;


  var valuesSubscription;

  // Gait sensor data
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
      timeout: const Duration(seconds: 5),
    )
    .listen((scanResult) {
      // print('localName: ${scanResult.advertisementData.localName}');
      // print('manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      // print('serviceData: ${scanResult.advertisementData.serviceData}');
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
    .connect(device, timeout: const Duration(seconds: 10))
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
              accXChar = se.characteristics[0];
              accYChar = se.characteristics[1];
              accZChar = se.characteristics[2];
            } else if (se.uuid.toString().substring(4,8) == "1101") {
              gyrXChar = se.characteristics[0];
              gyrYChar = se.characteristics[1];
              gyrZChar = se.characteristics[2];
            } 
          };

          // ensure all chars registered properly before proceeding, else wait
          if(accXChar != null && accYChar != null && accZChar != null && gyrXChar != null && gyrYChar != null && gyrZChar != null) {
            _setAllNotifyValues();

            //register handlers
            accXCharSub = device.onValueChanged(accXChar).listen((v) { setState(() {gaX = _convertDataToInt(v); }); });
            accYCharSub = device.onValueChanged(accYChar).listen((v) { setState(() {gaY = _convertDataToInt(v); }); });
            accZCharSub = device.onValueChanged(accZChar).listen((v) { setState(() {gaZ = _convertDataToInt(v); }); });
            gyrXCharSub = device.onValueChanged(gyrXChar).listen((v) { setState(() {ggX = _convertDataToInt(v); }); });
            gyrYCharSub = device.onValueChanged(gyrYChar).listen((v) { setState(() {ggY = _convertDataToInt(v); }); });
            gyrZCharSub = device.onValueChanged(gyrZChar).listen((v) { setState(() {ggZ = _convertDataToInt(v); }); });

            setState(() {
              _isLoading = false;
              sensorConnected = true;
            });
          }
          //_printChars();
        });
      }
    });
  }

  int _convertDataToInt(List<int> values) {
    Uint8List buffer = Uint8List.fromList(values);
    var bdata = new ByteData.view(buffer.buffer);
    return bdata.getInt32(0, Endian.little);
  }

  _setAllNotifyValues() async {
    await _setNotifyValue(accXChar, true);
    await _setNotifyValue(accYChar, true);
    await _setNotifyValue(accZChar, true);
    await _setNotifyValue(gyrXChar, true);
    await _setNotifyValue(gyrYChar, true);
    await _setNotifyValue(gyrZChar, true);
  }

  _setNotifyValue(BluetoothCharacteristic c, bool x) async {
    await device.setNotifyValue(c, x);
  }

  _readCharacteristic(BluetoothCharacteristic c) async {
    List<int> values = await device.readCharacteristic(c);
    return _convertDataToInt(values);
  }

  _printChars() async {
    gaX = await _readCharacteristic(accXChar);
    gaY = await _readCharacteristic(accYChar);
    gaZ = await _readCharacteristic(accZChar);
    ggX = await _readCharacteristic(gyrXChar);
    ggY = await _readCharacteristic(gyrYChar);
    ggZ = await _readCharacteristic(gyrZChar);
    setState(() {});
  }

   _disconnect() {
    // Remove all value changed listeners
    _setNotifyValue(accXChar, false);
    _setNotifyValue(accYChar, false);
    _setNotifyValue(accZChar, false);
    _setNotifyValue(gyrXChar, false);
    _setNotifyValue(gyrYChar, false);
    _setNotifyValue(gyrZChar, false);
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
    _setNotifyValue(accXChar, false);
    _setNotifyValue(accYChar, false);
    _setNotifyValue(accZChar, false);
    _setNotifyValue(gyrXChar, false);
    _setNotifyValue(gyrYChar, false);
    _setNotifyValue(gyrZChar, false);
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
      x.isGestureTrained,
      x.isGestureActive,
      x.gestureTrainingDuration,
      x.gestureName,
    )).toList();
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    List<Widget> tiles = new List<Widget>();
    // tiles.add(Text("AX: $gaX, AY: $gaY, AZ: $gaZ, GX: $ggX, GY: $ggY, GZ: $ggZ"));
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
