import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';
import '../models.dart';

const apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
const baseUrl = 'http://datamall2.mytransport.sg';
var busArrivalCache = Cache<List<BusArrival>>(defaultExpiryMs: 5000);

BusArrival parseBusArrival(Map<String, dynamic> map) {
  var ba = BusArrival();
  ba.serviceNo = parseString(map['ServiceNo']);
  ba.operator = parseString(map['Operator']);
  ba.nextBus =
      map['NextBus'] != null ? parseBusArrivalNextBus(map['NextBus']) : null;
  ba.nextBus2 =
      map['NextBus2'] != null ? parseBusArrivalNextBus(map['NextBus2']) : null;
  ba.nextBus3 =
      map['NextBus3'] != null ? parseBusArrivalNextBus(map['NextBus3']) : null;
  return ba;
}

BusArrivalNextBus parseBusArrivalNextBus(Map<String, dynamic> map) {
  var nb = BusArrivalNextBus();
  nb.originCode = parseString(map['OriginCode']);
  nb.destinationCode = parseString(map['DestinationCode']);
  if (map['EstimatedArrival'] != null &&
      map['EstimatedArrival'].runtimeType == String &&
      map['EstimatedArrival'] != '') {
    nb.estimatedArrival = DateTime.parse(map['EstimatedArrival']);
  }
  nb.latitude = parseDouble(map['Latitude']);
  nb.longitude = parseDouble(map['Longitude']);
  nb.visitNumber = parseString(map['VisitNumber']);
  nb.load = parseString(map['Load']);
  nb.feature = parseString(map['Feature']);
  nb.type = parseString(map['Type']);
  return nb;
}

BusStop parseBusStop(Map<String, dynamic> map) {
  var busStop = BusStop();
  busStop.busStopCode = parseString(map['BusStopCode']);
  busStop.roadName = parseString(map['RoadName']);
  busStop.description = parseString(map['Description']);
  busStop.latitude = parseDouble(map['Latitude']);
  busStop.longitude = parseDouble(map['Longitude']);
  return busStop;
}

BusRoute parseBusRoute(Map<String, dynamic> map) {
  var busRoute = BusRoute();
  busRoute.serviceNo = parseString(map['ServiceNo']);
  busRoute.operator = parseString(map['Operator']);
  busRoute.direction = parseInt(map['Direction']);
  busRoute.stopSequence = parseInt(map['StopSequence']);
  busRoute.busStopCode = parseString(map['BusStopCode']);
  busRoute.distance = parseDouble(map['Distance']);
  busRoute.wdFirstBus = parseString(map['WD_FirstBus']);
  busRoute.wdLastBus = parseString(map['WD_LastBus']);
  busRoute.satFirstBus = parseString(map['SAT_FirstBus']);
  busRoute.satLastBus = parseString(map['SAT_LastBus']);
  busRoute.sunFirstBus = parseString(map['SUN_FirstBus']);
  busRoute.sunLastBus = parseString(map['SUN_LastBus']);
  return busRoute;
}

BusService parseBusService(Map<String, dynamic> map) {
  var busService = BusService();
  busService.serviceNo = parseString(map['ServiceNo']);
  busService.operator = parseString(map['Operator']);
  busService.direction = parseInt(map['Direction']);
  busService.category = parseString(map['Category']);
  busService.originCode = parseString(map['OriginCode']);
  busService.destinationCode = parseString(map['DestinationCode']);
  busService.amPeakFreq = parseString(map['AM_Peak_Freq']);
  busService.amOffpeakFreq = parseString(map['AM_Offpeak_Freq']);
  busService.pmPeakFreq = parseString(map['PM_Peak_Freq']);
  busService.pmOffpeakFreq = parseString(map['PM_Offpeak_Freq']);
  busService.loopDesc = parseString(map['LoopDesc']);
  return busService;
}

Future<List<BusArrival>> getBusArrival({
  required String busStopCode,
  String? serviceNo,
}) async {
  List<BusArrival>? cached = busArrivalCache.get(busStopCode);
  if (cached != null) {
    return cached;
  }
  var uri = '$baseUrl/ltaodataservice/BusArrivalv2?BusStopCode=$busStopCode';
  if (serviceNo != null) {
    uri += '&ServiceNo=$serviceNo';
  }
  var url = Uri.parse(uri);
  var response = await http.get(url, headers: _getHttpHeaders());
  var data = jsonDecode(response.body);
  List<dynamic> services = data['Services'];
  var busArrivals = services.map((e) => parseBusArrival(e)).toList();
  // Sort by service no
  busArrivals.sort((ba1, ba2) {
    var serviceNo1 = ba1.serviceNo ?? '';
    var serviceNo2 = ba2.serviceNo ?? '';
    var serviceNo1Int = int.parse(serviceNo1.replaceAll(RegExp(r'[^0-9]'), ''));
    var serviceNo2Int = int.parse(serviceNo2.replaceAll(RegExp(r'[^0-9]'), ''));
    if (serviceNo1Int < serviceNo2Int) {
      return -1;
    } else if (serviceNo1Int > serviceNo2Int) {
      return 1;
    }
    return serviceNo1.compareTo(serviceNo2);
  });
  busArrivalCache.put(busStopCode, busArrivals);
  return busArrivals;
}

Future<List<BusStop>> getBusStops({int? skip}) async {
  var uri = '$baseUrl/ltaodataservice/BusStops';
  if (skip != null && skip > 0) {
    uri += '?\$skip=$skip';
  }
  var url = Uri.parse(uri);
  var response = await http.get(url, headers: _getHttpHeaders());
  var data = jsonDecode(response.body);
  List<BusStop> busStops = [];
  for (var busStopJson in data['value']) {
    busStops.add(parseBusStop(busStopJson));
  }
  return busStops;
}

Future<List<BusStop>> getAllBusStops() async {
  debugPrint('Getting all bus stops...');
  List<BusStop> busStops = [];
  var skip = 0;
  while (true) {
    var curBusStops = await getBusStops(skip: skip);
    if (curBusStops.isEmpty) {
      break;
    }
    busStops += curBusStops;
    skip += curBusStops.length;
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Got ${busStops.length} bus stops');
  }
  debugPrint('Done');
  return busStops;
}

Future<List<BusService>> getBusServices({int? skip}) async {
  var uri = '$baseUrl/ltaodataservice/BusServices';
  if (skip != null && skip > 0) {
    uri += '?\$skip=$skip';
  }
  var url = Uri.parse(uri);
  var response = await http.get(url, headers: _getHttpHeaders());
  var data = jsonDecode(response.body);
  List<BusService> busServices = [];
  for (var busServiceJson in data['value']) {
    busServices.add(parseBusService(busServiceJson));
  }
  return busServices;
}

Future<List<BusService>> getAllBusServices() async {
  debugPrint('Getting all bus services...');
  List<BusService> busServices = [];
  var skip = 0;
  while (true) {
    var curBusServices = await getBusServices(skip: skip);
    if (curBusServices.isEmpty) {
      break;
    }
    busServices += curBusServices;
    skip += curBusServices.length;
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Got ${busServices.length} bus services');
  }
  debugPrint('Done');
  return busServices;
}

Future<List<BusRoute>> getBusRoutes({int? skip}) async {
  var uri = '$baseUrl/ltaodataservice/BusRoutes';
  if (skip != null && skip > 0) {
    uri += '?\$skip=$skip';
  }
  var url = Uri.parse(uri);
  var response = await http.get(url, headers: _getHttpHeaders());
  var data = jsonDecode(response.body);
  List<BusRoute> busRoutes = [];
  for (var busRouteJson in data['value']) {
    busRoutes.add(parseBusRoute(busRouteJson));
  }
  return busRoutes;
}

Future<List<BusRoute>> getAllBusRoutes() async {
  debugPrint('Getting all bus routes...');
  List<BusRoute> busRoutes = [];
  var skip = 0;
  while (true) {
    var curBusRoutes = await getBusRoutes(skip: skip);
    if (curBusRoutes.isEmpty) {
      break;
    }
    busRoutes += curBusRoutes;
    skip += curBusRoutes.length;
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Got ${busRoutes.length} bus routes');
  }
  debugPrint('Done');
  return busRoutes;
}

Map<String, String> _getHttpHeaders() {
  return {'AccountKey': apiKey};
}
