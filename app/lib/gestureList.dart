import 'package:flutter/material.dart';

import 'package:app/trainingPage.dart';

class GestureItem extends StatefulWidget { 
  bool _isGestureTrained;
  bool _isGestureActive;
  String _gestureTrainingDuration;
  String _gestureName;

  GestureItem(
    this._isGestureTrained,
    this._isGestureActive,
    this._gestureTrainingDuration,
    this._gestureName
  );

  @override
  _GestureItemState createState() => _GestureItemState(
    _isGestureTrained,
    _isGestureActive,
    _gestureTrainingDuration,
    _gestureName
  );
}

/*
  Represents each gesture and it's status. Status include:
  - name?
  - description
  - active/inactive
  - training status
  Also contains buttons to allow user to train/untrain new gesture
*/
class _GestureItemState extends State<GestureItem> {

  bool _isEditingName = false;

  bool _isGestureTrained;
  bool _isGestureActive;
  String _gestureTrainingDuration;
  String _gestureName;

  _GestureItemState(
    this._isGestureTrained,
    this._isGestureActive,
    this._gestureTrainingDuration,
    this._gestureName
  );

  void _pushTraining() {
    Navigator.of(context).push(
      new MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return TrainingPage(_gestureName, _isGestureTrained, _gestureTrainingDuration);
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    return Card(
      color: _isGestureActive ? Colors.green : Colors.grey,
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => setState(() { _isEditingName = true; }),
                child: _isEditingName 
                ? TextField(
                    controller: TextEditingController(
                      text: _gestureName,
                    ),
                    onChanged: (v) => setState(() { _gestureName = v; }),
                    onEditingComplete: () => setState(() { _isEditingName = false; }),
                  )
                : Text(_gestureName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 20,
                    )
                  ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.grade),
              title: Text('The Enchanted Nightingale'),
              subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
            ),
            ButtonTheme.bar( // make buttons use the appropriate styles for cards
              child: ButtonBar(
                children: <Widget>[
                  FlatButton(
                    child: const Text('ON/OFF'),
                    onPressed: () => setState(() { _isGestureActive = !_isGestureActive; }),
                  ),
                  FlatButton(
                    child: const Text('TRAIN'),
                    onPressed: () => _pushTraining(),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}
