import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sgbusapp_flutter/utils/utils.dart';

import 'settings_screen.dart';
import '../constants.dart' as constants;
import '../preferences.dart';

import '../providers/session.dart';
import '../widgets/bus_map.dart';
import '../widgets/fav_page.dart';
import '../widgets/search_page.dart';
import '../widgets/nearby_page.dart';
import '../widgets/buses_page.dart';
import '../widgets/mrt_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _exitAppTimer;

  @override
  void initState() {
    super.initState();

    // Compute bottom sheet height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var mapHeight = (MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom -
              56 -
              80) /
          3;
      Provider.of<Session>(context, listen: false).bottomSheetHeight =
          (MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  56) -
              mapHeight;
    });

    // Nullify mapController if showMap option is disabled
    Provider.of<Preferences>(context, listen: false).addListener(() {
      if (!Provider.of<Preferences>(context, listen: false).showMap) {
        Provider.of<Session>(context, listen: false).mapController = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var lastNavIndex = Provider.of<Preferences>(context).lastNavIndex;
    var mapHeight = (MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            MediaQuery.of(context).padding.bottom -
            56 -
            80) /
        3;
    return WillPopScope(
      onWillPop: () async {
        var sess = Provider.of<Session>(context, listen: false);
        if (sess.isBottomSheetShown) {
          return true;
        }
        if (lastNavIndex == cFavPageNavIndex && sess.enableSearch) {
          sess.setEnableSearch(false);
          return false;
        }
        if (lastNavIndex == cBusesPageNavIndex &&
            sess.activeBusService != null) {
          sess.setActiveBusService(null);
          return false;
        }
        // Requires user to press back twice to exit
        // so that the user won't exit by mistake
        if (_exitAppTimer?.isActive != true) {
          _exitAppTimer?.cancel();
          _exitAppTimer = Timer(
            const Duration(seconds: 2),
            () {
              _exitAppTimer = null;
            },
          );
          showSnackBar(context, 'Press BACK again to exit');
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              !Provider.of<Session>(context).isBottomSheetShown,
          title: const Text(constants.cAppTitle),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                  // Navigator.push(
                  //   context,
                  //   PageRouteBuilder(
                  //     pageBuilder: (context, animation, secondaryAnimation) =>
                  //         const SettingsScreen(),
                  //     transitionsBuilder:
                  //         (context, animation, secondaryAnimation, child) {
                  //       return Stack(
                  //         children: <Widget>[
                  //           SlideTransition(
                  //             position: Tween<Offset>(
                  //               begin: const Offset(0.0, 0.0),
                  //               end: const Offset(-1.0, 0.0),
                  //             ).animate(CurvedAnimation(
                  //               parent: animation,
                  //               curve: Curves.ease,
                  //             )),
                  //             child: widget,
                  //           ),
                  //           SlideTransition(
                  //             position: Tween<Offset>(
                  //               begin: const Offset(1.0, 0.0),
                  //               end: Offset.zero,
                  //             ).animate(CurvedAnimation(
                  //               parent: animation,
                  //               curve: Curves.ease,
                  //             )),
                  //             child: child,
                  //           ),
                  //         ],
                  //       );
                  //     },
                  //   ),
                  // );
                },
                child: const Icon(Icons.settings, size: 26.0),
              ),
            ),
          ],
        ),
        floatingActionButton: lastNavIndex == cFavPageNavIndex &&
                !Provider.of<Session>(context).enableSearch &&
                !Provider.of<Session>(context).isBottomSheetShown
            ? FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: () {
                  Provider.of<Session>(context, listen: false)
                      .setEnableSearch(true);
                },
              )
            : null,
        bottomNavigationBar: !Provider.of<Session>(context).isBottomSheetShown
            ? NavigationBar(
                destinations: const <Widget>[
                  NavigationDestination(
                    label: 'Favourites',
                    icon: Icon(Icons.star),
                  ),
                  NavigationDestination(
                    label: 'Nearby',
                    icon: Icon(Icons.person_pin_circle),
                  ),
                  NavigationDestination(
                    label: 'Buses',
                    icon: Icon(Icons.directions_bus),
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_tree),
                    label: 'MRT Map',
                  ),
                ],
                selectedIndex: lastNavIndex,
                onDestinationSelected: (int index) {
                  if (Provider.of<Preferences>(context, listen: false)
                          .lastNavIndex !=
                      index) {
                    Provider.of<Preferences>(context, listen: false)
                        .setLastNavIndex(index);
                  }
                },
              )
            : null,
        body: IndexedStack(
          index: lastNavIndex == cFavPageNavIndex ||
                  lastNavIndex == cNearbyPageNavIndex ||
                  lastNavIndex == cBusesPageNavIndex
              ? 0
              : lastNavIndex,
          children: [
            Column(
              children: [
                if (Provider.of<Preferences>(context).showMap)
                  SizedBox(
                    height: mapHeight,
                    child: BusMap(
                      showMyLocation:
                          Provider.of<Preferences>(context).showMyLocation,
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: lastNavIndex,
                    children: [
                      Provider.of<Session>(context).enableSearch
                          ? const SearchPage()
                          : const FavPage(),
                      const NearbyPage(),
                      const BusesPage(),
                    ],
                  ),
                ),
              ],
            ),
            Container(),
            Container(),
            const MrtPage(),
          ],
        ),
      ),
    );
  }
}
