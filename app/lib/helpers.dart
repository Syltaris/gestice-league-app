import 'dart:typed_data';

int convertUint8ListToInt(Uint8List data) {
  var bdata = new ByteData.view(data.buffer);
  return bdata.getInt8(0);
}

int convertDataToInt(List<int> values) {
  Uint8List buffer = Uint8List.fromList(values);
  var bdata = new ByteData.view(buffer.buffer);
  return bdata.getInt32(0, Endian.little);
}

List<int> convert2ByteDataToIntList(List<int> values, int n) {
  List<int> output = new List<int>();
  //print(values);
  for(int i = 0; i < n; i++) {
    Uint8List buffer = Uint8List.fromList(values.sublist(i*2, i*2+2));
    var bdata = new ByteData.view(buffer.buffer);
    output.add(bdata.getInt16(0, Endian.big));
  }
  return output;
}

List<int> convert4ByteDataToIntList(List<int> values, int n) {
  List<int> output = new List<int>();
  //print(values);
  for(int i = 0; i < n; i++) {
    Uint8List buffer = Uint8List.fromList(values.sublist(i*4, i*4+4));
    var bdata = new ByteData.view(buffer.buffer);
    output.add(bdata.getInt32(0, Endian.big));
  }
  return output;
}