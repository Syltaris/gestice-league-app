import 'package:flutter/material.dart';

class TrainingPage extends StatefulWidget { 
  String title;
  bool trained;
  var trainingDuration;

  TrainingPage(this.title, this.trained, this.trainingDuration);

  @override
  _TrainingPageState createState() => _TrainingPageState(this.trained, this.trainingDuration);
}

/*

*/
class _TrainingPageState extends State<TrainingPage> {
  bool _isTrained; //need to bring out from root data
  var _trainingDuration;

  _TrainingPageState(this._isTrained, this._trainingDuration);

  @override
  Widget build(BuildContext context) { //reruns when setState
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
                child: _isTrained 
                ? Text('You have already trained this superpower!',
                    style: TextStyle(
                      fontSize: 20,
                    )
                  ) 
                : _trainingDuration > 0 
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
                      onPressed: _isTrained ? null : () => {},
                    ),
                    RaisedButton.icon(
                      icon: Icon(Icons.play_arrow) ,
                      label: Text(_trainingDuration > 0 ? 'RESUME TRAINING' : 'BEGIN TRAINING'),
                      color: Colors.green,
                      disabledColor: Colors.grey,
                      textColor: Colors.white,
                      onPressed: _isTrained ? null : () => {},
                    ),
                  ],
                ),
              ),
            )
            
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