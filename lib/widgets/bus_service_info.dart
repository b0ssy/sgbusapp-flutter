import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bus_stop_tile.dart';
import '../models.dart';
import '../preferences.dart';
import '../providers/session.dart';

class BusServiceInfo extends StatefulWidget {
  final BusService busService;
  final Function onClose;

  const BusServiceInfo({
    Key? key,
    required this.busService,
    required this.onClose,
  }) : super(key: key);

  @override
  State<BusServiceInfo> createState() => _BusServiceInfoState();
}

class _BusServiceInfoState extends State<BusServiceInfo> {
  final _scrollController1 = ScrollController();
  final _scrollController2 = ScrollController();
  List<BusStop> _busStopsDirection1 = [];
  List<BusStop> _busStopsDirection2 = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();

    _update();
  }

  @override
  void didUpdateWidget(covariant BusServiceInfo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.busService != oldWidget.busService) {
      _update();
    }
  }

  @override
  Widget build(BuildContext context) {
    var direction1Str = '';
    if (_busStopsDirection1.isNotEmpty) {
      direction1Str = 'From ${_busStopsDirection1[0].description}';
    }
    var direction2Str = '';
    if (_busStopsDirection2.isNotEmpty) {
      direction2Str = 'From ${_busStopsDirection2[0].description}';
    }
    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: Column(
        children: [
          Container(
            height: 1.0,
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          ListTile(
            title: Text(
              widget.busService.serviceNo ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: GestureDetector(
              child: const Icon(
                Icons.chevron_left,
                size: 26.0,
              ),
              onTap: () => widget.onClose(),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Wrap(
                spacing: 16.0,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.busService.operator != null)
                    Chip(
                      label: Text(
                        widget.busService.operator!,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                      visualDensity: const VisualDensity(
                        vertical: VisualDensity.minimumDensity,
                      ),
                    ),
                  // GestureDetector(
                  //   child: const Icon(
                  //     Icons.close,
                  //     size: 26.0,
                  //   ),
                  //   onTap: () => widget.onClose(),
                  // ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TabBar(
              labelStyle: const TextStyle(fontSize: 14.0),
              labelColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : null,
              unselectedLabelColor:
                  Theme.of(context).brightness == Brightness.light
                      ? Colors.grey
                      : null,
              tabs: [
                Tab(text: direction1Str),
                Tab(text: direction2Str),
              ],
              onTap: (tabIndex) {
                _setBusStops(tabIndex + 1);
                setState(() {
                  _tabIndex = tabIndex;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: TabBarView(
                children: [
                  Scrollbar(
                    controller: _scrollController1,
                    interactive: true,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController1,
                      itemCount: _busStopsDirection1.length,
                      itemBuilder: (context, index) => BusStopTile(
                        variant: BusStopTileVariant.search,
                        busStop: _busStopsDirection1[index],
                      ),
                    ),
                  ),
                  if (_busStopsDirection2.isNotEmpty) ...[
                    Scrollbar(
                      controller: _scrollController2,
                      interactive: true,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController2,
                        itemCount: _busStopsDirection2.length,
                        itemBuilder: (context, index) => BusStopTile(
                          variant: BusStopTileVariant.search,
                          busStop: _busStopsDirection2[index],
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'This bus service only has 1 direction',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _update() async {
    var serviceNo = widget.busService.serviceNo;
    if (serviceNo == null) {
      return;
    }
    var busStopsDirection1 =
        await Provider.of<Preferences>(context, listen: false)
            .database
            .getBusStopsForBusService(serviceNo, 1);
    var busStopsDirection2 =
        await Provider.of<Preferences>(context, listen: false)
            .database
            .getBusStopsForBusService(serviceNo, 2);
    BusStop.setUiIndex(busStopsDirection1);
    BusStop.setUiIndex(busStopsDirection2);
    if (!mounted) {
      return;
    }
    setState(() {
      _tabIndex = 0;
      _busStopsDirection1 = busStopsDirection1;
      _busStopsDirection2 = busStopsDirection2;
    });
    _setBusStops(1);
  }

  _setBusStops(int direction) {
    List<BusStop> busStops = direction == 1
        ? _busStopsDirection1
        : direction == 2
            ? _busStopsDirection2
            : [];
    Provider.of<Session>(context, listen: false)
        .setBusServiceBusStops(busStops);
    if (busStops.isNotEmpty) {
      double minLat = 90.0;
      double minLon = 180.0;
      double maxLat = -90.0;
      double maxLon = -190.0;
      for (var busStop in busStops) {
        if (busStop.latitude != null) {
          minLat = min(minLat, busStop.latitude!);
          maxLat = max(maxLat, busStop.latitude!);
        }
        if (busStop.longitude != null) {
          minLon = min(minLon, busStop.longitude!);
          maxLon = max(maxLon, busStop.longitude!);
        }
      }
      Provider.of<Session>(context, listen: false)
          .fitBounds(maxLat, minLon, minLat, maxLon);
    }
  }
}
