import 'package:flutter/material.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';


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

  String fileText = "";

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
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
    return file.delete();
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    int _trainingDuration = widget.trainingDuration;
    var sensorData = widget.sensorData;

    var gaX = widget.sensorData[0];
    var gaY = widget.sensorData[1];
    var gaZ = widget.sensorData[2];
    var ggX = widget.sensorData[3];
    var ggY = widget.sensorData[4];
    var ggZ = widget.sensorData[5];

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
          Text("${widget.trainingDuration}"), //duration is not getting passed down for some reason, unless child calls parent mutation methods?
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
                    textColor: Colors.white,
                    onPressed: widget.isTrained ? null : () => widget.toggleFileWrite(widget.gestureIndex),
                  )
                ]
              ),
            ),
          ),
          ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
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
                  color: Colors.green,
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
        // child: Column(
        //   mainAxisAlignment: MainAxisAlignment.center, //mainAxis here is vertical axis, cross is hori
        //   children: <Widget>[
        //     Expanded(
        //       child: Padding(
        //         padding: EdgeInsets.all(50.0),
        //         child: widget.isTrained 
        //         ? Text('You have already trained this superpower!',
        //             style: TextStyle(
        //               fontSize: 20,
        //             )
        //           ) 
        //         : widget.trainingDuration > 0 
        //         ? Text('You have been training this superpower for $_trainingDuration seconds. Would you like to resume training?',
        //             style: TextStyle(
        //               fontSize: 20,
        //             )
        //           )
        //         : Text("Let's begin training your new superpower!",
        //             style: TextStyle(
        //               fontSize: 20,
        //             )
        //           ),
        //       ),
        //     ),
        //     Padding(
        //       padding: EdgeInsets.symmetric(vertical: 150.0),
        //       child: ButtonTheme.bar( // make buttons use the appropriate styles for cards
        //         child: ButtonBar(
        //           alignment: MainAxisAlignment.center,
        //           children: <Widget>[
        //             RaisedButton.icon(
        //               icon: Icon(Icons.filter_drama) ,
        //               label: const Text('UPLOAD'),
        //               color: Colors.orange,
        //               disabledColor: Colors.grey,
        //               textColor: Colors.white,
        //               onPressed: widget.isTrained ? null : () => {},
        //             ),
        //             RaisedButton.icon(
        //               icon: Icon(Icons.play_arrow) ,
        //               label: Text(widget.trainingDuration > 0 ? 'RESUME TRAINING' : 'BEGIN TRAINING'),
        //               color: Colors.green,
        //               disabledColor: Colors.grey,
        //               textColor: Colors.white,
        //               onPressed: widget.isTrained ? null : () => widget.toggleFileWrite(widget.gestureIndex),
        //             ),

        //           ],
        //         ),
        //       ),
        //     ),
        //     Text("$fileText"),
        //   ]
        // )
        //)
    );
  }
}

// class TrainerPage extends StatefulWidget { 
//   String title;
//   bool trained;
//   var trainingDuration;

//   TrainerPage(this.title, this.trained, this.trainingDuration);

//   @override
//   _TrainerPageState createState() => _TrainerPageState(this.trained, this.trainingDuration);
// }

// class _TrainerPageState extends State<TrainerPage> {

// }