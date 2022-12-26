import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:sgbusapp_flutter/providers/session.dart';

import '../models.dart';
import '../preferences.dart';
import '../widgets/highlight_text.dart';
import '../widgets/bus_service_info.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({Key? key}) : super(key: key);

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  final _filterTextController = TextEditingController();
  final _scrollController = ScrollController();
  String _filterText = '';
  List<BusService> _busServices = [];

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    var activeBusService = Provider.of<Session>(context).activeBusService;
    var busServices = [..._busServices];
    if (_filterText.isNotEmpty) {
      busServices = busServices
          .where((busService) =>
              busService.serviceNo
                  ?.toLowerCase()
                  .contains(_filterText.toLowerCase()) ==
              true)
          .toList();
    }
    return PageTransitionSwitcher(
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: activeBusService == null
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    controller: _filterTextController,
                    decoration: InputDecoration(
                      hintText: 'Search buses here',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filterText.isNotEmpty
                          ? GestureDetector(
                              child: const Icon(Icons.close),
                              onTap: () {
                                setState(() {
                                  _filterText = '';
                                  _filterTextController.text = '';
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.ease,
                                  );
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filterText = value;
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(height: 4.0),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    interactive: true,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: busServices.length,
                      itemBuilder: (context, index) {
                        var busService = busServices[index];
                        return Column(
                          children: [
                            ListTile(
                              title: HighlightText(
                                text: busService.serviceNo ?? '-',
                                highlights: _filterText.isNotEmpty
                                    ? {
                                        _filterText: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      }
                                    : {},
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Wrap(
                                spacing: 8.0,
                                children: [
                                  if (busService.operator != null)
                                    Chip(
                                      label: Text(
                                        busService.operator!,
                                        style: const TextStyle(fontSize: 12.0),
                                      ),
                                      visualDensity: const VisualDensity(
                                        vertical: VisualDensity.minimumDensity,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Provider.of<Session>(context, listen: false)
                                    .setActiveBusService(busService);
                              },
                            ),
                            const Divider(height: 1.0),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: BusServiceInfo(
                    busService: activeBusService,
                    onClose: () {
                      Provider.of<Session>(context, listen: false)
                          .setBusServiceBusStops([]);
                      Provider.of<Session>(context, listen: false)
                          .setActiveBusService(null);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  _initialize() async {
    var busServices = await Provider.of<Preferences>(context, listen: false)
        .database
        .getBusServices(direction: 1);
    if (!mounted) {
      return;
    }
    setState(() {
      _busServices = busServices;
    });
  }
}
