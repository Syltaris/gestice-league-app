import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

const String SERVER_URL = "http://1bd19bbb.ap.ngrok.io";

class IdleTrainingPage extends StatefulWidget { 
  String title;
  int gestureIndex;
  var toggleFileWrite;
  var setIdleTrained;

  IdleTrainingPage({
    Key key,
    this.title, 
    this.gestureIndex,
    this.toggleFileWrite,
    this.setIdleTrained,
  }) : super(key: key);

  @override
  _IdleTrainingPageState createState() => _IdleTrainingPageState();
}

/*

*/
class _IdleTrainingPageState extends State<IdleTrainingPage> {
  Dio dio = new Dio();

  String fileText = "";
  bool isCounting = false;
  var countingSub;

  bool isTrained = false;
  bool isGestureTraining = false;
  var trainingDuration = 0;

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

    widget.setIdleTrained();
  }
  
  _debugReadFile() async {
    final path = await _localPath;
    String filepath = '$path/gesture_data_${widget.gestureIndex}.txt';
    File file = new File(filepath);
    print(filepath);
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
    if(isCounting && !isTrained) {
      countingSub = Timer.periodic(Duration(seconds: 1), (Timer t) => setState(() {
        trainingDuration = trainingDuration + 30;
        isTrained = trainingDuration >= 30 * 60; //30 frames * 60 seconds 

        if(isTrained && isGestureTraining) {
          widget.toggleFileWrite(widget.gestureIndex);
          setState(() {
            isCounting = false; 
            isGestureTraining = false;
          });
          countingSub?.cancel();
        }
        }) ); //30 frames
    } else {
      countingSub?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    Duration _trainingDuration = Duration(seconds: (trainingDuration / 30).round() );

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Idle Training Mode', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30.0,
            ),
            textAlign: TextAlign.center,
          ),
          Text("Welcome to the Gestice League! \nYour first task is to allow us to learn how you act when you're not doing any action, when you comfortably at rest!\nWhen you're ready, hit train to start!",
            style: TextStyle(
              fontSize: 20.0,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
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
                    icon: Icon(isGestureTraining ? Icons.pause : Icons.play_arrow) ,
                    label: Text(trainingDuration > 0 ? (isGestureTraining ? 'PAUSE TRAINING' : 'RESUME TRAINING') : 'BEGIN TRAINING'),
                    disabledColor: Colors.grey,
                    color: isGestureTraining ? Colors.grey : Colors.green,
                    textColor: Colors.white,
                    onPressed: isTrained && !isGestureTraining ? null : () { //allow user to stop recording when done
                      widget.toggleFileWrite(widget.gestureIndex);
                      setState(() {
                        isCounting = !isCounting; 
                        isGestureTraining = !isGestureTraining;
                      });
                      _internalIncTrainingDur();
                    },
                  )
                ]
              ),
            ),
          ),
          Container(
            child: isGestureTraining 
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
                  label: Text('Upload and Continue'),
                  color: Colors.blue,
                  disabledColor: Colors.grey,
                  textColor: Colors.white,
                  onPressed: isTrained ? () => _uploadFile() : null,
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