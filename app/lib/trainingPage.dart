import 'package:flutter/material.dart';

class TrainingPage extends StatefulWidget { 
  String title;
  bool isTrained;
  var trainingDuration;
  List<int> sensorData;

  TrainingPage({
    Key key,
    this.title, 
    this.isTrained, 
    this.trainingDuration, 
    this.sensorData
  }) : super(key: key);

  @override
  _TrainingPageState createState() => _TrainingPageState();
}

/*

*/
class _TrainingPageState extends State<TrainingPage> {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, //mainAxis here is vertical axis, cross is hori
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(50.0),
                child: widget.isTrained 
                ? Text('You have already trained this superpower!',
                    style: TextStyle(
                      fontSize: 20,
                    )
                  ) 
                : widget.trainingDuration > 0 
                ? Text('You have been training this superpower for $_trainingDuration seconds. Would you like to resume training?',
                    style: TextStyle(
                      fontSize: 20,
                    )
                  )
                : Text("Let's begin training your new superpower!",
                    style: TextStyle(
                      fontSize: 20,
                    )
                  ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 150.0),
              child: ButtonTheme.bar( // make buttons use the appropriate styles for cards
                child: ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton.icon(
                      icon: Icon(Icons.filter_drama) ,
                      label: const Text('UPLOAD'),
                      color: Colors.orange,
                      disabledColor: Colors.grey,
                      textColor: Colors.white,
                      onPressed: widget.isTrained ? null : () => {},
                    ),
                    RaisedButton.icon(
                      icon: Icon(Icons.play_arrow) ,
                      label: Text(widget.trainingDuration > 0 ? 'RESUME TRAINING' : 'BEGIN TRAINING'),
                      color: Colors.green,
                      disabledColor: Colors.grey,
                      textColor: Colors.white,
                      onPressed: widget.isTrained ? null : () => {},
                    ),
                  ],
                ),
              ),
            ),
            Text("AX: $gaX, AY: $gaY, AZ: $gaZ, GX: $ggX, GY: $ggY, GZ: $ggZ Sensor: $sensorData"),
          ]
        )
      )
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