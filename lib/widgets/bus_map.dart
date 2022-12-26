import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bus_arrivals.dart';
import '../models.dart';
import '../preferences.dart';
import '../providers/location.dart';
import '../providers/session.dart';
import '../utils/utils.dart';

class BusMap extends StatefulWidget {
  final bool? showMyLocation;
  final double? zoomToRadius;

  const BusMap({
    Key? key,
    this.showMyLocation,
    this.zoomToRadius,
  }) : super(key: key);

  @override
  State<BusMap> createState() => _BusMapState();
}

class _BusMapState extends State<BusMap> {
  final _mapController = MapController();
  DateTime? _mapCreatedTime;
  Timer? _saveMapPosTimer;

  @override
  Widget build(BuildContext context) {
    var lastNavIndex = Provider.of<Preferences>(context).lastNavIndex;
    var maxNearbyDistance = Provider.of<Preferences>(context).maxNearbyDistance;
    var serviceEnabled = Provider.of<Location>(context).serviceEnabled;
    var canGetPosition = Provider.of<Location>(context).canGetPosition();
    var currentPos = Provider.of<Location>(context).currentPos;
    var gettingCurrentPos = Provider.of<Location>(context).gettingCurrentPos;
    var activeBusStop = Provider.of<Session>(context).activeBusStop;
    var activeBusArrivals = Provider.of<Session>(context).activeBusArrivals;
    var activeBusArrival = Provider.of<Session>(context).activeBusArrival;
    var activeBusArrivalNextBus =
        Provider.of<Session>(context).activeBusArrival?.nextBus;
    var lastMapCenterLat =
        Provider.of<Preferences>(context).lastMapCenterLat ?? 1.362109;
    var lastMapCenterLon =
        Provider.of<Preferences>(context).lastMapCenterLon ?? 103.827732;
    var lastMapZoom = Provider.of<Preferences>(context).lastMapZoom ?? 10.0;
    var busStops = _getBusStops();
    var showBusStopIndex = busStops.where((e) => e.uiIndex != null).isNotEmpty;
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
              center: LatLng(lastMapCenterLat, lastMapCenterLon),
              zoom: lastMapZoom,

              // No more OSM tiles after this zoom level
              maxZoom: 18.0,
              interactiveFlags: InteractiveFlag.pinchMove |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
              onMapCreated: (MapController mapController) =>
                  _handleMapCreated(mapController),
              onPositionChanged: (MapPosition mapPosition, _) {
                _saveMapPosTimer?.cancel();
                _saveMapPosTimer = Timer(const Duration(seconds: 1), () async {
                  Provider.of<Preferences>(context, listen: false)
                      .setMapPosition(
                    centerLat: _mapController.center.latitude,
                    centerLon: _mapController.center.longitude,
                    zoom: _mapController.zoom,
                  );
                });
              },
              onTap: (tapPosition, point) {
                if (Provider.of<Session>(context, listen: false)
                        .searchPickMap &&
                    Provider.of<Preferences>(context, listen: false)
                            .lastNavIndex ==
                        cFavPageNavIndex &&
                    Provider.of<Session>(context, listen: false).enableSearch &&
                    Provider.of<Session>(context, listen: false)
                            .activeBusStop ==
                        null) {
                  Provider.of<Session>(context, listen: false)
                      .setSearchPickMapPos(point);
                  _searchBusStopsFromPos(point.latitude, point.longitude);
                }
              }),
          layers: [
            // OSM base layer
            TileLayerOptions(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.app',
            ),

            // Current location marker in nearby page
            if (lastNavIndex == cNearbyPageNavIndex &&
                widget.showMyLocation == true &&
                currentPos != null)
              CircleLayerOptions(
                circles: [
                  CircleMarker(
                    point: LatLng(currentPos.latitude, currentPos.longitude),
                    radius: 7.5,
                    color: serviceEnabled && !gettingCurrentPos
                        ? Colors.blue
                        : Colors.grey,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

            // Search nearby radius
            if (Provider.of<Session>(context).searchPickMap &&
                Provider.of<Session>(context).searchPickMapPos != null &&
                Provider.of<Session>(context).enableSearch &&
                lastNavIndex == cFavPageNavIndex)
              CircleLayerOptions(
                circles: [
                  CircleMarker(
                    point: LatLng(
                        Provider.of<Session>(context)
                            .searchPickMapPos!
                            .latitude,
                        Provider.of<Session>(context)
                            .searchPickMapPos!
                            .longitude),
                    radius: maxNearbyDistance,
                    color: Colors.grey.withOpacity(0.25),
                    borderColor: Colors.grey,
                    borderStrokeWidth: 2.5,
                    useRadiusInMeter: true,
                  ),
                ],
              ),

            // Nearby radius
            if (Provider.of<Preferences>(context).showNearbyRadius &&
                lastNavIndex == cNearbyPageNavIndex &&
                currentPos != null &&
                Provider.of<Session>(context).activeBusStop == null)
              CircleLayerOptions(
                circles: [
                  CircleMarker(
                    point: LatLng(currentPos.latitude, currentPos.longitude),
                    radius: maxNearbyDistance,
                    color: Colors.grey.withOpacity(0.25),
                    borderColor: Colors.grey,
                    borderStrokeWidth: 2.5,
                    useRadiusInMeter: true,
                  ),
                ],
              ),

            // Bus stops
            for (var i = 0; i < busStops.length; i++)
              ..._buildBusStopLayer(
                busStop: busStops[i],
                showBusStopIndex: showBusStopIndex,
                activeBusStop: activeBusStop,
              ),

            // Active bus arrivals
            for (var activeBusArrival in activeBusArrivals)
              ..._buildBusArrivalLayer(activeBusArrival),

            // Active bus arrival next bus
            if (activeBusArrival != null &&
                activeBusArrivalNextBus != null &&
                activeBusArrivalNextBus.latitude != null &&
                activeBusArrivalNextBus.longitude != null)
              ..._buildBusArrivalLayer(activeBusArrival),
          ],
        ),

        // Show current position
        if (lastNavIndex == cNearbyPageNavIndex &&
            widget.showMyLocation == true)
          Positioned(
            bottom: 5.0,
            right: 5.0,
            child: FloatingActionButton(
              heroTag: 'BusMap.ZoomToCurrentPosition',
              child: Icon(
                Icons.gps_fixed,
                color: !canGetPosition ? Theme.of(context).disabledColor : null,
              ),
              onPressed: () => _zoomToCurrentPos(),
            ),
          ),

        // Credit OpenStreetMap
        Positioned(
          top: 5.0,
          right: 5.0,
          child: Opacity(
            opacity: 0.75,
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '© ',
                        style: TextStyle(color: Colors.black, fontSize: 10.0),
                      ),
                      TextSpan(
                        text: 'OpenStreetMap',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10.0,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _launchOpenStreetMapUrl(),
                      ),
                      const TextSpan(
                        text: ' contributors',
                        style: TextStyle(color: Colors.black, fontSize: 10.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _buildBusArrivalLayer(BusArrival busArrival) {
    var busArrivalParsed = busArrival.parse(
      context,
      brightness: Brightness.light,
    );
    var busArrivalNextBus = busArrival.nextBus;
    var lat = busArrivalNextBus?.latitude;
    var lon = busArrivalNextBus?.longitude;
    var latLng = lat != null && lon != null ? LatLng(lat, lon) : null;
    return [
      if (latLng != null)
        MarkerLayerOptions(
          markers: [
            _buildCircleMarker(
              latLng: latLng,
              outerColor: busArrivalParsed[1] ?? Colors.white,
              innerColor: Colors.white,
            ),
            Marker(
              point: latLng,
              anchorPos: AnchorPos.align(AnchorAlign.center),
              builder: (context) => const Icon(
                Icons.directions_bus,
                color: Colors.black,
                size: 14.0,
              ),
            ),
            Marker(
              point: latLng,
              width: 110.0,
              height: 75.0,
              anchorPos: AnchorPos.exactly(Anchor(55.0, -10.0)),
              builder: (context) => _BusArrivalInfo(
                busArrival: busArrival,
              ),
            ),
          ],
        ),
    ];
  }

  _buildBusStopLayer({
    required BusStop busStop,
    BusStop? activeBusStop,
    required bool showBusStopIndex,
  }) {
    return [
      if (busStop.latitude != null && busStop.longitude != null)
        MarkerLayerOptions(
          markers: [
            Marker(
              point: LatLng(busStop.latitude!, busStop.longitude!),
              width: showBusStopIndex ? 30.0 : 20.0,
              height: showBusStopIndex ? 30.0 : 20.0,
              builder: (context) => GestureDetector(
                child: Opacity(
                  opacity: activeBusStop == null || activeBusStop == busStop
                      ? 1.0
                      : 0.25,
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 16.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: showBusStopIndex ? 12.0 : 8.0,
                          child: showBusStopIndex && busStop.uiIndex != null
                              ? Text(
                                  '${busStop.uiIndex!}',
                                  style: const TextStyle(fontSize: 12.0),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  if (Provider.of<Session>(context, listen: false)
                          .activeBusStop ==
                      busStop) {
                    return;
                  }
                  showBusArrivalsBottomSheet(
                    context: context,
                    variant: BusArrivalsVariant.home,
                    busStop: busStop,
                  );
                },
              ),
            ),
          ],
        ),
    ];
  }

  _buildCircleMarker({
    required LatLng latLng,
    double width = 20.0,
    double height = 20.0,
    double outerRadius = 20.0,
    double innerRadius = 8.0,
    Color? outerColor,
    Color? innerColor,
  }) {
    return Marker(
      point: latLng,
      width: width,
      height: height,
      builder: (context) => Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: outerRadius,
              backgroundColor: outerColor,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: innerRadius,
              backgroundColor: innerColor,
            ),
          ),
        ],
      ),
    );
  }

  List<BusStop> _getBusStops() {
    List<BusStop> busStops = [];
    var lastNavIndex = Provider.of<Preferences>(context).lastNavIndex;
    if (lastNavIndex == cFavPageNavIndex) {
      if (Provider.of<Session>(context).enableSearch) {
        busStops = Provider.of<Session>(context).searchedBusStops;
      } else {
        var busStopsByBusStopCode =
            Provider.of<Preferences>(context).busStopsByBusStopCode;
        busStops = Provider.of<Preferences>(context)
            .favBusStops
            .where((e) => busStopsByBusStopCode.containsKey(e.busStopCode))
            .map((e) => busStopsByBusStopCode[e.busStopCode]!)
            .toList();
        BusStop.setUiIndex(busStops);
      }
    } else if (lastNavIndex == cNearbyPageNavIndex) {
      busStops = Provider.of<Session>(context).nearbyBusStops;
    } else if (lastNavIndex == cBusesPageNavIndex) {
      busStops = Provider.of<Session>(context).busServiceBusStops;
    }

    // If zoomToBusStop exists, then move it to the last
    // This ensures it will be always on top of the rest
    var zoomToBusStop = Provider.of<Session>(context).zoomToBusStop;
    if (zoomToBusStop != null && busStops.contains(zoomToBusStop)) {
      busStops = busStops.where((e) => e != zoomToBusStop).toList();
      busStops.add(zoomToBusStop);
    }

    // If activeBusStop exists, then move it to the last
    // This ensures it will be always on top of the rest
    var activeBusStop = Provider.of<Session>(context).activeBusStop;
    if (activeBusStop != null) {
      busStops = busStops.where((e) => e != activeBusStop).toList();
      busStops.add(activeBusStop);
    }

    return busStops;
  }

  _handleMapCreated(MapController mapController) {
    Provider.of<Session>(context, listen: false).mapController = mapController;
    var currentPos = Provider.of<Location>(context, listen: false).currentPos;
    if (widget.showMyLocation == true) {
      if (currentPos != null) {
        _zoomTo(currentPos.latitude, currentPos.longitude);
      } else {
        _mapCreatedTime = DateTime.now();
        Provider.of<Location>(context, listen: false)
            .addListener(_zoomToCurrentPosOnMapCreated);
      }
    }
  }

  _zoomTo(double lat, double lon) {
    var offsetDeg = Location.metersToDegrees(widget.zoomToRadius ?? 250.0);
    var bounds = LatLngBounds(
      LatLng(lat - offsetDeg, lon - offsetDeg),
      LatLng(lat + offsetDeg, lon + offsetDeg),
    );
    _mapController.fitBounds(bounds);
  }

  _zoomToCurrentPosOnMapCreated() {
    if (_mapCreatedTime == null) {
      return;
    }
    if (DateTime.now().difference(_mapCreatedTime!).inSeconds > 3) {
      if (mounted) {
        Provider.of<Location>(context, listen: false)
            .removeListener(_zoomToCurrentPosOnMapCreated);
      }
      return;
    }
    if (Provider.of<Preferences>(context, listen: false).lastNavIndex != 1) {
      return;
    }
    var currentPos = Provider.of<Location>(context, listen: false).currentPos;
    if (currentPos != null) {
      _zoomTo(currentPos.latitude, currentPos.longitude);
    }
  }

  _zoomToCurrentPos() async {
    var loc = Provider.of<Location>(context, listen: false);
    if (!loc.serviceEnabled) {
      showMessageDialog(
        context: context,
        title: 'Please turn on location service',
      );
      return;
    }

    // Immediately zoom to last known location first
    var currentPos = loc.currentPos;
    if (currentPos != null) {
      _zoomTo(currentPos.latitude, currentPos.longitude);
    }

    // Then set current position again
    loc.setCurrentPosition();
  }

  _launchOpenStreetMapUrl() async {
    if (!await showYesCancelDialog(
      context: context,
      title: 'View OpenStreetMap Webpage?',
      yesText: 'Yes',
    )) {
      return;
    }
    var uri = Uri.parse('https://www.openstreetmap.org/copyright');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showSnackBar(context, 'Failed to open webpage');
    }
  }

  _searchBusStopsFromPos(double lat, double lon) async {
    var maxNearbyDistance =
        Provider.of<Preferences>(context, listen: false).maxNearbyDistance;
    var offsetDeg = Location.metersToDegrees(maxNearbyDistance);
    var minLat = lat - offsetDeg;
    var maxLat = lat + offsetDeg;
    var minLon = lon - offsetDeg;
    var maxLon = lon + offsetDeg;
    var busStops = await Provider.of<Preferences>(context, listen: false)
        .database
        .searchNearbyBusStops(minLat, maxLat, minLon, maxLon);
    // The search results may get bus stops >= maxDistance
    // So we filter away them here
    busStops = busStops
        .where((b) =>
            Geolocator.distanceBetween(
              lat,
              lon,
              b.latitude ?? 0.0,
              b.longitude ?? 0.0,
            ) <=
            maxNearbyDistance)
        .toList();
    BusStop.setUiIndex(busStops);
    Provider.of<Session>(context, listen: false).setSearchedBusStops(busStops);
  }
}

class _BusArrivalInfo extends StatefulWidget {
  final BusArrival busArrival;

  const _BusArrivalInfo({
    Key? key,
    required this.busArrival,
  }) : super(key: key);

  @override
  State<_BusArrivalInfo> createState() => _BusArrivalInfoState();
}

class _BusArrivalInfoState extends State<_BusArrivalInfo> {
  int _lastUpdateSecs = 0;
  Timer? _lastUpdateTimer;

  @override
  void initState() {
    super.initState();

    _lastUpdateSecs =
        DateTime.now().difference(widget.busArrival.time).inSeconds;

    // Auto-refresh the last update time
    _lastUpdateTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        setState(() {
          _lastUpdateSecs =
              DateTime.now().difference(widget.busArrival.time).inSeconds;
        });
      },
    );
  }

  @override
  void dispose() {
    _lastUpdateTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var busArrivalParsed = widget.busArrival.parse(
      context,
      brightness: Brightness.light,
    );
    var showLastUpdate = _lastUpdateSecs >= 60;
    return Column(
      children: [
        if (!showLastUpdate) const SizedBox(height: 20.0),
        Expanded(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 2.0, left: 4.0, bottom: 0.0, right: 4.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.busArrival.serviceNo ?? '?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${busArrivalParsed[0][0]}',
                              style: TextStyle(
                                color: busArrivalParsed[1],
                                fontSize: 16.0,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.busArrival.nextBus?.type == 'SD'
                                      ? 'single'
                                      : widget.busArrival.nextBus?.type == 'DD'
                                          ? 'double'
                                          : '',
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    color: Colors.black,
                                  ),
                                ),
                                if (widget.busArrival.nextBus?.feature == 'WAB')
                                  const Icon(
                                    Icons.accessible,
                                    size: 12.0,
                                    color: Colors.black,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showLastUpdate)
                    Expanded(
                      child: Center(
                        child: Text(
                          'updated ${_lastUpdateSecs ~/ 60}m ago',
                          style: const TextStyle(
                            fontSize: 10.0,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
