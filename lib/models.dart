import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'utils/utils.dart';

class BusService {
  int? id;
  String? serviceNo;
  String? operator;
  int? direction;
  String? category;
  String? originCode;
  String? destinationCode;
  String? amPeakFreq;
  String? amOffpeakFreq;
  String? pmPeakFreq;
  String? pmOffpeakFreq;
  String? loopDesc;

  BusService();

  BusService.fromMap(Map<String, dynamic> map) {
    id = parseInt(map['id']);
    serviceNo = parseString(map['service_no']);
    operator = parseString(map['operator']);
    direction = parseInt(map['direction']);
    category = parseString(map['category']);
    originCode = parseString(map['origin_code']);
    destinationCode = parseString(map['destination_code']);
    amPeakFreq = parseString(map['am_peak_freq']);
    amOffpeakFreq = parseString(map['am_offpeak_freq']);
    pmPeakFreq = parseString(map['pm_peak_freq']);
    pmOffpeakFreq = parseString(map['pm_offpeak_freq']);
    loopDesc = parseString(map['loop_desc']);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    if (serviceNo != null) {
      map['service_no'] = serviceNo;
    }
    if (operator != null) {
      map['operator'] = operator;
    }
    if (direction != null) {
      map['direction'] = direction;
    }
    if (category != null) {
      map['category'] = category;
    }
    if (originCode != null) {
      map['origin_code'] = originCode;
    }
    if (destinationCode != null) {
      map['destination_code'] = destinationCode;
    }
    if (amPeakFreq != null) {
      map['am_peak_freq'] = amPeakFreq;
    }
    if (amOffpeakFreq != null) {
      map['am_offpeak_freq'] = amOffpeakFreq;
    }
    if (pmPeakFreq != null) {
      map['pm_peak_freq'] = pmPeakFreq;
    }
    if (pmOffpeakFreq != null) {
      map['pm_offpeak_freq'] = pmOffpeakFreq;
    }
    if (loopDesc != null) {
      map['loop_desc'] = loopDesc;
    }
    return map;
  }

  static int sortByServiceNo(BusService e1, BusService e2) {
    var serviceNo1 = e1.serviceNo ?? '';
    var serviceNo2 = e2.serviceNo ?? '';
    var serviceNo1StartsWithDigit = serviceNo1.startsWith(RegExp(r'[0-9]'));
    var serviceNo2StartsWithDigit = serviceNo2.startsWith(RegExp(r'[0-9]'));
    if (serviceNo1StartsWithDigit && !serviceNo2StartsWithDigit) {
      return -1;
    }
    if (!serviceNo1StartsWithDigit && serviceNo2StartsWithDigit) {
      return 1;
    }
    if (serviceNo1StartsWithDigit && serviceNo2StartsWithDigit) {
      var serviceNo1Int =
          int.parse(serviceNo1.replaceAll(RegExp(r'[^0-9]'), ''));
      var serviceNo2Int =
          int.parse(serviceNo2.replaceAll(RegExp(r'[^0-9]'), ''));
      if (serviceNo1Int < serviceNo2Int) {
        return -1;
      }
      if (serviceNo1Int > serviceNo2Int) {
        return 1;
      }
    }
    return serviceNo1.compareTo(serviceNo2);
  }
}

class BusStop {
  int? id;
  String? busStopCode;
  String? roadName;
  String? description;
  double? latitude;
  double? longitude;

  int? uiIndex;

  BusStop();

  BusStop.fromMap(Map<String, dynamic> map) {
    id = parseInt(map['id']);
    busStopCode = parseString(map['bus_stop_code']);
    roadName = parseString(map['road_name']);
    description = parseString(map['description']);
    latitude = parseDouble(map['latitude']);
    longitude = parseDouble(map['longitude']);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    if (busStopCode != null) {
      map['bus_stop_code'] = busStopCode;
    }
    if (roadName != null) {
      map['road_name'] = roadName;
    }
    if (description != null) {
      map['description'] = description;
    }
    if (latitude != null) {
      map['latitude'] = latitude;
    }
    if (longitude != null) {
      map['longitude'] = longitude;
    }
    return map;
  }

  static void setUiIndex(List<BusStop> busStops) {
    for (var i = 0; i < busStops.length; i++) {
      busStops[i].uiIndex = i + 1;
    }
  }
}

class BusRoute {
  int? id;
  String? serviceNo;
  String? operator;
  int? direction;
  int? stopSequence;
  String? busStopCode;
  double? distance;
  String? wdFirstBus;
  String? wdLastBus;
  String? satFirstBus;
  String? satLastBus;
  String? sunFirstBus;
  String? sunLastBus;

  BusRoute();

  BusRoute.fromMap(Map<String, dynamic> map) {
    id = parseInt(map['id']);
    serviceNo = parseString(map['service_no']);
    operator = parseString(map['operator']);
    direction = parseInt(map['direction']);
    stopSequence = parseInt(map['stop_sequence']);
    busStopCode = parseString(map['bus_stop_code']);
    distance = parseDouble(map['distance']);
    wdFirstBus = parseString(map['wd_first_bus']);
    wdLastBus = parseString(map['wd_last_bus']);
    satFirstBus = parseString(map['sat_first_bus']);
    satLastBus = parseString(map['sat_last_bus']);
    sunFirstBus = parseString(map['sun_first_bus']);
    sunLastBus = parseString(map['sun_last_bus']);
  }

  String get wdFirstBusStr => wdFirstBus?.length == 4
      ? DateFormat('KK:mm a')
          .format(DateFormat('KK:mm').parse(
              wdFirstBus!.substring(0, 2) + ':' + wdFirstBus!.substring(2, 4)))
          .toLowerCase()
      : '-';

  String get wdLastBusStr => wdLastBus?.length == 4
      ? DateFormat('KK:mm a')
          .format(DateFormat('KK:mm').parse(
              wdLastBus!.substring(0, 2) + ':' + wdLastBus!.substring(2, 4)))
          .toLowerCase()
      : '-';

  String get satFirstBusStr => satFirstBus?.length == 4
      ? DateFormat('KK:mm a')
          .format(DateFormat('KK:mm').parse(satFirstBus!.substring(0, 2) +
              ':' +
              satFirstBus!.substring(2, 4)))
          .toLowerCase()
      : '-';

  String get satLastBusStr => satLastBus?.length == 4
      ? DateFormat('KK:mm a')
          .format(DateFormat('KK:mm').parse(
              satLastBus!.substring(0, 2) + ':' + satLastBus!.substring(2, 4)))
          .toLowerCase()
      : '-';

  String get sunFirstBusStr => sunFirstBus?.length == 4
      ? DateFormat('KK:mm a')
          .format(DateFormat('KK:mm').parse(sunFirstBus!.substring(0, 2) +
              ':' +
              sunFirstBus!.substring(2, 4)))
          .toLowerCase()
      : '-';

  String get sunLastBusStr => sunLastBus?.length == 4
      ? DateFormat('KK:mm a')
          .format(DateFormat('KK:mm').parse(
              sunLastBus!.substring(0, 2) + ':' + sunLastBus!.substring(2, 4)))
          .toLowerCase()
      : '-';

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    if (serviceNo != null) {
      map['service_no'] = serviceNo;
    }
    if (operator != null) {
      map['operator'] = operator;
    }
    if (direction != null) {
      map['direction'] = direction;
    }
    if (stopSequence != null) {
      map['stop_sequence'] = stopSequence;
    }
    if (busStopCode != null) {
      map['bus_stop_code'] = busStopCode;
    }
    if (distance != null) {
      map['distance'] = distance;
    }
    if (wdFirstBus != null) {
      map['wd_first_bus'] = wdFirstBus;
    }
    if (wdLastBus != null) {
      map['wd_last_bus'] = wdLastBus;
    }
    if (satFirstBus != null) {
      map['sat_first_bus'] = satFirstBus;
    }
    if (satLastBus != null) {
      map['sat_last_bus'] = satLastBus;
    }
    if (sunFirstBus != null) {
      map['sun_first_bus'] = sunFirstBus;
    }
    if (sunLastBus != null) {
      map['sun_last_bus'] = sunLastBus;
    }
    return map;
  }
}

class BusArrival {
  DateTime time = DateTime.now();

  String? serviceNo;
  String? operator;
  BusArrivalNextBus? nextBus;
  BusArrivalNextBus? nextBus2;
  BusArrivalNextBus? nextBus3;

  List<dynamic> parse(BuildContext context, {Brightness? brightness}) {
    var arrivalTimes = ['-', '-', '-'];
    var estimatedArrival = nextBus?.estimatedArrival;
    if (estimatedArrival != null) {
      var diffMins = estimatedArrival.difference(DateTime.now()).inMinutes;
      arrivalTimes[0] = diffMins <= 0 ? 'Arr' : diffMins.toString();
    }
    var estimatedArrival2 = nextBus2?.estimatedArrival;
    if (estimatedArrival2 != null) {
      var diffMins = estimatedArrival2.difference(DateTime.now()).inMinutes;
      arrivalTimes[1] = diffMins <= 0 ? 'Arr' : diffMins.toString();
    }
    var estimatedArrival3 = nextBus3?.estimatedArrival;
    if (estimatedArrival3 != null) {
      var diffMins = estimatedArrival3.difference(DateTime.now()).inMinutes;
      arrivalTimes[2] = diffMins <= 0 ? 'Arr' : diffMins.toString();
    }

    Color? color;
    var shade = (brightness ?? Theme.of(context).brightness) == Brightness.light
        ? 800
        : 400;
    if (arrivalTimes[0] == 'Arr') {
      color = Colors.green[shade];
    } else {
      int? value = int.tryParse(arrivalTimes[0]);
      if (value != null) {
        if (value <= 5) {
          color = Colors.green[shade];
        } else if (value <= 10) {
          color = Colors.yellow[shade];
        } else if (value <= 20) {
          color = Colors.orange[shade];
        } else {
          color = Colors.red[shade];
        }
      }
    }

    return [arrivalTimes, color];
  }
}

class BusArrivalNextBus {
  String? originCode;
  String? destinationCode;
  DateTime? estimatedArrival;
  double? latitude;
  double? longitude;
  String? visitNumber;
  String? load;
  String? feature;
  String? type;

  bool get hasValidLocation =>
      latitude != null &&
      latitude != 0.0 &&
      longitude != null &&
      longitude != 0.0;
}

class FavBusStop {
  final String busStopCode;
  List<String>? favServiceNos;
  bool? showFavServiceNos;
  String? altDescription;

  FavBusStop({
    required this.busStopCode,
    this.favServiceNos,
    this.showFavServiceNos,
    this.altDescription,
  });

  static FavBusStop fromMap(Map<String, dynamic> value) {
    return FavBusStop(
      busStopCode: parseString(value['busStopCode']) ?? '',
      favServiceNos: parseStringList(value['favServiceNos']),
      showFavServiceNos: parseBool(value['showFavServiceNos']),
      altDescription: parseString(value['altDescription']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busStopCode': busStopCode,
      'favServiceNos': favServiceNos,
      'showFavServiceNos': showFavServiceNos,
      'altDescription': altDescription,
    };
  }
}

class MrtStation {
  String? objectId;
  String? stnName;
  String? stnNo;
  double? x;
  double? y;
  double? latitude;
  double? longitude;
  String? color;

  MrtStation();

  MrtStation.fromMap(Map<String, dynamic> map) {
    objectId = parseString(map['object_id']);
    stnName = parseString(map['stn_name']);
    stnNo = parseString(map['stn_no']);
    x = parseDouble(map['x']);
    y = parseDouble(map['y']);
    latitude = parseDouble(map['latitude']);
    longitude = parseDouble(map['longitude']);
    color = parseString(map['color']);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (objectId != null) {
      map['object_id'] = objectId;
    }
    if (stnName != null) {
      map['stn_name'] = stnName;
    }
    if (stnNo != null) {
      map['stn_no'] = stnNo;
    }
    if (x != null) {
      map['x'] = x;
    }
    if (y != null) {
      map['y'] = y;
    }
    if (latitude != null) {
      map['latitude'] = latitude;
    }
    if (longitude != null) {
      map['longitude'] = longitude;
    }
    if (color != null) {
      map['color'] = color;
    }
    return map;
  }
}
