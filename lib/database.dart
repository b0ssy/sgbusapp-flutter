import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'models.dart';

typedef OnCreateDatabaseCallback = Future<void> Function(Database db);

const cDatabaseVersion = 1;

class Database {
  sqflite.Database? _db;

  sqflite.Database? get() {
    return _db;
  }

  Future<void> open({OnCreateDatabaseCallback? onCreateCallback}) async {
    debugPrint('Opening database...');
    var databasesPath = await sqflite.getDatabasesPath();
    String path = join(databasesPath, 'sgbusapp.db');
    var createdTables = false;
    _db = await sqflite.openDatabase(
      path,
      version: cDatabaseVersion,
      onCreate: (sqflite.Database db, int version) async {
        debugPrint('Creating new database...');
        await _createTables(db);
        createdTables = true;
        debugPrint('Created new database successfully');
      },
      onUpgrade: (sqflite.Database db, int oldVersion, int newVersion) async {
        debugPrint('Upgrading database...');
        await _dropTables(db);
        await _createTables(db);
        createdTables = true;
        debugPrint('Upgraded database successfully');
      },
      onDowngrade: (sqflite.Database db, int oldVersion, int newVersion) async {
        debugPrint('Downgrading database...');
        await _dropTables(db);
        await _createTables(db);
        createdTables = true;
        debugPrint('Downgraded database successfully');
      },
    );
    if (createdTables && onCreateCallback != null) {
      debugPrint('Inserting rows...');
      await onCreateCallback(this);
      debugPrint('Inserted rows successfully');
    }
    debugPrint('Opened database successfully');
  }

  Future<void> close() async {
    debugPrint('Closing database...');
    await _db?.close();
    debugPrint('Closed database successfully');
  }

  Future<List<BusStop>> searchBusStops(
    String searchText, {
    int limit = 20,
  }) async {
    List<BusStop> busStops = [];
    var db = _db;
    if (db != null) {
      List<Map<String, dynamic>> busStopResults = await db.rawQuery(
        'SELECT * FROM BusStop '
        'WHERE bus_stop_code like ? '
        'OR road_name like ? '
        'OR description like ? '
        'LIMIT ?',
        [
          '%$searchText%',
          '%$searchText%',
          '%$searchText%',
          limit,
        ],
      );
      busStops = busStopResults.map((e) => BusStop.fromMap(e)).toList();
    }
    return busStops;
  }

  Future<List<BusStop>> searchNearbyBusStops(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 20,
  }) async {
    List<BusStop> busStops = [];
    var db = _db;
    if (db != null) {
      List<Map<String, dynamic>> busStopResults = await db.rawQuery(
        'SELECT * FROM BusStop '
        'WHERE latitude BETWEEN ? AND ? '
        'AND longitude BETWEEN ? AND ? '
        'LIMIT ?',
        [minLat, maxLat, minLon, maxLon, limit],
      );
      busStops = busStopResults.map((e) => BusStop.fromMap(e)).toList();
    }
    return busStops;
  }

  Future<List<BusStop>> getBusStopsForBusService(
    String serviceNo,
    int direction,
  ) async {
    List<BusStop> busStops = [];
    var db = _db;
    if (db != null) {
      List<Map<String, dynamic>> busStopResults = await db.rawQuery(
        'SELECT BusStop.* FROM BusStop '
        'INNER JOIN BusRoute ON BusStop.bus_stop_code = BusRoute.bus_stop_code '
        'WHERE BusRoute.service_no = ? '
        'AND BusRoute.direction = ? ',
        [serviceNo, direction],
      );
      busStops = busStopResults.map((e) => BusStop.fromMap(e)).toList();
    }
    return busStops;
  }

  Future<List<BusService>> getBusServices({
    int? direction,
  }) async {
    List<BusService> busServices = [];
    var db = _db;
    if (db != null) {
      String sql = 'SELECT * FROM BusService ';
      List<Object?> arguments = [];
      if (direction != null) {
        sql += 'WHERE direction = ? ';
        arguments.add(direction);
      }
      List<Map<String, dynamic>> busServiceResults = await db.rawQuery(
        sql,
        arguments,
      );
      busServices =
          busServiceResults.map((e) => BusService.fromMap(e)).toList();
      busServices.sort(BusService.sortByServiceNo);
    }
    return busServices;
  }

  Future<List<MrtStation>> getMrtStations() async {
    List<MrtStation> stations = [];
    var db = _db;
    if (db != null) {
      String sql = 'SELECT * FROM MrtStation ';
      List<Map<String, dynamic>> stationsResults = await db.rawQuery(sql);
      stations = stationsResults.map((e) => MrtStation.fromMap(e)).toList();
    }
    return stations;
  }

  Future<List<BusService>> getBusServicesForBusStop(String busStopCode) async {
    List<BusService> busServices = [];
    var db = _db;
    if (db != null) {
      List<Map<String, dynamic>> busServiceResults = await db.rawQuery(
        'SELECT BusService.* '
        'FROM BusService '
        'INNER JOIN BusRoute '
        'ON BusService.service_no = BusRoute.service_no '
        'WHERE BusService.direction = 1 AND BusRoute.bus_stop_code = ?',
        [busStopCode],
      );
      busServices =
          busServiceResults.map((e) => BusService.fromMap(e)).toList();

      // Remove duplicates
      Set<String?> serviceNoSet = {};
      busServices = busServices.where((e) {
        if (serviceNoSet.contains(e.serviceNo)) {
          return false;
        }
        serviceNoSet.add(e.serviceNo);
        return true;
      }).toList();

      busServices.sort(BusService.sortByServiceNo);
    }
    return busServices;
  }

  Future<List<BusRoute>> getBusRoutesForBusStop(String busStopCode) async {
    List<BusRoute> busRoutes = [];
    var db = _db;
    if (db != null) {
      List<Map<String, dynamic>> busRouteResults = await db.rawQuery(
        'SELECT * '
        'FROM BusRoute '
        'WHERE bus_stop_code = ?',
        [busStopCode],
      );
      busRoutes = busRouteResults.map((e) => BusRoute.fromMap(e)).toList();
    }
    return busRoutes;
  }

  Future<void> updateBusServices(List<BusService> busServices) async {
    debugPrint('Updating ${busServices.length} bus services...');
    var db = _db;
    if (db == null) {
      return;
    }
    var batch = db.batch();
    batch.delete('BusService');
    for (var element in busServices) {
      batch.insert('BusService', element.toMap());
    }
    await batch.commit(noResult: true);
    debugPrint('Updated ${busServices.length} bus services successfully');
  }

  Future<void> updateBusStops(List<BusStop> busStops) async {
    debugPrint('Updating ${busStops.length} bus stops...');
    var db = _db;
    if (db == null) {
      return;
    }
    var batch = db.batch();
    batch.delete('BusStop');
    for (var element in busStops) {
      batch.insert('BusStop', element.toMap());
    }
    await batch.commit(noResult: true);
    debugPrint('Updated ${busStops.length} bus stops successfully');
  }

  Future<void> updateBusRoutes(List<BusRoute> busRoutes) async {
    debugPrint('Updating ${busRoutes.length} bus routes...');
    var db = _db;
    if (db == null) {
      return;
    }
    var batch = db.batch();
    batch.delete('BusRoute');
    for (var element in busRoutes) {
      batch.insert('BusRoute', element.toMap());
    }
    await batch.commit(noResult: true);
    debugPrint('Updated ${busRoutes.length} bus routes successfully');
  }

  Future<void> updateMrtStations(List<MrtStation> mrtStations) async {
    debugPrint('Updating ${mrtStations.length} mrt stations...');
    var db = _db;
    if (db == null) {
      return;
    }
    var batch = db.batch();
    batch.delete('MrtStation');
    for (var element in mrtStations) {
      batch.insert('MrtStation', element.toMap());
    }
    await batch.commit(noResult: true);
    debugPrint('Updated ${mrtStations.length} mrt stations successfully');
  }

  _createTables(sqflite.Database db) async {
    await db.execute('CREATE TABLE BusService '
        '(id INTEGER PRIMARY KEY'
        ',service_no TEXT'
        ',operator TEXT'
        ',direction INTEGER'
        ',category TEXT'
        ',origin_code TEXT'
        ',destination_code TEXT'
        ',am_peak_freq TEXT'
        ',am_offpeak_freq TEXT'
        ',pm_peak_freq TEXT'
        ',pm_offpeak_freq TEXT'
        ',loop_desc TEXT'
        ')');
    await db.execute('CREATE TABLE BusStop '
        '(id INTEGER PRIMARY KEY'
        ',bus_stop_code TEXT'
        ',road_name TEXT'
        ',description TEXT'
        ',latitude REAL'
        ',longitude REAL'
        ')');
    await db.execute('CREATE TABLE BusRoute '
        '(id INTEGER PRIMARY KEY'
        ',service_no TEXT'
        ',operator TEXT'
        ',direction INTEGER'
        ',stop_sequence INTEGER'
        ',bus_stop_code TEXT'
        ',distance REAL'
        ',wd_first_bus TEXT'
        ',wd_last_bus TEXT'
        ',sat_first_bus TEXT'
        ',sat_last_bus TEXT'
        ',sun_first_bus TEXT'
        ',sun_last_bus TEXT'
        ')');
    await db.execute('CREATE TABLE MrtStation '
        '(id INTEGER PRIMARY KEY'
        ',object_id TEXT'
        ',stn_name TEXT'
        ',stn_no TEXT'
        ',x REAL'
        ',y REAL'
        ',latitude REAL'
        ',longitude REAL'
        ',color TEXT'
        ')');
  }

  _dropTables(sqflite.Database db) async {
    await db.execute('DROP TABLE IF EXISTS BusService');
    await db.execute('DROP TABLE IF EXISTS BusStop');
    await db.execute('DROP TABLE IF EXISTS BusRoute');
    await db.execute('DROP TABLE IF EXISTS MrtStation');
  }
}
