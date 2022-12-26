import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import 'ack.dart';
import 'bus_stop_tile.dart';
import '../models.dart';
import '../preferences.dart';
import '../providers/location.dart';
import '../providers/session.dart';
import '../utils/utils.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({Key? key}) : super(key: key);

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  bool _searching = false;
  List<BusStop> _busStops = [];

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  void dispose() {
    _serviceStatusStream?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_busStops.isEmpty) {
      // Request user to turn on location service
      if (Provider.of<Location>(context).serviceEnabled != true) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Please turn on location service',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  Geolocator.openLocationSettings().then((openSuccess) {
                    if (!openSuccess) {
                      showSnackBar(context, 'Failed to open location settings');
                    }
                  });
                },
                child: const Text('Open Location Settings'),
              ),
            ),
          ],
        );
      }

      // Request user to allow app to access location
      if (Provider.of<Location>(context).permission ==
          LocationPermission.denied) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Please allow app to access location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  Provider.of<Location>(context, listen: false)
                      .requestPermission();
                },
                child: const Text('Allow Access to Location'),
              ),
            ),
          ],
        );
      }

      // Request user to go to settings to allow app to access location
      if (Provider.of<Location>(context).permission ==
          LocationPermission.deniedForever) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Please allow app to access location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  Geolocator.openAppSettings().then((openSuccess) {
                    if (!openSuccess) {
                      showSnackBar(context, 'Failed to open app settings');
                    }
                  });
                },
                child: const Text('Open App Settings'),
              ),
            ),
          ],
        );
      }
    }

    // Sort by distance in ascending order
    var busStops = [..._busStops];

    // Display bus stops
    return Column(
      children: [
        if (!_searching && busStops.isEmpty)
          const SizedBox(
            height: 36.0,
            child: Center(
              child: Text(
                'No nearby bus stops found',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (!_searching) ...[
                      for (var i = 0; i < busStops.length; i++)
                        Column(
                          children: [
                            BusStopTile(
                              variant: BusStopTileVariant.nearby,
                              busStop: busStops[i],
                              showDistanceChip: true,
                            ),
                            const Divider(height: 1.0, thickness: 1.0),
                          ],
                        ),
                      // Create empty "placeholders" so the refresh indicator
                      // can still be pulled if there are not enough bus stops
                      for (var i = 0; i < 5 - busStops.length; i++)
                        const Opacity(
                          opacity: 0.0,
                          child: ListTile(),
                        ),
                    ] else ...[
                      for (var i = 0;
                          i < (busStops.isNotEmpty ? busStops.length : 5);
                          i++) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 18.0,
                            bottom: 16.0,
                            left: 16.0,
                            right: 16.0,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 16.0,
                                child: Skeleton(
                                  isLoading: true,
                                  skeleton: const SkeletonLine(
                                    style: SkeletonLineStyle(
                                      width: 200.0,
                                      height: 16.0,
                                    ),
                                  ),
                                  child: Container(),
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              SizedBox(
                                height: 16.0,
                                child: Skeleton(
                                  isLoading: true,
                                  skeleton: const SkeletonLine(
                                    style: SkeletonLineStyle(
                                      width: 115.0,
                                      height: 16.0,
                                    ),
                                  ),
                                  child: Container(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1.0,
                          thickness: 1.0,
                          color: Colors.transparent,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              onRefresh: () =>
                  _searchNearbyBusStops(showMessageToTurnOnLocation: true)),
        ),
        if (!Provider.of<Preferences>(context)
            .ackDragDownToRefreshNearbyBusStops)
          Ack(
            title: 'Drag down to refresh',
            onPressed: () {
              Provider.of<Preferences>(context, listen: false)
                  .setAckDragDownToRefreshNearbyBusStops(true);
            },
          ),
      ],
    );
  }

  _searchNearbyBusStops({bool? showMessageToTurnOnLocation}) async {
    if (!Provider.of<Location>(context, listen: false).canGetPosition()) {
      if (showMessageToTurnOnLocation == true) {
        showMessageDialog(
          context: context,
          title: 'Please turn on location service',
        );
      }
      return;
    }

    setState(() {
      _searching = true;
    });
    var wait = Wait(duration: const Duration(milliseconds: 500));
    await Provider.of<Location>(context, listen: false).setCurrentPosition();
    if (!mounted) {
      return;
    }
    List<BusStop> busStops = [];
    var pos = Provider.of<Location>(context, listen: false).currentPos;
    if (pos != null) {
      var maxNearbyDistance =
          Provider.of<Preferences>(context, listen: false).maxNearbyDistance;
      var offsetDeg = Location.metersToDegrees(maxNearbyDistance);
      var minLat = pos.latitude - offsetDeg;
      var maxLat = pos.latitude + offsetDeg;
      var minLon = pos.longitude - offsetDeg;
      var maxLon = pos.longitude + offsetDeg;
      busStops = await Provider.of<Preferences>(context, listen: false)
          .database
          .searchNearbyBusStops(minLat, maxLat, minLon, maxLon);
      // The search results may get bus stops >= maxDistance
      // So we filter away them here
      busStops = busStops
          .where((b) =>
              Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                b.latitude ?? 0.0,
                b.longitude ?? 0.0,
              ) <=
              maxNearbyDistance)
          .toList();
      // Sort bus stops by distance from current pos
      busStops.sort((b1, b2) {
        double b1Distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          b1.latitude ?? 0.0,
          b1.longitude ?? 0.0,
        );
        double b2Distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          b2.latitude ?? 0.0,
          b2.longitude ?? 0.0,
        );
        if (b1Distance < b2Distance) {
          return -1;
        }
        if (b1Distance > b2Distance) {
          return 1;
        }
        return 0;
      });
      BusStop.setUiIndex(busStops);
    }
    await wait.wait();
    if (!mounted) {
      return;
    }
    Provider.of<Session>(context, listen: false).setNearbyBusStops(busStops);
    if (pos != null &&
        Provider.of<Preferences>(context, listen: false).lastNavIndex ==
            cNearbyPageNavIndex) {
      Provider.of<Session>(context, listen: false)
          .fitPoint(pos.latitude, pos.longitude);
    }
    setState(() {
      _searching = false;
      _busStops = busStops;
    });
  }

  _initialize() async {
    _serviceStatusStream =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      Provider.of<Location>(context, listen: false)
          .setServiceEnabled(status == ServiceStatus.enabled);
      _searchNearbyBusStops();
    });
    await Provider.of<Location>(context, listen: false).requestPermission();
    await Provider.of<Location>(context, listen: false).setCurrentState();
    _searchNearbyBusStops();
  }
}
