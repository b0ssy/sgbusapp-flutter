import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Location extends ChangeNotifier {
  bool serviceEnabled = false;
  LocationPermission? permission;
  bool gettingCurrentPos = false;
  Position? currentPos;

  Location() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      setServiceEnabled(status == ServiceStatus.enabled);
      if (status == ServiceStatus.enabled) {
        setCurrentPosition();
      }
    });
    setCurrentState();
  }

  bool canGetPosition() {
    return serviceEnabled == true &&
        (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse);
  }

  void setServiceEnabled(bool serviceEnabled) {
    if (this.serviceEnabled != serviceEnabled) {
      this.serviceEnabled = serviceEnabled;
      notifyListeners();
    }
  }

  Future<void> setCurrentPosition({
    Function(Position currentPos)? onSuccess,
  }) async {
    if (!canGetPosition()) {
      return;
    }
    gettingCurrentPos = true;
    notifyListeners();
    var success = false;
    try {
      currentPos = await Geolocator.getCurrentPosition();
      success = true;
    } catch (ex) {
      // Ignore exception
    }
    gettingCurrentPos = false;
    if (onSuccess != null && success && currentPos != null) {
      onSuccess(currentPos!);
    }
    notifyListeners();
  }

  Future<void> setCurrentState() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    notifyListeners();
  }

  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    this.permission = permission;
    notifyListeners();
  }

  static double degreesToMeters(double deg) {
    return deg * 111139;
  }

  static double metersToDegrees(double meters) {
    return meters / 111139;
  }
}
