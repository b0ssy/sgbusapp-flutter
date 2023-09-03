import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'constants.dart' as constants;
import 'database.dart' as db;
import 'models.dart';
import 'utils/datamall_api.dart';

const cMaxRecentBusStopSearchesSize = 10;
const cFavPageNavIndex = 0;
const cNearbyPageNavIndex = 1;
const cBusesPageNavIndex = 2;
const cMrtMapPageNavIndex = 3;

class Preferences extends ChangeNotifier {
  final SharedPreferences prefs;

  // Database
  var database = db.Database();

  ThemeMode themeMode = ThemeMode.system;
  bool showMap = true;
  bool showMyLocation = true;
  bool showNearbyRadius = true;
  bool showDistanceForNearbyFavs = true;
  bool showBusStopsForSelectedBusArrival = true;
  List<FavBusStop> favBusStops = [];
  var ackTapToRefreshBusArrivals = false;
  var ackShowBusStopsForSelectedBus = false;
  var ackDragDownToRefreshNearbyBusStops = false;
  var lastNavIndex = 0;
  List<String> recentBusStopSearches = [];
  var maxNearbyDistance = 200.0; // meters
  double? lastMapCenterLat;
  double? lastMapCenterLon;
  double? lastMapZoom;
  DateTime? lastDataSyncDate;

  // Cached in memory only
  var needsToLoadDatabase = false;
  Map<String, BusStop> busStopsByBusStopCode = {};
  Map<String, FavBusStop> favBusStopsByBusStopCode = {};
  List<String> searchBusStopCode = ['', '', '', '', ''];

  Preferences(this.prefs);

  Future<void> load() async {
    // database
    await database.open(onCreateCallback: (database) async {
      needsToLoadDatabase = true;
    });

    // themeMode
    {
      var value = prefs.getString('themeMode');
      if (value == 'system') {
        themeMode = ThemeMode.system;
      } else if (value == 'light') {
        themeMode = ThemeMode.light;
      } else if (value == 'dark') {
        themeMode = ThemeMode.dark;
      }
    }

    // showMap
    {
      showMap = prefs.getBool('showMap') ?? showMap;
    }

    // showCurrentLocation
    {
      showMyLocation = prefs.getBool('showMyLocation') ?? showMyLocation;
    }

    // showNearbyRadius
    {
      showNearbyRadius = prefs.getBool('showNearbyRadius') ?? showNearbyRadius;
    }

    // showDistanceForNearbyFavs
    {
      showDistanceForNearbyFavs = prefs.getBool('showDistanceForNearbyFavs') ??
          showDistanceForNearbyFavs;
    }

    // showBusStopsForSelectedBusArrival
    {
      showBusStopsForSelectedBusArrival =
          prefs.getBool('showBusStopsForSelectedBusArrival') ??
              showBusStopsForSelectedBusArrival;
    }

    // favBusStops
    {
      favBusStopsByBusStopCode = {};
      var value = prefs.getString('favBusStops');
      if (value != null) {
        List<dynamic> decoded = jsonDecode(value);
        favBusStops = decoded.map((i) => FavBusStop.fromMap(i)).toList();
        for (var favBusStop in favBusStops) {
          favBusStopsByBusStopCode[favBusStop.busStopCode] = favBusStop;
        }
      }
    }

    // ackDoubleTapToRefreshBusArrivals
    {
      ackTapToRefreshBusArrivals =
          prefs.getBool('ackTapToRefreshBusArrivals') ?? false;
    }

    // ackShowBusStopsForSelectedBus
    {
      ackShowBusStopsForSelectedBus =
          prefs.getBool('ackShowBusStopsForSelectedBus') ?? false;
    }

    // ackDragDownToRefreshNearbyBusStops
    {
      ackDragDownToRefreshNearbyBusStops =
          prefs.getBool('ackDragDownToRefreshNearbyBusStops') ?? false;
    }

    // lastNavIndex
    {
      lastNavIndex = prefs.getInt('lastNavIndex') ?? 0;
    }

    // recentBusStopSearches
    {
      recentBusStopSearches =
          prefs.getStringList('recentBusStopSearches') ?? [];
    }

    // maxNearbyDistance
    {
      maxNearbyDistance =
          prefs.getDouble('maxNearbyDistance') ?? maxNearbyDistance;
    }

    // lastMapCenterLat
    {
      lastMapCenterLat =
          prefs.getDouble('lastMapCenterLat') ?? lastMapCenterLat;
    }

    // lastMapCenterLon
    {
      lastMapCenterLon =
          prefs.getDouble('lastMapCenterLon') ?? lastMapCenterLon;
    }

    // lastMapZoom
    {
      lastMapZoom = prefs.getDouble('lastMapZoom') ?? lastMapZoom;
    }

    // lastDataSyncDate
    {
      var value = prefs.getInt('lastDataSyncDate');
      if (value != null) {
        lastDataSyncDate = DateTime.fromMillisecondsSinceEpoch(value);
      }
    }

    // busStopsByBusStopCode
    {
      busStopsByBusStopCode = {};
      var db = database.get();
      if (db != null) {
        List<Map<String, dynamic>> results = await db.query('BusStop');
        for (var e in results) {
          var busStop = BusStop.fromMap(e);
          var busStopCode = busStop.busStopCode;
          if (busStopCode != null) {
            busStopsByBusStopCode[busStopCode] = busStop;
          }
        }
      }
    }

    notifyListeners();
  }

  Future<void> loadDatabase() async {
    // bus services
    {
      String value = await rootBundle.loadString(constants.busServicesJsonPath);
      List<dynamic> decoded = jsonDecode(value);
      var busServices = decoded.map((e) => parseBusService(e)).toList();
      await database.updateBusServices(busServices);
    }

    // bus stops
    {
      String value = await rootBundle.loadString(constants.busStopsJsonPath);
      List<dynamic> decoded = jsonDecode(value);
      var busStops = decoded.map((e) => parseBusStop(e)).toList();
      await database.updateBusStops(busStops);
    }

    // bus routes
    {
      String value = await rootBundle.loadString(constants.busRoutesJsonPath);
      List<dynamic> decoded = jsonDecode(value);
      var busRoutes = decoded.map((e) => parseBusRoute(e)).toList();
      await database.updateBusRoutes(busRoutes);
    }

    // busStopsByBusStopCode
    {
      busStopsByBusStopCode = {};
      var db = database.get();
      if (db != null) {
        List<Map<String, dynamic>> results = await db.query('BusStop');
        for (var e in results) {
          var busStop = BusStop.fromMap(e);
          var busStopCode = busStop.busStopCode;
          if (busStopCode != null) {
            busStopsByBusStopCode[busStopCode] = busStop;
          }
        }
      }
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    var value = 'system';
    if (themeMode == ThemeMode.system) {
      value = 'system';
    } else if (themeMode == ThemeMode.light) {
      value = 'light';
    } else if (themeMode == ThemeMode.dark) {
      value = 'dark';
    }
    await prefs.setString('themeMode', value);
    this.themeMode = themeMode;
    notifyListeners();
  }

  Future<void> setShowMap(bool showMap) async {
    if (this.showMap != showMap) {
      await prefs.setBool('showMap', showMap);
      this.showMap = showMap;
      notifyListeners();
    }
  }

  Future<void> setShowMyLocation(bool showMyLocation) async {
    if (this.showMyLocation != showMyLocation) {
      await prefs.setBool('showMyLocation', showMyLocation);
      this.showMyLocation = showMyLocation;
      notifyListeners();
    }
  }

  Future<void> setShowNearbyRadius(bool showNearbyRadius) async {
    if (this.showNearbyRadius != showNearbyRadius) {
      await prefs.setBool('showNearbyRadius', showNearbyRadius);
      this.showNearbyRadius = showNearbyRadius;
      notifyListeners();
    }
  }

  Future<void> setShowDistanceForNearbyFavs(
      bool showDistanceForNearbyFavs) async {
    if (this.showDistanceForNearbyFavs != showDistanceForNearbyFavs) {
      await prefs.setBool(
          'showDistanceForNearbyFavs', showDistanceForNearbyFavs);
      this.showDistanceForNearbyFavs = showDistanceForNearbyFavs;
      notifyListeners();
    }
  }

  Future<void> setShowBusStopsForSelectedBusArrival(
      bool showBusStopsForSelectedBusArrival) async {
    if (this.showBusStopsForSelectedBusArrival !=
        showBusStopsForSelectedBusArrival) {
      await prefs.setBool('showBusStopsForSelectedBusArrival',
          showBusStopsForSelectedBusArrival);
      this.showBusStopsForSelectedBusArrival =
          showBusStopsForSelectedBusArrival;
      notifyListeners();
    }
  }

  Future<void> addFavBusStop(
    String busStopCode, {
    List<String>? favServiceNos,
    int? index,
  }) async {
    var favBusStop = FavBusStop(busStopCode: busStopCode);
    favBusStops.insert(index ?? 0, favBusStop);
    if (favServiceNos != null) {
      favBusStop.favServiceNos = favServiceNos;
    }
    favBusStopsByBusStopCode[favBusStop.busStopCode] = favBusStop;
    String value = jsonEncode(favBusStops.map((e) => e.toMap()).toList());
    await prefs.setString('favBusStops', value);
    notifyListeners();
  }

  Future<int?> removeFavBusStop(String busStopCode) async {
    var index = favBusStops.indexWhere((e) => e.busStopCode == busStopCode);
    if (index >= 0) {
      favBusStops.removeAt(index);
      favBusStopsByBusStopCode.remove(busStopCode);
      String value = jsonEncode(favBusStops.map((e) => e.toMap()).toList());
      await prefs.setString('favBusStops', value);
      notifyListeners();
    }
    return index;
  }

  Future<void> updateFavBusStop(
    String busStopCode, {
    String? addFavServiceNo,
    String? removeFavServiceNo,
    bool? showFavServiceNos,
    String? altDescription,
  }) async {
    var index = favBusStops.indexWhere((e) => e.busStopCode == busStopCode);
    if (index >= 0) {
      if (addFavServiceNo != null) {
        var favServiceNos = favBusStops[index].favServiceNos ?? [];
        favServiceNos.insert(0, addFavServiceNo);
        favBusStops[index].favServiceNos = favServiceNos;
      }
      if (removeFavServiceNo != null) {
        var favServiceNos = favBusStops[index].favServiceNos ?? [];
        favServiceNos.remove(removeFavServiceNo);
        favBusStops[index].favServiceNos = favServiceNos;
      }
      if (showFavServiceNos != null) {
        favBusStops[index].showFavServiceNos = showFavServiceNos;
      }
      if (altDescription != null) {
        favBusStops[index].altDescription =
            altDescription.isNotEmpty ? altDescription : null;
      }
      favBusStopsByBusStopCode[busStopCode] = favBusStops[index];
      String value = jsonEncode(favBusStops.map((e) => e.toMap()).toList());
      await prefs.setString('favBusStops', value);
      notifyListeners();
    }
  }

  Future<void> moveFavBusStop(int oldIndex, int newIndex) async {
    var fbs = favBusStops.removeAt(oldIndex);
    newIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    favBusStops.insert(newIndex, fbs);
    String value = jsonEncode(favBusStops.map((e) => e.toMap()).toList());
    await prefs.setString('favBusStops', value);
    notifyListeners();
  }

  void setSearchBusStopCode(List<String> searchBusStopCode) {
    this.searchBusStopCode = searchBusStopCode;
    notifyListeners();
  }

  Future<void> setAckTapToRefreshBusArrivals(
      bool ackTapToRefreshBusArrivals) async {
    await prefs.setBool(
        'ackTapToRefreshBusArrivals', ackTapToRefreshBusArrivals);
    this.ackTapToRefreshBusArrivals = ackTapToRefreshBusArrivals;
    notifyListeners();
  }

  Future<void> setAckShowBusStopsForSelectedBus(
      bool ackShowBusStopsForSelectedBus) async {
    await prefs.setBool(
        'ackShowBusStopsForSelectedBus', ackShowBusStopsForSelectedBus);
    this.ackShowBusStopsForSelectedBus = ackShowBusStopsForSelectedBus;
    notifyListeners();
  }

  Future<void> setAckDragDownToRefreshNearbyBusStops(
      bool ackDragDownToRefreshNearbyBusStops) async {
    await prefs.setBool('ackDragDownToRefreshNearbyBusStops',
        ackDragDownToRefreshNearbyBusStops);
    this.ackDragDownToRefreshNearbyBusStops =
        ackDragDownToRefreshNearbyBusStops;
    notifyListeners();
  }

  Future<void> setLastNavIndex(int lastNavIndex) async {
    await prefs.setInt('lastNavIndex', lastNavIndex);
    this.lastNavIndex = lastNavIndex;
    notifyListeners();
  }

  Future<void> setRecentBusStopSearches(
      List<String> recentBusStopSearches) async {
    await prefs.setStringList('recentBusStopSearches', recentBusStopSearches);
    this.recentBusStopSearches = recentBusStopSearches;
    notifyListeners();
  }

  Future<void> addRecentBusStopSearch(
    String recentBusStopSearch, {
    int? index,
  }) async {
    recentBusStopSearches.removeWhere((e) => e == recentBusStopSearch);
    recentBusStopSearches.insert(index ?? 0, recentBusStopSearch);
    while (recentBusStopSearches.length > cMaxRecentBusStopSearchesSize) {
      recentBusStopSearches.removeLast();
    }
    await prefs.setStringList('recentBusStopSearches', recentBusStopSearches);
    notifyListeners();
  }

  Future<int> removeRecentBusStopSearch(String recentBusStopSearch) async {
    var index = recentBusStopSearches.indexOf(recentBusStopSearch);
    if (index >= 0) {
      recentBusStopSearches.removeAt(index);
      await prefs.setStringList('recentBusStopSearches', recentBusStopSearches);
      notifyListeners();
    }
    return index;
  }

  Future<void> setMapPosition({
    required double centerLat,
    required double centerLon,
    required double zoom,
  }) async {
    if (lastMapCenterLat != centerLat ||
        lastMapCenterLon != centerLon ||
        lastMapZoom != zoom) {
      await prefs.setDouble('lastMapCenterLat', centerLat);
      await prefs.setDouble('lastMapCenterLon', centerLon);
      await prefs.setDouble('lastMapZoom', zoom);
      lastMapCenterLat = centerLat;
      lastMapCenterLon = centerLon;
      lastMapZoom = zoom;
      notifyListeners();
    }
  }

  Future<void> setLastDataSyncDate(DateTime? lastDataSyncDate) async {
    if (this.lastDataSyncDate != lastDataSyncDate) {
      if (lastDataSyncDate != null) {
        await prefs.setInt(
            'lastDataSyncDate', lastDataSyncDate.millisecondsSinceEpoch);
      } else {
        await prefs.remove('lastDataSyncDate');
      }
      this.lastDataSyncDate = lastDataSyncDate;
      notifyListeners();
    }
  }

  Future<void> restoreDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setShowMap(true);
    await setShowMyLocation(true);
    await setShowNearbyRadius(true);
    await setShowDistanceForNearbyFavs(true);
    await setShowBusStopsForSelectedBusArrival(true);
    ackTapToRefreshBusArrivals = false;
    ackDragDownToRefreshNearbyBusStops = false;
  }
}
