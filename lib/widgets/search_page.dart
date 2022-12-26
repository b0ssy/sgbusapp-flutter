import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../models.dart';
import '../preferences.dart';
import '../providers/session.dart';
import '../widgets/bus_stop_tile.dart';
import '../utils/utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  var _searchText = '';
  var _searching = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var recentBusStopSearches =
        Provider.of<Preferences>(context, listen: false).recentBusStopSearches;
    var searchedBusStops = Provider.of<Session>(context).searchedBusStops;
    var showMap = Provider.of<Preferences>(context).showMap;
    var searchPickMap = Provider.of<Session>(context).searchPickMap && showMap;
    var searchPickMapPos = Provider.of<Session>(context).searchPickMapPos;
    var showRecentSearches = _searchText.isEmpty && !searchPickMap;
    return Column(
      children: [
        Container(
          height: 1.0,
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  enabled: !searchPickMap,
                  autofocus: true,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bus stops here',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchText.isNotEmpty
                        ? GestureDetector(
                            child: const Icon(Icons.close),
                            onTap: () {
                              setState(() {
                                _searchText = '';
                                _searchController.text = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ),
              if (showMap)
                SizedBox(
                  width: 100.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: TextButton(
                      onPressed: () {
                        var newSearchPickMap =
                            !Provider.of<Session>(context, listen: false)
                                .searchPickMap;
                        Provider.of<Session>(context, listen: false)
                            .setSearchPickMap(newSearchPickMap);
                        if (newSearchPickMap) {
                          Provider.of<Session>(context, listen: false)
                              .setSearchedBusStops([]);
                        } else {
                          Provider.of<Session>(context, listen: false)
                              .setSearchPickMapPos(null);
                          Provider.of<Session>(context, listen: false)
                              .setSearchedBusStops([]);
                          if (_searchController.text.isNotEmpty) {
                            _searchBusStops(_searchController.text);
                          }
                        }
                      },
                      child: Text(!Provider.of<Session>(context).searchPickMap
                          ? 'PICK MAP'
                          : 'CANCEL'),
                    ),
                  ),
                ),
            ],
          ),
          leading: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              hideSnackBar(context);
              Provider.of<Session>(context, listen: false)
                  .setEnableSearch(false);
            },
            child: const Icon(
              Icons.chevron_left,
              size: 26.0,
            ),
          ),
        ),
        if (showRecentSearches)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recentBusStopSearches.isNotEmpty
                        ? 'Recent searches'
                        : 'No recent searches',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                const Spacer(),
                Opacity(
                  opacity: recentBusStopSearches.isNotEmpty ? 1.0 : 0.0,
                  child: TextButton(
                    child: const Text('Clear all'),
                    onPressed: () async {
                      Provider.of<Preferences>(context, listen: false)
                          .setRecentBusStopSearches([]);
                      showSnackBarUndo(
                        context,
                        text: 'Cleared all recent searches',
                        onUndo: () async {
                          await Provider.of<Preferences>(context, listen: false)
                              .setRecentBusStopSearches(recentBusStopSearches);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!_searching) ...[
                  // Show recent searches if no search text entered
                  if (showRecentSearches) ...[
                    ..._buildRecentSearches(),
                  ]
                  // Show searched bus stops
                  else ...[
                    for (var busStop in searchedBusStops)
                      Column(
                        children: [
                          BusStopTile(
                            variant: BusStopTileVariant.search,
                            busStop: busStop,
                            highlightText:
                                _searchText.isNotEmpty ? _searchText : null,
                          ),
                          const Divider(height: 1.0, thickness: 1.0),
                        ],
                      ),
                    if (searchedBusStops.isEmpty &&
                        (!searchPickMap || searchPickMapPos != null))
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('No bus stops found'),
                      ),
                  ],
                ] else ...[
                  for (var i = 0; i < 5; i++) ...[
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
        ),
      ],
    );
  }

  _handleSearchTextChanged() {
    Provider.of<Session>(context, listen: false).setSearchedBusStops([]);
    _searchTimer?.cancel();
    var searchText = _searchController.text;
    if (searchText.isNotEmpty) {
      setState(() {
        _searching = true;
      });
      _searchTimer = Timer(
        const Duration(milliseconds: 500),
            () => _searchBusStops(searchText),
      );
    } else {
      // var recentSearchedBusStops = _getRecentSearchedBusStops();
      // Provider.of<Session>(context, listen: false)
      //     .setSearchedBusStops(recentSearchedBusStops);
      setState(() {
        _searching = false;
      });
    }
    setState(() {
      _searchText = _searchController.text;
    });
  }

  _buildRecentSearches() {
    var recentBusStopSearches =
        Provider.of<Preferences>(context).recentBusStopSearches;
    return [
      for (var recentBusStopSearch in recentBusStopSearches) ...[
        Dismissible(
          key: ObjectKey(recentBusStopSearch),
          direction: DismissDirection.startToEnd,
          background: ListTile(
            tileColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.red.shade800
                : Colors.red.shade100,
            title: const Text('Remove'),
            // subtitle: const Text('from recent searches'),
          ),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListTile(
              title: Text(recentBusStopSearch),
              onTap: () {
                _searchController.text = recentBusStopSearch;
                selectAllText(_searchController);
              },
            ),
          ),
          onDismissed: (_) async {
            var removedIndex =
                await Provider.of<Preferences>(context, listen: false)
                    .removeRecentBusStopSearch(recentBusStopSearch);
            if (removedIndex < 0) {
              return;
            }
            showSnackBarUndo(
              context,
              text: 'Removed "$recentBusStopSearch"'
                  ' from recent searches',
              onUndo: () {
                Provider.of<Preferences>(context, listen: false)
                    .addRecentBusStopSearch(
                  recentBusStopSearch,
                  index: removedIndex,
                );
              },
            );
          },
        ),
        const Divider(height: 1.0, thickness: 1.0),
      ],
    ];
  }

  _searchBusStops(String searchText) async {
    var busStops = await Provider.of<Preferences>(context, listen: false)
        .database
        .searchBusStops(searchText);
    BusStop.setUiIndex(busStops);
    Provider.of<Preferences>(context, listen: false)
        .addRecentBusStopSearch(searchText);
    Provider.of<Session>(context, listen: false).setSearchedBusStops(busStops);
    setState(() {
      _searching = false;
    });
  }
}
