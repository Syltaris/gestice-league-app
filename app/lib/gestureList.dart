import 'package:flutter/material.dart';

import 'package:app/main.dart';
import 'package:app/trainingPage.dart';

class GestureItem extends StatefulWidget { 
  int gestureIndex;
  bool isGestureTrained;
  bool isGestureActive;
  bool isGestureTraining;
  var gestureTrainingDuration;
  String gestureName;
  List<int> sensorData;
  var toggleFileWrite;
  var saveDataChanges;
  var updateGesture;

  GestureItem({
    Key key,
    this.gestureIndex,
    this.isGestureTrained,
    this.isGestureActive,
    this.isGestureTraining,
    this.gestureTrainingDuration,
    this.gestureName,
    this.sensorData,
    this.toggleFileWrite,
    this.saveDataChanges,
    this.updateGesture
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

  TextEditingController editedGestureName;

  void _pushTraining() {
    Navigator.of(context).push(
      new MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return TrainingPage(
            title: widget.gestureName,
            gestureIndex: widget.gestureIndex, 
            isTrained: widget.isGestureTrained, 
            isGestureTraining: widget.isGestureTraining,
            trainingDuration: widget.gestureTrainingDuration, 
            sensorData: widget.sensorData,
            toggleFileWrite: widget.toggleFileWrite,
          );
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) { //reruns when setState
    editedGestureName = TextEditingController( text: widget.gestureName );

    return Card(
      //color: Colors.grey,
      child: Card(
        margin: EdgeInsets.all(8.0),
        color: widget.isGestureActive ? Colors.cyan[600] : Colors.grey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => setState(() { _isEditingName = true; }),
                child: _isEditingName 
                ? TextField(
                    controller: editedGestureName,
                    //onChanged: (v) => () { widget.gestureName = v; },
                    onEditingComplete: () => setState(() { 
                      widget.updateGesture(
                        widget.gestureIndex, 
                        new Gesture(
                          widget.gestureIndex,
                          widget.isGestureTrained,
                          widget.isGestureActive,
                          widget.gestureTrainingDuration,
                          editedGestureName.text
                        )
                      ); 
                      _isEditingName = false; 
                    }),
                  )
                : Text(widget.gestureName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 20,
                      color: Colors.white,
                    )
                  ),
              ),
            ),
            // ListTile(
            //   leading: Icon(Icons.grade),
            //   title: Text("$sensorData"),
            //   subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
            // ),
            ButtonTheme.bar( // make buttons use the appropriate styles for cards
              child: 
              ButtonBar(
                alignment: MainAxisAlignment.spaceBetween, 
                children: <Widget>[
                  FlatButton(//HACKY: used as padding 
                    child: const Text(''),
                    onPressed: null
                  ),
                  RaisedButton(
                    color: Colors.white,
                    textColor: widget.isGestureTrained ? Colors.black : Colors.cyan[700] ,
                    child: const Text('TRAIN', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _pushTraining(),
                  ),
                  Switch(
                    value: widget.isGestureActive,
                    onChanged: (bool newValue) => 
                    setState(() { 
                      if(widget.isGestureTrained) {
                        widget.isGestureActive = newValue; 
                        widget.updateGesture(
                          widget.gestureIndex, 
                          new Gesture(
                            widget.gestureIndex,
                            widget.isGestureTrained,
                            newValue,
                            widget.gestureTrainingDuration,
                            widget.gestureName
                          )
                        ); 
                      }
                    }),
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
