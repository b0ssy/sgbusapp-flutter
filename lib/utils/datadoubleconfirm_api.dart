import 'package:http/http.dart' as http;

import '../models.dart';
import '../utils/utils.dart';

const cBaseUrl = 'https://raw.githubusercontent.com/'
    'hxchua/datadoubleconfirm/master/datasets/mrtsg.csv';

Future<List<MrtStation>> getMrtStations() async {
  var url = Uri.parse(cBaseUrl);
  var response = await http.get(url);
  return parseMrtStationsCsv(response.body);
}

List<MrtStation> parseMrtStationsCsv(String csvText) {
  List<MrtStation> stations = [];
  var lines = csvText.split('\n');
  if (lines.isNotEmpty) {
    lines.removeAt(0);
    for (var line in lines) {
      var parts = line.split(',');
      if (parts.length == 8) {
        var stn = MrtStation();
        stn.objectId = parts[0];
        stn.stnName = parts[1];
        stn.stnNo = parts[2];
        stn.x = parseDouble(parts[3]);
        stn.y = parseDouble(parts[4]);
        stn.latitude = parseDouble(parts[5]);
        stn.longitude = parseDouble(parts[6]);
        stn.color = parts[7];
        stations.add(stn);
      }
    }
  }
  return stations;
}
