import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'package:app/helpers.dart';
import 'package:app/models/gesture.dart';
import 'package:app/gestureList.dart';
import 'package:app/idleTrainingPage.dart';
import 'package:spotify/spotify_io.dart' as spotify;

const String IFTTT_API_KEY = "cUFyYThzpW_SrXXbddRrb_";
const String SERVER_URL = "http://6ce3b55d.ap.ngrok.io";
const String SOCKET_URL = "ws://6ce3b55d.ap.ngrok.io";
const int SAMPLING_RATE = 60;

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
  Dio dio = new Dio();
  DateTime lastRequestTime = DateTime.now();

  bool _isLoading = false;
  bool _isIdleTrained = false;

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

  BluetoothCharacteristic imuChar;
  var imuCharSub;
  var valuesSubscription;

  // Gait sensor data
  List<int> accData = new List<int>(6);
  List<int> gyrData = new List<int>(6);

  List<List<int>> gestureDataBuffer = [];

  // File state
  bool _writeToFile = false;
  int _gestureIndexToWriteTo = 0;
  var fileSink;

  List<Gesture> _gesturesList;

  //Server sockets
  var serverChannel;

  // Spotify
  bool _isPlaying = false;

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
    .connect(device, timeout: const Duration(seconds: 5))
    .listen((s) {
      if(s == BluetoothDeviceState.connected) {
        setState(() {       
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
              imuChar = se.characteristics[0];
            }
          };

          // ensure all chars registered properly before proceeding, else wait
          if(imuChar != null) { // && gyrChar 
            _setAllNotifyValues(true);
            //register handlers
            imuCharSub = device.onValueChanged(imuChar).listen((v) { 
              accData = convert2ByteDataToIntList(v.sublist(0,6), 3); 
              gyrData = convert4ByteDataToIntList(v.sublist(6,18), 3);
              if(_writeToFile) { 
                _writeData(_gestureIndexToWriteTo);
                _gestureIndexToWriteTo == 0 ? null : _incGestureTrainingDuration(_gestureIndexToWriteTo-1); 
                _gestureIndexToWriteTo == 0 ? null : _checkAndSetGestureTrained(_gestureIndexToWriteTo-1);
              }

              gestureDataBuffer.add([accData[0], accData[1], accData[2], gyrData[0], gyrData[1], gyrData[2]]); //probably better way to do this
              if(gestureDataBuffer.length >= SAMPLING_RATE && _isIdleTrained) {
                bool anyActiveGesture = false;
                for(Gesture g in _gesturesList) {
                  anyActiveGesture = g.isGestureActive || anyActiveGesture;
                  if(anyActiveGesture) {break;}
                }

                if(anyActiveGesture) {
                  _predictForGesture(new List.from(gestureDataBuffer));
                }
                gestureDataBuffer.clear();
              }
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

  _setAllNotifyValues(bool x) async {
    imuChar != null ? await _setNotifyValue(imuChar, x) : null;
  }

  _setNotifyValue(BluetoothCharacteristic c, bool x) async {
    device != null ? await device.setNotifyValue(c, x) : null;
  }

   _disconnect() {
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
    bool fileExists = await output.exists();
    if ( !fileExists ) {
      print('creating file...');
      return await output.create();
    }    
    return output;
  }
  
  Future<bool> _checkIfIdleGestureTrained() async {
    final path = await _localPath;
    File file = new File('$path/gesture_data_0.txt');
    bool fileExists = await file.exists();
    if ( !fileExists ) {
      return false;
    } else {
      String idleFile = await file.readAsString();
      if(idleFile == null || idleFile.length < 100) { //if file corrupt 
        return false;
      }
    }
    return true;
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
        Gesture(1,false, false, 0,'New Superpower 1'),
        Gesture(2,false, false, 0,'New Superpower 2'),
        Gesture(3,false, false, 0,'New Superpower 3'),
        Gesture(4,false, false, 0,'New Superpower 4'),
        Gesture(5,false, false, 0,'New Superpower 5'),
      ];
      String initJson = json.encode(output);
    } else {
      //load gestures
      String oldJson = await file.readAsString();
      print(oldJson);
      if(oldJson == null || oldJson.length < 3) { //if file corrupt 
        output = [
          Gesture(1,false, false, 0,'New Superpower 1'),
          Gesture(2,false, false, 0,'New Superpower 2'),
          Gesture(3,false, false, 0,'New Superpower 3'),
          Gesture(4,false, false, 0,'New Superpower 4'),
          Gesture(5,false, false, 0,'New Superpower 5'),
        ];
      } else {
        _isIdleTrained = await _checkIfIdleGestureTrained();
        List gestures = json.decode(oldJson);
        for(Object g in gestures) {
          output.add(new Gesture.fromJson(g));
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
  }

  _writeData(int index) async {
    if(fileSink == null) {
      final file = await _localFileForGesture(index);
      fileSink = file.openWrite(mode: FileMode.append);
    } else if (_writeToFile) {
      fileSink.write('${accData[0]},${accData[1]},${accData[2]},${gyrData[0]},${gyrData[1]},${gyrData[2]},\n');
    } 
    // await file.writeAsString("${accData[0]},${accData[1]},${accData[2]},${gyrData[0]},${gyrData[1]},${gyrData[2]},\n", 
    // mode: FileMode.append);
    // var sink = file.openWrite(mode: FileMode.append);
    // sink.write('${accData[0]},${accData[1]},${accData[2]},${gyrData[0]},${gyrData[1]},${gyrData[2]},\n');
    // sink.close();
  }

  toggleFileWrite(int index) {
    setState(() {
      _writeToFile = !_writeToFile;
      _gestureIndexToWriteTo = index;
    });

    if(!_writeToFile) {
      fileSink?.close();
      fileSink = null;
    }
  }

  /*
    Data mutation methods
  */
  // inefficient maybe but simple
  _updateGesture(int index, Gesture newGesture) {
    setState(() {
      _gesturesList[index] = newGesture;
    });
    _saveDataChanges();
  }

  _incGestureTrainingDuration(int index) {
    Gesture x = _gesturesList[index];
    _updateGesture(index, new Gesture(
      x.gestureIndex, 
      x.isGestureTrained, 
      x.isGestureActive, 
      x.gestureTrainingDuration+1, 
      x.gestureName,
    )); 
  }

  _checkAndSetGestureTrained(int index) {
    Gesture x = _gesturesList[index];
    print(x.gestureTrainingDuration >= 30 * 60);
    _updateGesture(index, new Gesture(
      x.gestureIndex, 
      x.gestureTrainingDuration >= 30 * 60, //30 frames * 60 seconds 
      x.isGestureActive, 
      x.gestureTrainingDuration, 
      x.gestureName,
    )); 
  }

  _deleteData() async {
    final path = await _localPath;

    File file = new File('$path/gesture_data_0.txt');
    file.writeAsString("", mode: FileMode.write); //clear file instead of deleting

    file = new File('$path/user_data.json');
    return file.writeAsString("", mode: FileMode.write); //clear file instead of deleting
    //return file.delete();  }
  }

  _sendRequest(int index) async {
    // Response response = await dio.post("https://maker.ifttt.com/trigger/gesture_${index}_triggered/with/key/" + IFTTT_API_KEY, data: {"fake": "payload"}); //WARNING: only for test
    // print(response.data.toString());

    var url = "https://maker.ifttt.com/trigger/gesture_${index}_triggered/with/key/" + IFTTT_API_KEY;
    http.post(url)
        .then((response) {
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
    });
  }

  /*
    Gestures
  */
  _checkAndTriggerGestures() {
    for(Gesture g in _gesturesList) {
      if(g.isGestureTrained && g.isGestureActive) {
        //classify each data here and then trigger if true
        if(gyrData[0] + gyrData[1] + gyrData[2] >= 15000 && DateTime.now().isAfter(lastRequestTime.add(new Duration(seconds: 2)))) {
          lastRequestTime = DateTime.now();
          _sendRequest(g.gestureIndex);
        }
      }
    }
  }

  _predictForGesture(var data) async {
    // Response response = await dio.post(SERVER_URL + "/api/predict", data: data);
    // int answer = int.parse(response.data.toString());
    // print(answer);

    if(serverChannel == null) {
      serverChannel = IOWebSocketChannel.connect(SOCKET_URL);
      serverChannel.sink.add({'type':"message", 'data': "msg"});
      serverChannel.stream.listen((msg) {
          print(msg);
          // int answer = msg;
          // if(answer == 0) { return; }

          // var g = _gesturesList[answer - 1];
          // if(g.isGestureTrained && g.isGestureActive) {
          //   if(answer == 2) {
          //     _spotifyLogin();
          //     return;
          //   }
          //   _sendRequest(answer);
          // }
      });
    } else {
      serverChannel = null;
    }

    serverChannel?.sink?.add('from app');
  }

  _spotifyLogin() async {
    // var clientId = "222a1980a2e24d0ea81fbf9fc5609781";
    // var clientSecret = "91360928d53b405783d0d4e1e91586a0"; //WARNING VERY DANGEROUS!!!

    // var credentials = new spotify.SpotifyApiCredentials(clientId, clientSecret);
    // var spotify2 = new spotify.SpotifyApi(credentials);

    // var url = "https://accounts.spotify.com/api/token";
    // http.post(url, 
    // body: {"grant_type": "client_credentials"},
    // headers:  {
    //   HttpHeaders.authorizationHeader: credentials.basicAuth
    // })
    // .then((response) {
    //   print("Response status: ${response.statusCode}");
    //   print("Response body: ${response.body}");
    //});

    var url = "https://api.spotify.com/v1/me/player/play";
    if(_isPlaying) { url = "https://api.spotify.com/v1/me/player/pause"; }
    http.put(url, 
    headers:  {
      "Accept": "application/json",
      "Content-Type": "application/json",
      HttpHeaders.authorizationHeader: "Bearer BQBKHtzOgV5dSdEpeL0flYbfRNCbKUtqjYHG2xkP7ISLahIMmu03VI3GLXCEdigc_TgMbgJSnETwRmkSzbkqwYERv1gQ5RWCix-G3h_iyofy13lVzK5FKVYuHkfF6qkggPlfcv65AhR_rb_K7NHtWcYBTA"
    })
    .then((response) {
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
    });
    _isPlaying = !_isPlaying;
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
    serverChannel?.sink?.close();
    serverChannel = null;
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
      isGestureTraining: _writeToFile,
      gestureTrainingDuration: x.gestureTrainingDuration,
      gestureName: x.gestureName,
      toggleFileWrite: toggleFileWrite,
      saveDataChanges: _saveDataChanges,
      updateGesture : _updateGesture,
    )).toList();
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    List<Widget> tiles = new List<Widget>();
    // tiles.add(
    //   RaisedButton.icon(
    //     icon: Icon(Icons.beach_access) ,
    //     label: const Text('PREDICT'),
    //     color: Colors.lightBlue,
    //     disabledColor: Colors.grey,
    //     textColor: Colors.white,
    //     onPressed: () {
    //       _predictForGesture(new List.from(gestureDataBuffer));
    //       gestureDataBuffer.clear();
    //     },
    //   ),
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
          _isIdleTrained ?
            ListView( 
              children: tiles
            )
            :
            IdleTrainingPage(
              title: 'Idle State',
              gestureIndex: 0, 
              toggleFileWrite: toggleFileWrite,
              setIdleTrained: () => setState(() {_isIdleTrained = true;})
            )
          :
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FittedBox(
                  fit: BoxFit.contain, // otherwise the logo will be tiny
                  child: Image.asset('assets/icon/gl-logo2.png'),
              ),
              Container(
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
                      RaisedButton.icon(
                        icon: Icon(Icons.bluetooth) ,
                        label: const Text('SPOT'),
                        color: Colors.green,
                        disabledColor: Colors.grey,
                        textColor: Colors.white,
                        onPressed: () => _predictForGesture([0]),
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
