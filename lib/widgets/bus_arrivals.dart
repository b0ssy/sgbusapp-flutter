import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import 'ack.dart';
import '../models.dart';
import '../preferences.dart';
import '../providers/session.dart';
import '../utils/datamall_api.dart';
import '../utils/utils.dart';
import '../widgets/bus_stop_tile.dart';

enum BusArrivalsVariant {
  home,
  search,
}

class BusArrivals extends StatefulWidget {
  final BusArrivalsVariant variant;
  final BusStop busStop;
  final String? altDescription;
  final Function onClose;

  const BusArrivals({
    Key? key,
    required this.variant,
    required this.busStop,
    this.altDescription,
    required this.onClose,
  }) : super(key: key);

  @override
  _BusArrivalsState createState() => _BusArrivalsState();
}

class _BusArrivalsState extends State<BusArrivals> {
  final _firstFavBusServiceKey = GlobalKey();
  bool _showInfo = false;
  var _loading = false;
  List<BusService> _busServices = [];
  Map<String, BusArrival> _busArrivalMap = {};
  Map<String, BusRoute> _busRouteMap = {};

  @override
  void initState() {
    super.initState();

    _zoomTo(false);
    _update(fitBounds: true);
  }

  @override
  void didUpdateWidget(covariant BusArrivals oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.busStop != oldWidget.busStop) {
      _update(fitBounds: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    var ackTapToRefreshBusArrivals =
        Provider.of<Preferences>(context).ackTapToRefreshBusArrivals;
    var favBusStop = Provider.of<Preferences>(context)
        .favBusStops
        .firstWhereOrNull((e) => e.busStopCode == widget.busStop.busStopCode);
    var showFavServiceNos = favBusStop?.showFavServiceNos == true;
    showFavServiceNos = false;

    var operatingBusServices = _busServices
        .where((e) =>
            _busArrivalMap[e.serviceNo] != null &&
            (!showFavServiceNos ||
                favBusStop?.favServiceNos?.contains(e.serviceNo) == true))
        .toList();
    var nonOperatingBusServices = _busServices
        .where((e) =>
            _busArrivalMap[e.serviceNo] == null &&
            (!showFavServiceNos ||
                favBusStop?.favServiceNos?.contains(e.serviceNo) == true))
        .toList();

    BusService? firstFavBusService = operatingBusServices.firstWhereOrNull(
        (e) => e.serviceNo != null && _isServiceNoFav(e.serviceNo!));
    return Column(
      children: [
        Container(
          height: 1.0,
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        Stack(
          children: [
            BusStopTile(
              variant: BusStopTileVariant.arrival,
              busStop: widget.busStop,
              altDescription: widget.altDescription,
              // backgroundColor: Theme.of(context).colorScheme.surface,
              trailing: [
                // if (Provider.of<Preferences>(context).showMap)
                //   GestureDetector(
                //     child: const Icon(
                //       Icons.location_searching,
                //       size: 26.0,
                //     ),
                //     onTap: () => _zoomTo(false),
                //   ),
                // TextButton(
                //   child: Text(!_showInfo ? 'SHOW INFO' : 'HIDE INFO'),
                //   onPressed: () {
                //     setState(() {
                //       _showInfo = !_showInfo;
                //     });
                //   },
                // ),
                GestureDetector(
                  child: Icon(
                    Icons.info,
                    size: 26.0,
                    color: _showInfo
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onTap: () {
                    setState(() {
                      _showInfo = !_showInfo;
                    });
                  },
                ),
                GestureDetector(
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 26.0,
                  ),
                  onTap: () => widget.onClose(),
                ),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  width: 40.0,
                  height: 3.0,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            ),
          ],
        ),
        // Center(
        //   child: SizedBox(
        //     width: 350.0,
        //     child: Column(
        //       children: [
        //         ListTile(
        //           contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
        //           title: Text(
        //             widget.altDescription ??
        //                 widget.busStop.description ??
        //                 'N/A',
        //             maxLines: 1,
        //             style: TextStyle(
        //               fontWeight: FontWeight.bold,
        //               fontStyle: widget.altDescription?.isNotEmpty == true
        //                   ? FontStyle.italic
        //                   : null,
        //             ),
        //           ),
        //           subtitle: Row(
        //             children: [
        //               SizedBox(
        //                 width: 50.0,
        //                 child: Text(
        //                   widget.busStop.busStopCode ?? 'N/A',
        //                   style: const TextStyle(fontSize: 12.0),
        //                 ),
        //               ),
        //               Text(
        //                 widget.busStop.roadName ?? 'N/A',
        //                 style: const TextStyle(fontSize: 12.0),
        //               ),
        //             ],
        //           ),
        //           trailing: Wrap(
        //             spacing: 16.0,
        //             children: [
        //               GestureDetector(
        //                 child: const Icon(Icons.refresh),
        //                 onTap: () {
        //                   _update();
        //                 },
        //               ),
        //               // GestureDetector(
        //               //   child: Icon(
        //               //     Icons.info,
        //               //     color: _showInfo
        //               //         ? Theme.of(context).colorScheme.primary
        //               //         : null,
        //               //   ),
        //               //   onTap: () {
        //               //     setState(() {
        //               //       _showInfo = !_showInfo;
        //               //     });
        //               //   },
        //               // ),
        //             ],
        //           ),
        //         ),
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             if (widget.variant == BusArrivalsVariant.home)
        //               OutlinedButton(
        //                 style: showFavServiceNos
        //                     ? OutlinedButton.styleFrom(
        //                         side: const BorderSide(
        //                           width: 1.0,
        //                           color: Colors.orange,
        //                         ),
        //                       )
        //                     : null,
        //                 child: Text(
        //                   'Show Favourites Only',
        //                   style: TextStyle(
        //                     color: showFavServiceNos ? Colors.orange : null,
        //                   ),
        //                 ),
        //                 onPressed: () {
        //                   var busStopCode = widget.busStop.busStopCode;
        //                   if (busStopCode != null) {
        //                     Provider.of<Preferences>(context, listen: false)
        //                         .updateFavBusStop(busStopCode,
        //                             showFavServiceNos: !showFavServiceNos);
        //                   }
        //                 },
        //               ),
        //             // const SizedBox(width: 8.0),
        //             // OutlinedButton(
        //             //   child: const Text('Refresh'),
        //             //   onPressed: () {
        //             //     _update();
        //             //   },
        //             // ),
        //           ],
        //         ),
        //         const SizedBox(height: 8.0),
        //       ],
        //     ),
        //   ),
        // ),
        if (_showInfo)
          SizedBox(
            width: 350.0,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'First / Last Bus',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: Container()),
                    const Expanded(
                      child: Text(
                        'Weekday',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Saturday',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Sunday',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 350.0,
                  child: Column(
                    children: [
                      if (_busServices.isNotEmpty) ...[
                        for (var busService in operatingBusServices) ...[
                          _buildBusArrivalRow(
                            busService,
                            firstFavBusService:
                                busService == firstFavBusService,
                          ),
                        ],
                        if (nonOperatingBusServices.isNotEmpty) ...[
                          for (var busService in nonOperatingBusServices) ...[
                            _buildBusArrivalRow(busService),
                          ],
                        ],
                        // Add a small placeholder at the bottom
                        const SizedBox(height: 50.0),
                      ] else ...[
                        for (var i = 0; i < 5; i++) _buildBusArrivalRow(null),
                      ],
                      if (_busServices.isEmpty &&
                          _busArrivalMap.isEmpty &&
                          !_loading) ...[
                        const SizedBox(height: 8.0),
                        const Text(
                          'Sorry, no buses are operating at this time',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                      // if (showFavServiceNos &&
                      //     operatingBusServices.isEmpty &&
                      //     nonOperatingBusServices.isEmpty) ...[
                      //   const SizedBox(height: 8.0),
                      //   const Text(
                      //     'You do not have any favourites',
                      //     style: TextStyle(fontStyle: FontStyle.italic),
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ),
            ),
            onTap: () {
              if (!_loading && !_showInfo) {
                _update();
              }
            },
          ),
        ),
        if (!ackTapToRefreshBusArrivals)
          Ack(
            title: 'Tap on page to refresh',
            contentPadding: const EdgeInsets.symmetric(horizontal: 32.0),
            onPressed: () {
              Provider.of<Preferences>(context, listen: false)
                  .setAckTapToRefreshBusArrivals(true);
            },
          ),
      ],
    );
  }

  Widget _buildBusArrivalRow(
    BusService? busService, {
    bool? firstFavBusService,
  }) {
    var busArrival = _busArrivalMap[busService?.serviceNo];
    var isOperating = busArrival != null;
    var parsed = busArrival?.parse(context);
    List<String> arrivalTimes = parsed?[0] ?? ['-', '-', '-'];
    Color? color = parsed?[1];
    var isServiceNoFav = _isServiceNoFav(busService?.serviceNo ?? '');
    return Padding(
      key: firstFavBusService == true ? _firstFavBusServiceKey : null,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: !_loading && !_showInfo && isOperating
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center,
            children: [
              if (!_loading || busService != null) ...[
                Expanded(
                  child: ElevatedButton(
                    style: isServiceNoFav
                        ? OutlinedButton.styleFrom(
                            side: const BorderSide(
                              width: 1.0,
                              color: Colors.orange,
                            ),
                          )
                        : null,
                    child: Text(
                      busService?.serviceNo ?? '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: !isOperating
                            ? Theme.of(context).disabledColor
                            : isServiceNoFav
                                ? Colors.orange
                                : null,
                      ),
                    ),
                    onPressed: () async {
                      if (!isOperating) {
                        Provider.of<Session>(context, listen: false)
                            .setActiveBusArrival(null);
                        showSnackBar(
                            context, 'Bus is currently not in operation');
                        return;
                      }
                      if (widget.busStop.latitude != null &&
                          widget.busStop.longitude != null &&
                          busArrival.nextBus?.hasValidLocation != true) {
                        Provider.of<Session>(context, listen: false)
                            .setActiveBusArrival(null);
                        showSnackBar(context, 'No bus location available');
                        return;
                      }
                      await _update();
                      Provider.of<Session>(context, listen: false)
                          .setActiveBusArrival(busArrival);
                      var paddingTop = widget.busStop.latitude! <
                              busArrival.nextBus!.latitude!
                          ? 75.0
                          : 12.0;
                      var paddingLeft = widget.busStop.longitude! >
                              busArrival.nextBus!.longitude!
                          ? 25.0
                          : 12.0;
                      var paddingRight = widget.busStop.longitude! <
                              busArrival.nextBus!.longitude!
                          ? 25.0
                          : 12.0;
                      FitBoundsOptions options = FitBoundsOptions(
                        padding: EdgeInsets.only(
                          top: paddingTop,
                          left: paddingLeft,
                          right: paddingRight,
                          bottom: 12.0,
                        ),
                      );
                      Provider.of<Session>(context, listen: false).fitBounds(
                        widget.busStop.latitude!,
                        widget.busStop.longitude!,
                        busArrival.nextBus!.latitude!,
                        busArrival.nextBus!.longitude!,
                        // ignoreIfPointsWithinMapBounds: true,
                        options: options,
                      );
                    },
                    onLongPress: () async {
                      var busStopCode = widget.busStop.busStopCode;
                      var serviceNo = busService?.serviceNo;
                      if (busStopCode == null || serviceNo == null) {
                        showSnackBar(context, 'Sorry, an error has occurred');
                        return;
                      }
                      await Provider.of<Preferences>(context, listen: false)
                          .updateFavBusStop(
                        busStopCode,
                        addFavServiceNo: !isServiceNoFav ? serviceNo : null,
                        removeFavServiceNo: isServiceNoFav ? serviceNo : null,
                      );
                      // _setActiveBusArrivals(fitBounds: true);
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Skeleton(
                    isLoading: true,
                    skeleton: SkeletonItem(
                      child: ElevatedButton(
                        child: Row(
                          children: const [
                            Expanded(
                              child: Text(
                                '',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 24.0),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {},
                      ),
                    ),
                    child: Container(),
                  ),
                ),
              ],
              if (_showInfo) ...[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _busRouteMap[busService?.serviceNo]?.wdFirstBusStr ??
                            '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        _busRouteMap[busService?.serviceNo]?.wdLastBusStr ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _busRouteMap[busService?.serviceNo]?.satFirstBusStr ??
                            '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        _busRouteMap[busService?.serviceNo]?.satLastBusStr ??
                            '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _busRouteMap[busService?.serviceNo]?.sunFirstBusStr ??
                            '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      Text(
                        _busRouteMap[busService?.serviceNo]?.sunLastBusStr ??
                            '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (!_loading) ...[
                  if (isOperating) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: Column(
                          children: [
                            Text(
                              arrivalTimes[0],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  busArrival.nextBus?.type == 'SD'
                                      ? 'single'
                                      : busArrival.nextBus?.type == 'DD'
                                          ? 'double'
                                          : '',
                                  style: const TextStyle(fontSize: 10.0),
                                ),
                                if (busArrival.nextBus?.feature == 'WAB')
                                  const Icon(
                                    Icons.accessible,
                                    size: 12.0,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            arrivalTimes[1],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                busArrival.nextBus2?.type == 'SD'
                                    ? 'single'
                                    : busArrival.nextBus2?.type == 'DD'
                                        ? 'double'
                                        : '',
                                style: const TextStyle(fontSize: 10.0),
                              ),
                              if (busArrival.nextBus2?.feature == 'WAB')
                                const Icon(
                                  Icons.accessible,
                                  size: 12.0,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: Column(
                          children: [
                            Text(
                              arrivalTimes[2],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14.0),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  busArrival.nextBus3?.type == 'SD'
                                      ? 'single'
                                      : busArrival.nextBus3?.type == 'DD'
                                          ? 'double'
                                          : '',
                                  style: const TextStyle(fontSize: 10.0),
                                ),
                                if (busArrival.nextBus3?.feature == 'WAB')
                                  const Icon(
                                    Icons.accessible,
                                    size: 12.0,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                        child: Text(
                          'Currently not in operation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const Expanded(
                    flex: 3,
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 32.0, right: 32.0, top: 8.0),
                      child: SkeletonLine(
                        style: SkeletonLineStyle(height: 30.0),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  _zoomTo(bool ignoreIfWithinMapBounds) {
    var lat = widget.busStop.latitude;
    var lon = widget.busStop.longitude;
    if (lat == null || lon == null) {
      return;
    }
    Provider.of<Session>(context, listen: false).fitPoint(lat, lon,
        offset: 100.0, ignoreIfWithinMapBounds: ignoreIfWithinMapBounds);
  }

  _isServiceNoFav(String serviceNo) {
    var favBusStops = Provider.of<Preferences>(context).favBusStops;
    var index = favBusStops
        .indexWhere((e) => e.busStopCode == widget.busStop.busStopCode);
    return index >= 0 &&
        favBusStops[index].favServiceNos?.contains(serviceNo) == true;
  }

  _update({bool? fitBounds}) async {
    var busStopCode = widget.busStop.busStopCode;
    if (busStopCode == null) {
      return;
    }
    setState(() {
      _loading = true;
    });
    var wait = Wait(duration: const Duration(milliseconds: 500));
    var busArrivals = await getBusArrival(busStopCode: busStopCode);
    Map<String, BusArrival> busArrivalsMap = {};
    for (var busArrival in busArrivals) {
      var serviceNo = busArrival.serviceNo;
      if (serviceNo != null) {
        busArrivalsMap[serviceNo] = busArrival;
      }
    }
    var busServices = await Provider.of<Preferences>(context, listen: false)
        .database
        .getBusServicesForBusStop(busStopCode);
    var busRoutes = await Provider.of<Preferences>(context, listen: false)
        .database
        .getBusRoutesForBusStop(busStopCode);
    Map<String, BusRoute> busRouteMap = {};
    for (var busRoute in busRoutes) {
      if (busRoute.serviceNo != null) {
        busRouteMap[busRoute.serviceNo!] = busRoute;
      }
    }
    await wait.wait();
    if (!mounted) {
      return;
    }

    // Update active bus arrival
    if (busArrivalsMap.containsKey(Provider.of<Session>(context, listen: false)
        .activeBusArrival
        ?.serviceNo)) {
      Provider.of<Session>(context, listen: false).setActiveBusArrival(
          busArrivalsMap[Provider.of<Session>(context, listen: false)
              .activeBusArrival
              ?.serviceNo!]);
    }

    setState(() {
      _loading = false;
      _busServices = busServices;
      _busArrivalMap = busArrivalsMap;
      _busRouteMap = busRouteMap;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var ctx = _firstFavBusServiceKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx);
      }
    });

    // Update active bus arrivals
    // _setActiveBusArrivals(fitBounds: fitBounds);
  }

// _setActiveBusArrivals({bool? fitBounds}) {
//   var favBusStops =
//       Provider.of<Preferences>(context, listen: false).favBusStops;
//   var index = favBusStops
//       .indexWhere((e) => e.busStopCode == widget.busStop.busStopCode);
//   List<BusArrival> activeBusArrivals = [];
//   if (index >= 0) {
//     for (var favServiceNo in favBusStops[index].favServiceNos ?? []) {
//       var busArrival = _busArrivalMap[favServiceNo];
//       if (busArrival != null) {
//         activeBusArrivals.add(busArrival);
//       }
//     }
//   }
//   // Fit bounds on map if not empty
//   if (activeBusArrivals.isNotEmpty && fitBounds == true) {
//     double minLat = widget.busStop.latitude ?? 90.0;
//     double minLon = widget.busStop.longitude ?? 180.0;
//     double maxLat = widget.busStop.latitude ?? -90.0;
//     double maxLon = widget.busStop.longitude ?? -190.0;
//     for (var activeBusArrival in activeBusArrivals) {
//       if (activeBusArrival.nextBus?.hasValidLocation == true) {
//         minLat = min(minLat, activeBusArrival.nextBus!.latitude!);
//         maxLat = max(maxLat, activeBusArrival.nextBus!.latitude!);
//       }
//       if (activeBusArrival.nextBus?.hasValidLocation == true) {
//         minLon = min(minLon, activeBusArrival.nextBus!.longitude!);
//         maxLon = max(maxLon, activeBusArrival.nextBus!.longitude!);
//       }
//     }
//     Provider.of<Session>(context, listen: false)
//         .fitBounds(maxLat, minLon, minLat, maxLon);
//   }
//   Provider.of<Session>(context, listen: false)
//       .setActiveBusArrivals(activeBusArrivals);
// }
}

void showBusArrivalsBottomSheet({
  required BuildContext context,
  required BusArrivalsVariant variant,
  required BusStop busStop,
  String? altDescription,
}) {
  var sess = Provider.of<Session>(context, listen: false);
  var mapHeight = (MediaQuery.of(context).size.height -
          MediaQuery.of(context).padding.top -
          MediaQuery.of(context).padding.bottom -
          56 -
          80) /
      3;
  var height = (MediaQuery.of(context).size.height -
          MediaQuery.of(context).padding.top -
          MediaQuery.of(context).padding.bottom -
          56) -
      mapHeight;
  height = sess.bottomSheetHeight ?? height;
  PersistentBottomSheetController? controller;
  sess.setActiveBusStop(busStop);
  sess.setIsBottomSheetShown(true);
  controller = Scaffold.of(context).showBottomSheet(
    (context) => SizedBox(
      height: height,
      child: BusArrivals(
        variant: variant,
        busStop: busStop,
        altDescription: altDescription,
        onClose: () {
          controller?.close();
        },
      ),
    ),
  );
  controller.closed.then((value) {
    // Add some delay for the bottom sheet to close
    // Otherwise, the bottom navigation bar and FAB will appear,
    // causing the bottom sheet to be shifted up while closing
    Future.delayed(const Duration(milliseconds: 200)).then((_) {
      sess.setIsBottomSheetShown(false);
      sess.setActiveBusStop(null);
      sess.setActiveBusArrival(null);
      sess.setActiveBusArrivals([]);
    });
  });
}
