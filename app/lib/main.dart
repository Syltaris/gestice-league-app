import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

import 'package:app/gestureList.dart';

void main() => runApp(MyApp());

class Gesture {
  final int gestureIndex;
  final bool isGestureTrained;
  final bool isGestureActive;
  final int gestureTrainingDuration;
  final String gestureName;

  Gesture(
    this.gestureIndex, 
    this.isGestureTrained, 
    this.isGestureActive, 
    this.gestureTrainingDuration, 
    this.gestureName
  );

  Gesture.fromJson(Map<String, dynamic> json)
    : gestureIndex = json['gestureIndex'],
      isGestureTrained = json['isGestureTrained'],
      isGestureActive = json['isGestureActive'],
      gestureTrainingDuration = json['gestureTrainingDuration'],
      gestureName = json['gestureName'];

  Map<String, dynamic> toJson() =>
    {
      'gestureIndex' : gestureIndex,
      'isGestureTrained': isGestureTrained,
      'isGestureActive' : isGestureActive,
      'gestureTrainingDuration' : gestureTrainingDuration,
      'gestureName' : gestureName,
    };
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

  BluetoothCharacteristic accChar;
  var accCharSub;
  var valuesSubscription;

  // Gait sensor data
  List<int> sensorData = new List<int>(6);
  List<int> accData = new List<int>(6);
  List<int> gyrData = new List<int>(6);

  // File state
  bool _writeToFile = false;
  int _gestureIndexToWriteTo = 0;

  List<Gesture> _gesturesList;

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

    _loadGesturesFromFile();
  }

  /* 
    Bluetooth connection and data synchronization methods.
  */
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
              if(_writeToFile) { _writeData(_gestureIndexToWriteTo);}

              //setState(() {  });
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
    //print(values);
    for(int i = 0; i < n; i++) {
      Uint8List buffer = Uint8List.fromList(values.sublist(i*2, i*2+2));
      var bdata = new ByteData.view(buffer.buffer);
      output.add(bdata.getInt16(0, Endian.big));
    }
    return output;
  }

  List<int> _convert4ByteDataToIntList(List<int> values, int n) {
    List<int> output = new List<int>();
    //print(values);
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

  /*
    File, data recording methods
  */
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFileForGesture(int index) async {
    final path = await _localPath;
    File output = new File('$path/gesture_data_$index.txt');
    print("writing to ${output.path}");  
    bool fileExists = await output.exists();
    if ( !fileExists ) {
      print('creating file...');
      return await output.create();
    }    
    return output;
  }

  Future<List<Gesture>> _loadGesturesFromFile() async {
    List<Gesture> output = [];
    final path = await _localPath;
    File file = new File('$path/user_data.json');
    bool fileExists = await file.exists();
    if ( !fileExists ) {
      print('creating file...');
      await file.create();
      //create list and write to file
      output = [
        Gesture(0,false, false, 0,'New Superpower'),
        Gesture(1,false, false, 0,'New Superpower'),
        Gesture(2,false, false, 0,'New Superpower'),
        Gesture(3,false, false, 0,'New Superpower'),
        Gesture(4,false, false, 0,'New Superpower'),
      ];
      String initJson = json.encode(output);
    } else {
      //load gestures
      String oldJson = await file.readAsString();
      print(oldJson);
      if(oldJson == null || oldJson.length < 3) { //if file corrupt 
        output = [
          Gesture(0,false, false, 0,'New Superpower'),
          Gesture(1,false, false, 0,'New Superpower'),
          Gesture(2,false, false, 0,'New Superpower'),
          Gesture(3,false, false, 0,'New Superpower'),
          Gesture(4,false, false, 0,'New Superpower'),
        ];
      } else {
        List gestures = json.decode(oldJson);
        for(Object g in gestures) {
          output.add(new Gesture.fromJson(g));
          print(g);
        }
      }
    }
    setState(() {
      _gesturesList = output;
      print('loaded');
      print(_gesturesList);
    });

    return output;
  }

  _saveDataChanges() async {
    String toFile = json.encode(_gesturesList);
    final path = await _localPath;
    File file = new File('$path/user_data.json');
    await file.writeAsString(toFile);
    print('changes saved!');
    print(toFile);
  }

  _writeData(int index) async {
    final file = await _localFileForGesture(index);
    await file.writeAsString("${accData[0]},${accData[1]},${accData[2]},${gyrData[0]},${gyrData[1]},${gyrData[2]},\n", 
    mode: FileMode.append);
    // var sink = file.openWrite(mode: FileMode.append);
    // sink.write('${accData[0]},${accData[1]},${accData[2]},${gyrData[0]},${gyrData[1]},${gyrData[2]},\n');
    // sink.close();
  }

  toggleFileWrite(int index) {
    setState(() {
      _writeToFile = !_writeToFile;
      _gestureIndexToWriteTo = index;
    });
  }

  /*
    Data mutation methods
  */
  // inefficient maybe but simle
  _updateGesture(int index, Gesture newGesture) {
    setState(() {
      _gesturesList[index] = newGesture;
    });
    _saveDataChanges();
  }

  _deleteData() async {
    final path = await _localPath;
    File file = new File('$path/user_data.json');
    return file.delete();
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
    return _gesturesList == null 
    ? [new Text("Something's wrong :/")]
    : _gesturesList.map((x) => GestureItem(
      gestureIndex: x.gestureIndex,
      isGestureTrained: x.isGestureTrained,
      isGestureActive: x.isGestureActive,
      gestureTrainingDuration: x.gestureTrainingDuration,
      gestureName: x.gestureName,
      sensorData: sensorData,
      toggleFileWrite: toggleFileWrite,
      saveDataChanges: _saveDataChanges,
      updateGesture : _updateGesture,
    )).toList();
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    List<Widget> tiles = new List<Widget>();
    //tiles.add(Text("ACC: $accData GYR: $gyrData"));
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
      appBar: sensorConnected 
      ? AppBar( // MyHomePage object in App.build 's title ...?
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.bluetooth_disabled),
              tooltip: 'Disconnect',
              onPressed: _disconnect,
            ),
            IconButton(
              icon: Icon(Icons.clear),
              tooltip: 'Delete Data',
              onPressed: _deleteData,
            ),
          ]
        )
      : null,
      body: 
      Stack(
        children: <Widget>[
          _isLoading ? LinearProgressIndicator() : new Container(),
          sensorConnected 
          ?
          ListView( 
            children: tiles
          )
          :
          Column(
            children: <Widget>[
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain, // otherwise the logo will be tiny
                  child: Image.asset('assets/icon/gl-logo2.png'),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 200.0), //TODO: not the best way to do this
                child: ButtonTheme.bar( // make buttons use the appropriate styles for cards
                  height: 50.0,
                  child: ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.autorenew) ,
                        tooltip: 'Scan for Sensor',
                        color: Colors.lightBlue,
                        disabledColor: Colors.grey,
                        onPressed: state != BluetoothState.on ? null : () => _scanForDevice(),
                      ),
                      RaisedButton.icon(
                        icon: Icon(Icons.bluetooth) ,
                        label: const Text('CONNECT TO SENSOR'),
                        color: Colors.lightBlue,
                        disabledColor: Colors.grey,
                        textColor: Colors.white,
                        onPressed: !deviceFound ? null : () => _establishConnection(),
                      ),
                    ]
                  ),
                ),
              )
            ]
          )
        ]
      )
    );
  }
}
