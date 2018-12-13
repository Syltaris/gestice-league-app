import 'package:flutter/material.dart';

import 'package:app/trainingPage.dart';

class GestureItem extends StatefulWidget { 
  bool isGestureTrained;
  bool isGestureActive;
  var gestureTrainingDuration;
  String gestureName;
  List<int> sensorData;

  GestureItem({
    Key key,
    this.isGestureTrained,
    this.isGestureActive,
    this.gestureTrainingDuration,
    this.gestureName,
    this.sensorData,
  }) : super(key:key);

  @override
  _GestureItemState createState() => _GestureItemState();
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

  void _pushTraining() {
    Navigator.of(context).push(
      new MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return TrainingPage(
            title: widget.gestureName, 
            isTrained: widget.isGestureTrained, 
            trainingDuration: widget.gestureTrainingDuration, 
            sensorData: widget.sensorData
          );
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    return Card(
      color: widget.isGestureActive ? Colors.green : Colors.grey,
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
                      text: widget.gestureName,
                    ),
                    onChanged: (v) => setState(() { widget.gestureName = v; }),
                    onEditingComplete: () => setState(() { _isEditingName = false; }),
                  )
                : Text(widget.gestureName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 20,
                    )
                  ),
              ),
            ),
            // const ListTile(
            //   leading: Icon(Icons.grade),
            //   title: Text('The Enchanted Nightingale'),
            //   subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
            // ),
            ButtonTheme.bar( // make buttons use the appropriate styles for cards
              child: ButtonBar(
                children: <Widget>[
                  FlatButton(
                    child: const Text('ON/OFF'),
                    onPressed: !widget.isGestureTrained ? null : () => setState(() { widget.isGestureActive = !widget.isGestureActive; }),
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
