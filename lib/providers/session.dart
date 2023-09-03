import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'location.dart';
import '../models.dart';

class Session extends ChangeNotifier {
  double? bottomSheetHeight;
  MapController? mapController;

  bool isBottomSheetShown = false;
  BusStop? zoomToBusStop;
  BusStop? activeBusStop;
  BusArrival? activeBusArrival;
  List<BusArrival> activeBusArrivals = [];
  bool enableSearch = false;
  BusService? activeBusService;
  List<BusStop> searchedBusStops = [];
  List<BusStop> nearbyBusStops = [];
  List<BusStop> busArrivalBusStops = [];
  List<BusStop> busServiceBusStops = [];
  var searchPickMap = false;
  LatLng? searchPickMapPos;

  void setIsBottomSheetShown(bool isBottomSheetShown) {
    if (this.isBottomSheetShown != isBottomSheetShown) {
      this.isBottomSheetShown = isBottomSheetShown;
      notifyListeners();
    }
  }

  void setZoomToBusStop(BusStop? zoomToBusStop) {
    if (this.zoomToBusStop != zoomToBusStop) {
      this.zoomToBusStop = zoomToBusStop;
      notifyListeners();
    }
  }

  void setActiveBusStop(BusStop? activeBusStop) {
    if (this.activeBusStop != activeBusStop) {
      this.activeBusStop = activeBusStop;
      activeBusArrival = null;
      activeBusArrivals = [];
      notifyListeners();
    }
  }

  void setActiveBusArrival(BusArrival? activeBusArrival) {
    if (this.activeBusArrival != activeBusArrival) {
      this.activeBusArrival = activeBusArrival;
      notifyListeners();
    }
  }

  void setActiveBusArrivals(List<BusArrival> activeBusArrivals) {
    if (this.activeBusArrivals != activeBusArrivals) {
      this.activeBusArrivals = activeBusArrivals;
      notifyListeners();
    }
  }

  void setEnableSearch(bool enableSearch) {
    if (this.enableSearch != enableSearch) {
      this.enableSearch = enableSearch;
      notifyListeners();
    }
  }

  void setActiveBusService(BusService? activeBusService) {
    if (this.activeBusService != activeBusService) {
      this.activeBusService = activeBusService;
      notifyListeners();
    }
  }

  void setSearchedBusStops(List<BusStop> searchedBusStops) {
    if (this.searchedBusStops != searchedBusStops) {
      this.searchedBusStops = searchedBusStops;
      notifyListeners();
    }
  }

  void setNearbyBusStops(List<BusStop> nearbyBusStops) {
    if (this.nearbyBusStops != nearbyBusStops) {
      this.nearbyBusStops = nearbyBusStops;
      notifyListeners();
    }
  }

  void setBusArrivalBusStops(List<BusStop> busArrivalBusStops) {
    if (this.busArrivalBusStops != busArrivalBusStops) {
      this.busArrivalBusStops = busArrivalBusStops;
      notifyListeners();
    }
  }

  void setBusServiceBusStops(List<BusStop> busServiceBusStops) {
    if (this.busServiceBusStops != busServiceBusStops) {
      this.busServiceBusStops = busServiceBusStops;
      notifyListeners();
    }
  }

  void setSearchPickMap(bool searchPickMap) {
    if (this.searchPickMap != searchPickMap) {
      this.searchPickMap = searchPickMap;
      notifyListeners();
    }
  }

  void setSearchPickMapPos(LatLng? searchPickMapPos) {
    if (this.searchPickMapPos != searchPickMapPos) {
      this.searchPickMapPos = searchPickMapPos;
      notifyListeners();
    }
  }

  void fitPoint(
    double lat,
    double lon, {
    double? offset,
    bool? ignoreIfWithinMapBounds,
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
  }) {
    var offsetDeg = Location.metersToDegrees(offset ?? 200.0);
    var bounds = LatLngBounds(
      LatLng(lat - offsetDeg, lon - offsetDeg),
      LatLng(lat + offsetDeg, lon + offsetDeg),
    );
    if (ignoreIfWithinMapBounds == true &&
        mapController?.bounds?.contains(LatLng(lat, lon)) == true) {
      return;
    }
    mapController?.fitBounds(bounds, options: options);
  }

  void fitBounds(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double? offset,
    bool? ignoreIfPointsWithinMapBounds,
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
  }) {
    var minLat = min(lat1, lat2);
    var maxLat = max(lat1, lat2);
    var minLon = min(lon1, lon2);
    var maxLon = max(lon1, lon2);
    var offsetDeg = Location.metersToDegrees(offset ?? 200.0);
    var bounds = LatLngBounds(
      LatLng(maxLat + offsetDeg, minLon - offsetDeg),
      LatLng(minLat - offsetDeg, maxLon + offsetDeg),
    );
    if (ignoreIfPointsWithinMapBounds == true &&
        mapController?.bounds?.contains(LatLng(lat1, lon1)) == true &&
        mapController?.bounds?.contains(LatLng(lat2, lon2)) == true) {
      return;
    }
    mapController?.fitBounds(bounds, options: options);
  }
}
