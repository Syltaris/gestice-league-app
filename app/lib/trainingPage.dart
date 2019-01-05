import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


const String SERVER_URL = "http://845ca6c8.ngrok.io";

class TrainingPage extends StatefulWidget { 
  String title;
  int gestureIndex;
  bool isTrained;
  bool isGestureTraining;
  var trainingDuration;
  List<int> sensorData;
  var toggleFileWrite;

  TrainingPage({
    Key key,
    this.title, 
    this.gestureIndex,
    this.isTrained, 
    this.isGestureTraining,
    this.trainingDuration, 
    this.sensorData,
    this.toggleFileWrite,
  }) : super(key: key);

  @override
  _TrainingPageState createState() => _TrainingPageState();
}

/*

*/
class _TrainingPageState extends State<TrainingPage> {
  Dio dio = new Dio();

  String fileText = "";
  bool isCounting = false;
  var countingSub;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  _uploadFile() async {
    final path = await _localPath;
    FormData formData = new FormData.from({
      "file": new UploadFileInfo(new File('$path/gesture_data_${widget.gestureIndex}.txt'), '${widget.gestureIndex}.txt'),
    });
    Response response = await dio.post(SERVER_URL + "/api/upload", data: formData);
    print(response.data.toString());

    // var url = SERVER_URL + "/api/upload";
    // http.post(url, body: {"data": formData})
    //     .then((response) {
    //     print("Response status: ${response.statusCode}");
    //     print("Response body: ${response.body}");
    //   });
  }

  _downloadModel() async {
    
  }
  
  _debugReadFile() async {
    final path = await _localPath;
    File file = new File('$path/gesture_data_${widget.gestureIndex}.txt');
    return file.readAsString();
  }
  
  _readFile() async {
    String out = await _debugReadFile();
    setState(() {
      fileText =  out;
    });
  }

  _deleteFile() async {
    final path = await _localPath;
    File file = new File('$path/gesture_data_${widget.gestureIndex}.txt');
    return file.writeAsString("", mode: FileMode.write); //clear file instead of deleting
    //return file.delete();
  }

  //shouldnt be done this way, should receive updated values fromparent but use this as temp workaround
  _internalIncTrainingDur() {
    if(isCounting) {
      countingSub = Timer.periodic(Duration(seconds: 1), (Timer t) => setState(() {widget.trainingDuration = widget.trainingDuration + 30;}) ); //30 frames
    } else {
      countingSub?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    Duration _trainingDuration = Duration(seconds: (widget.trainingDuration / 30).round() );

    return Scaffold(
      appBar: AppBar( // MyHomePage object in App.build 's title ...?
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Text('TRAINING MODE', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30.0,
            ),
          ),
          Text("You've been training for ${_trainingDuration.inMinutes} mins, ${_trainingDuration.inSeconds % 60} secs!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ), //duration is not getting passed down for some reason, unless child calls parent mutation methods?
          Container(
            child: ButtonTheme.bar( // make buttons use the appropriate styles for cards
              height: 50.0,
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton.icon(
                    icon: Icon(widget.isGestureTraining ? Icons.pause : Icons.play_arrow) ,
                    label: Text(widget.trainingDuration > 0 ? (widget.isGestureTraining ? 'PAUSE TRAINING' : 'RESUME TRAINING') : 'BEGIN TRAINING'),
                    disabledColor: Colors.grey,
                    color: widget.isGestureTraining ? Colors.grey : Colors.green,
                    textColor: Colors.white,
                    onPressed: widget.isTrained && !widget.isGestureTraining ? null : () { //allow user to stop recording when done
                      widget.toggleFileWrite(widget.gestureIndex);
                      setState(() {
                        isCounting = !isCounting; 
                        widget.isGestureTraining = !widget.isGestureTraining;
                      });
                      _internalIncTrainingDur();
                    },
                  )
                ]
              ),
            ),
          ),
          Container(
            child: widget.isGestureTraining 
            ?
            new CircularProgressIndicator()
            :
            new Container()
          ),
          ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton.icon(
                  icon: Icon(Icons.cloud_upload) ,
                  label: Text('Upload'),
                  color: Colors.blue,
                  disabledColor: Colors.grey,
                  textColor: Colors.white,
                  onPressed: () => _uploadFile(),
                ),
                RaisedButton.icon(
                  icon: Icon(Icons.payment) ,
                  label: const Text('POOF'),
                  color: Colors.orange,
                  disabledColor: Colors.grey,
                  textColor: Colors.white,
                  onPressed: () => _readFile(),
                ),
                RaisedButton.icon(
                  icon: Icon(Icons.clear) ,
                  label: Text('EWW'),
                  color: Colors.red,
                  disabledColor: Colors.grey,
                  textColor: Colors.white,
                  onPressed: () => _deleteFile(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                Text(fileText),
              ]
            ),
          ),
        ]
      )
    );
  }
}