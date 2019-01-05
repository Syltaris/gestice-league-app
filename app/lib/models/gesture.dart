class Gesture {
  final int gestureIndex;
  final bool isGestureTrained;
  final bool isGestureActive;
  final int gestureTrainingDuration;
  final String gestureName;

  Gesture(
    this.gestureIndex, 
    this.isGestureTrained, 
    this.isGestureActive, 
    this.gestureTrainingDuration, 
    this.gestureName
  );

  Gesture.fromJson(Map<String, dynamic> json)
    : gestureIndex = json['gestureIndex'],
      isGestureTrained = json['isGestureTrained'],
      isGestureActive = json['isGestureActive'],
      gestureTrainingDuration = json['gestureTrainingDuration'],
      gestureName = json['gestureName'];

  Map<String, dynamic> toJson() =>
    {
      'gestureIndex' : gestureIndex,
      'isGestureTrained': isGestureTrained,
      'isGestureActive' : isGestureActive,
      'gestureTrainingDuration' : gestureTrainingDuration,
      'gestureName' : gestureName,
    };
}