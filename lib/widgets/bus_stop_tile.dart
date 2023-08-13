import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skeletons/skeletons.dart';

import 'bus_arrivals.dart';
import 'highlight_text.dart';
import '../preferences.dart';
import '../models.dart';
import '../providers/location.dart';
import '../providers/session.dart';
import '../utils/utils.dart';

enum BusStopTileVariant {
  home,
  search,
  arrival,
  nearby,
}

class BusStopTile extends StatefulWidget {
  final BusStopTileVariant variant;
  final BusStop busStop;
  final bool? selected;
  final String? altDescription;
  final bool? showDistanceChip;
  final bool? showNearbyDistanceChip;
  final String? highlightText;
  final Color? backgroundColor;
  final Widget? leading;
  final List<Widget>? trailing;
  final GestureTapCallback? onTap;

  const BusStopTile({
    Key? key,
    required this.variant,
    required this.busStop,
    this.selected,
    this.altDescription,
    this.showDistanceChip,
    this.showNearbyDistanceChip,
    this.highlightText,
    this.backgroundColor,
    this.leading,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  State<BusStopTile> createState() => _BusStopTileState();
}

class _BusStopTileState extends State<BusStopTile> {
  @override
  Widget build(BuildContext context) {
    var serviceEnabled = Provider.of<Location>(context).serviceEnabled;
    var currentPos = Provider.of<Location>(context).currentPos;
    var distance = (widget.showDistanceChip == true ||
                widget.showNearbyDistanceChip == true) &&
            currentPos != null &&
            serviceEnabled == true
        ? Geolocator.distanceBetween(currentPos.latitude, currentPos.longitude,
                widget.busStop.latitude ?? 0.0, widget.busStop.longitude ?? 0.0)
            .floor()
        : null;
    if (distance != null &&
        widget.showNearbyDistanceChip == true &&
        distance > Provider.of<Preferences>(context).maxNearbyDistance) {
      distance = null;
    }
    return Dismissible(
      key: ObjectKey(widget.busStop),
      direction: widget.variant == BusStopTileVariant.home
          ? DismissDirection.startToEnd
          : DismissDirection.none,
      background: ListTile(
        tileColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.red.shade800
            : Colors.red.shade100,
        title: const Text('Remove'),
        subtitle: const Text('from favourites'),
      ),
      child: Column(
        children: [
          Container(
            color: widget.backgroundColor ??
                (widget.variant == BusStopTileVariant.home ||
                        widget.variant == BusStopTileVariant.search
                    ? Theme.of(context).scaffoldBackgroundColor
                    : null),
            child: ListTile(
              selected: widget.selected == true,
              title: HighlightText(
                text: _getDescription(),
                highlights: widget.highlightText != null
                    ? {
                        widget.highlightText!: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      }
                    : {},
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: widget.altDescription?.isNotEmpty == true
                      ? FontStyle.italic
                      : null,
                ),
                maxLines: 1,
              ),
              subtitle: Row(
                children: [
                  SizedBox(
                    width: 50.0,
                    child: HighlightText(
                      text: widget.busStop.busStopCode ?? 'N/A',
                      highlights: widget.highlightText != null
                          ? {
                              widget.highlightText!: const TextStyle(
                                fontSize: 12.0,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            }
                          : {},
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  HighlightText(
                    text: widget.busStop.roadName ?? 'N/A',
                    highlights: widget.highlightText != null
                        ? {
                            widget.highlightText!: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          }
                        : {},
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              leading: widget.leading ??
                  (widget.busStop.uiIndex != null
                      ? GestureDetector(
                          onTap: () {
                            if (widget.busStop.latitude != null &&
                                widget.busStop.longitude != null) {
                              Provider.of<Session>(context, listen: false)
                                  .setZoomToBusStop(widget.busStop);
                              Provider.of<Session>(context, listen: false)
                                  .fitPoint(widget.busStop.latitude!,
                                      widget.busStop.longitude!);
                            }
                          },
                          child: CircleAvatar(
                            child: Text('${widget.busStop.uiIndex}'),
                          ),
                        )
                      : null),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Wrap(
                  spacing: 16.0,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (distance != null)
                      if (!Provider.of<Location>(context)
                          .gettingCurrentPos) ...[
                        Chip(
                          label: Text(
                            !Provider.of<Location>(context).gettingCurrentPos
                                ? widget.variant == BusStopTileVariant.home
                                    ? 'nearby'
                                    : '${distance}m'
                                : '...',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          side: const BorderSide(color: Colors.green),
                          backgroundColor: Colors.transparent,
                          visualDensity: const VisualDensity(
                            vertical: VisualDensity.minimumDensity,
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: 45.0,
                          height: 16.0,
                          child: Skeleton(
                            isLoading: true,
                            skeleton: const SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 45.0,
                                height: 16.0,
                              ),
                            ),
                            child: Container(),
                          ),
                        ),
                      ],
                    if (widget.variant == BusStopTileVariant.search ||
                        widget.variant == BusStopTileVariant.nearby)
                      _buildFavIcon(context),
                    if (widget.variant == BusStopTileVariant.home)
                      _buildMenuIcon(context),
                    if (widget.trailing != null) ...widget.trailing!,
                  ],
                ),
              ),
              onTap: widget.onTap != null
                  ? widget.onTap!
                  : widget.variant != BusStopTileVariant.arrival
                      ? () {
                          showBusArrivalsBottomSheet(
                            context: context,
                            variant: widget.variant == BusStopTileVariant.home
                                ? BusArrivalsVariant.home
                                : BusArrivalsVariant.search,
                            busStop: widget.busStop,
                            altDescription: widget.altDescription,
                          );
                        }
                      : null,
            ),
          ),
        ],
      ),
      onDismissed: (_) => _remove(),
    );
  }

  Widget _buildFavIcon(BuildContext context) {
    var favBusStops = Provider.of<Preferences>(context).favBusStops;
    var isFav = favBusStops.firstWhereOrNull(
            (element) => element.busStopCode == widget.busStop.busStopCode) !=
        null;
    return GestureDetector(
      child: Icon(
        isFav ? Icons.star : Icons.star_border,
        color: isFav ? Colors.orange : null,
        size: 26.0,
      ),
      onTap: () {
        var busStopCode = widget.busStop.busStopCode;
        if (busStopCode != null) {
          if (isFav) {
            Provider.of<Preferences>(context, listen: false)
                .removeFavBusStop(busStopCode);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content:
                      Text('Removed "${_getDescription()}" from favourites'),
                ),
              );
          } else {
            Provider.of<Preferences>(context, listen: false)
                .addFavBusStop(busStopCode);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Added "${_getDescription()}" to favourites'),
                ),
              );
          }
        }
      },
    );
  }

  Widget _buildMenuIcon(BuildContext context) {
    // var favBusStopCodes = Provider.of<Preferences>(context).favBusStopCodes;
    // var isFav = favBusStopCodes.contains(widget.busStop.busStopCode);
    return GestureDetector(
      child: const Icon(
        Icons.more_vert,
        size: 26.0,
      ),
      onTapUp: (TapUpDetails details) {
        var rect = RelativeRect.fromLTRB(
            details.globalPosition.dx, details.globalPosition.dy, 0, 0);
        showMenu(
          context: context,
          position: rect,
          items: [
            // PopupMenuItem(
            //   child: const Text('Change Name'),
            //   onTap: () async {
            //     await Future.delayed(Duration.zero);
            //     _changeName();
            //   },
            // ),
            PopupMenuItem(
              child: const Text('Remove'),
              onTap: () => _remove(),
            ),
          ],
        );
        // var busStopCode = widget.busStop.busStopCode;
        // if (busStopCode != null) {
        //   if (isFav) {
        //     Provider.of<Preferences>(context, listen: false)
        //         .removeFavBusStopCode(busStopCode);
        //     ScaffoldMessenger.of(context)
        //       ..removeCurrentSnackBar()
        //       ..showSnackBar(
        //         const SnackBar(
        //           content: Text('Removed from favourites'),
        //         ),
        //       );
        //   } else {
        //     Provider.of<Preferences>(context, listen: false)
        //         .addFavBusStopCode(busStopCode);
        //     ScaffoldMessenger.of(context)
        //       ..removeCurrentSnackBar()
        //       ..showSnackBar(
        //         const SnackBar(
        //           content: Text('Added as favourites'),
        //         ),
        //       );
        //   }
        // }
      },
    );
  }

  String _getDescription() {
    return widget.altDescription ?? widget.busStop.description ?? 'N/A';
  }

  // _changeName() async {
  //   var busStopCode = widget.busStop.busStopCode;
  //   if (busStopCode == null) {
  //     showSnackBar(context, 'Invalid Bus Stop Code');
  //     return;
  //   }
  //
  //   var altDescription = await showTextDialog(
  //     context: context,
  //     title: 'Enter Bus Stop Name',
  //     initialValue: widget.altDescription,
  //     hintText: widget.busStop.description,
  //   );
  //   if (!mounted) {
  //     return;
  //   }
  //   Provider.of<Preferences>(context, listen: false).updateFavBusStop(
  //     busStopCode,
  //     altDescription: altDescription,
  //   );
  // }

  _remove() async {
    var busStopCode = widget.busStop.busStopCode;
    if (busStopCode != null) {
      var prefs = Provider.of<Preferences>(context, listen: false);
      var index = await prefs.removeFavBusStop(busStopCode);
      if (index != null) {
        showSnackBarUndo(
          context,
          text: 'Removed "${_getDescription()}" from favourites',
          onUndo: () {
            prefs.addFavBusStop(busStopCode, index: index);
          },
        );
      }
    }
  }
}
