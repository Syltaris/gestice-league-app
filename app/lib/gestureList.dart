import 'package:flutter/material.dart';

class GestureItem extends StatefulWidget { 
  //GestureItem({Key key, this.title}) : super(key: key);

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


  bool _isGestureActive = false;
  String _gestureName = "Gesture Name";

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
                    onPressed: () { /* ... */ },
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
