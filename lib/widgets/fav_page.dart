import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'bus_stop_tile.dart';
import '../models.dart';
import '../preferences.dart';

class FavPage extends StatefulWidget {
  const FavPage({Key? key}) : super(key: key);

  @override
  State<FavPage> createState() => _FavPageState();
}

class _FavPageState extends State<FavPage> {
  @override
  Widget build(BuildContext context) {
    var hasFavBusStops =
        Provider.of<Preferences>(context).favBusStops.isNotEmpty;
    var busStopsByBusStopCode =
        Provider.of<Preferences>(context).busStopsByBusStopCode;
    List<Map<String, dynamic>> favBusStops = Provider.of<Preferences>(context)
        .favBusStops
        .where((e) => busStopsByBusStopCode.containsKey(e.busStopCode))
        .map((e) => {
              'favBusStop': e,
              'busStop': BusStop.fromMap(
                  busStopsByBusStopCode[e.busStopCode]!.toMap()),
            })
        .toList();
    for (var i = 0; i < favBusStops.length; i++) {
      favBusStops[i]['busStop'].uiIndex = i + 1;
    }
    return hasFavBusStops
        ? Column(
            children: [
              Expanded(
                child: ReorderableListView(
                  onReorder: (int oldIndex, int newIndex) {
                    // There is a "placeholder" container at the last index
                    // So we need to compensate for it
                    newIndex = newIndex >= favBusStops.length + 1
                        ? newIndex - 1
                        : newIndex;
                    Provider.of<Preferences>(context, listen: false)
                        .moveFavBusStop(oldIndex, newIndex);
                  },
                  onReorderStart: (int index) {
                    setState(() {
                      HapticFeedback.vibrate();
                    });
                  },
                  proxyDecorator:
                      (Widget widget, int index, Animation animation) {
                    return Material(
                      child: Container(
                        color: Theme.of(context).colorScheme.background,
                        child: widget,
                      ),
                    );
                  },
                  children: [
                    for (var i = 0; i < favBusStops.length; i++)
                      Column(
                        key: Key('${favBusStops[i]['busStop'].busStopCode}'),
                        children: [
                          BusStopTile(
                            variant: BusStopTileVariant.home,
                            busStop: favBusStops[i]['busStop'],
                            altDescription:
                                favBusStops[i]['favBusStop'].altDescription,
                            showNearbyDistanceChip:
                                Provider.of<Preferences>(context)
                                    .showDistanceForNearbyFavs,
                          ),
                          const Divider(height: 1.0, thickness: 1.0),
                        ],
                      ),
                    // Placeholder to prevent last item from being blocked by FAB
                    IgnorePointer(
                      key: UniqueKey(),
                      child: Container(
                        height: 100.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Click the ',
                  style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
                ),
                Icon(Icons.search),
                Text(
                  'icon below to add bus stop',
                  style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
  }
}
