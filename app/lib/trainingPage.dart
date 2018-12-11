import 'package:flutter/material.dart';

class TrainingPage extends StatefulWidget { 
  final String title;
  final bool trained;
  final String trainingDuration;

  TrainingPage(this.title, this.trained, this.trainingDuration);

  @override
  _TrainingPageState createState() => _TrainingPageState(this.trained, this.trainingDuration);
}

/*

*/
class _TrainingPageState extends State<TrainingPage> {
  bool _isTrained = false; //need to bring out from root data
  String _trainingDuration = "5 minutes";

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
            Padding(
              padding: EdgeInsets.all(50.0),
              child: _isTrained 
              ? Text('You have already trained this superpower!',
                  style: TextStyle(
                    fontSize: 20,
                  )
                ) 
              : Text('You have been training this superpower for $_trainingDuration. Would you like to resume training?',
                  style: TextStyle(
                    fontSize: 20,
                  )
                ),
            ),
            ButtonTheme.bar( // make buttons use the appropriate styles for cards
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    color: Colors.orange,
                    textColor: Colors.white,
                    child: const Text('UPLOAD'),
                    onPressed: _isTrained ? null : () => {},
                  ),
                  RaisedButton(
                    color: Colors.green,
                    disabledColor: Colors.grey,
                    textColor: Colors.white,
                    child: const Text('RESUME TRAINING'),
                    onPressed: _isTrained ? null : () => {},
                  ),
                ],
              ),
            ),
          ]
        )
      )
    );
  }
}
