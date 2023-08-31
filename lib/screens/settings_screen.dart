import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:intl/intl.dart';

import '../preferences.dart';
// import '../utils/datamall_api.dart';
import '../utils/utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _syncing = false;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        _packageInfo = packageInfo;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var platformBrightness = WidgetsBinding.instance.window.platformBrightness;
    var themeText =
        'Use ${platformBrightness == Brightness.light ? 'Dark' : 'Light'} Theme';
    var platformThemeMode = platformBrightness == Brightness.light
        ? ThemeMode.light
        : ThemeMode.dark;
    var inversePlatformThemeMode = platformBrightness == Brightness.light
        ? ThemeMode.dark
        : ThemeMode.light;
    var selectedThemeMode =
        Provider.of<Preferences>(context).themeMode == ThemeMode.system
            ? platformThemeMode
            : inversePlatformThemeMode;
    var theme = SettingsThemeData(
      titleTextColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
    var showMap = Provider.of<Preferences>(context).showMap;
    var showMyLocation = Provider.of<Preferences>(context).showMyLocation;
    var showNearbyRadius = Provider.of<Preferences>(context).showNearbyRadius;
    var showDistanceForNearbyFavs =
        Provider.of<Preferences>(context).showDistanceForNearbyFavs;
    // var lastDataSyncDate = Provider.of<Preferences>(context).lastDataSyncDate;
    // var dateFormat = DateFormat('dd MMM yyyy, kk:mm:ss a');
    return WillPopScope(
      onWillPop: () async {
        if (_syncing) {
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Please wait for synchronization to complete'),
              ),
            );
        }
        return !_syncing;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: SettingsList(
          lightTheme: theme,
          darkTheme: theme,
          sections: [
            SettingsSection(
              title: const Text('Display'),
              tiles: <SettingsTile>[
                SettingsTile.switchTile(
                  initialValue: platformThemeMode != selectedThemeMode,
                  leading: Icon(
                    selectedThemeMode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  title: Text(themeText),
                  // description: platformThemeMode == selectedThemeMode
                  //     ? const Text('using system theme')
                  //     : null,
                  trailing: Switch(
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: platformThemeMode != selectedThemeMode,
                    onChanged: (value) {
                      Provider.of<Preferences>(context, listen: false)
                          .setThemeMode(value
                              ? inversePlatformThemeMode
                              : ThemeMode.system);
                    },
                  ),
                  onToggle: (value) {
                    Provider.of<Preferences>(context, listen: false)
                        .setThemeMode(value
                            ? inversePlatformThemeMode
                            : ThemeMode.system);
                  },
                ),
                SettingsTile.switchTile(
                  initialValue: showMap,
                  leading: Icon(showMap ? Icons.place : Icons.location_off),
                  title: const Text('Show Map'),
                  // description: const Text('increase data usage'),
                  trailing: Switch(
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: showMap,
                    onChanged: (value) {
                      Provider.of<Preferences>(context, listen: false)
                          .setShowMap(value);
                    },
                  ),
                  onToggle: (value) {
                    Provider.of<Preferences>(context, listen: false)
                        .setShowMap(value);
                  },
                ),
                SettingsTile.switchTile(
                  enabled: showMap,
                  initialValue: showMyLocation,
                  leading: const Icon(Icons.gps_fixed),
                  title: const Text('Show My Location on Map'),
                  trailing: Switch(
                    activeColor: showMap
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                    value: showMyLocation,
                    onChanged: (value) {
                      Provider.of<Preferences>(context, listen: false)
                          .setShowMyLocation(value);
                    },
                  ),
                  onToggle: (value) {
                    Provider.of<Preferences>(context, listen: false)
                        .setShowMyLocation(value);
                  },
                ),
                SettingsTile.switchTile(
                  enabled: showMap,
                  initialValue: showNearbyRadius,
                  leading: const Icon(Icons.gps_fixed),
                  title: const Text('Show Nearby Radius on Map'),
                  trailing: Switch(
                    activeColor: showMap
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                    value: showNearbyRadius,
                    onChanged: (value) {
                      Provider.of<Preferences>(context, listen: false)
                          .setShowNearbyRadius(value);
                    },
                  ),
                  onToggle: (value) {
                    Provider.of<Preferences>(context, listen: false)
                        .setShowNearbyRadius(value);
                  },
                ),
                SettingsTile.switchTile(
                  initialValue: showDistanceForNearbyFavs,
                  leading: const Icon(Icons.straighten),
                  title: const Text('Show Distance'),
                  description: const Text('from nearby favourite bus stops'),
                  trailing: Switch(
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: showDistanceForNearbyFavs,
                    onChanged: (value) {
                      Provider.of<Preferences>(context, listen: false)
                          .setShowDistanceForNearbyFavs(value);
                    },
                  ),
                  onToggle: (value) {
                    Provider.of<Preferences>(context, listen: false)
                        .setShowDistanceForNearbyFavs(value);
                  },
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Software'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  enabled: !_syncing,
                  leading: const FlutterLogo(),
                  title: const Text('Built using Flutter'),
                  value: const Text('my first Flutter app!'),
                ),
                SettingsTile.navigation(
                  enabled: !_syncing,
                  leading: const Icon(Icons.info),
                  title: const Text('Version'),
                  value: Text(_packageInfo?.version ?? ''),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('About'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  enabled: !_syncing,
                  leading: const Icon(Icons.email),
                  title: const Text('Contact Me'),
                  value: const Text('superbos88@hotmail.com'),
                  onPressed: (_) async {
                    await Clipboard.setData(
                        const ClipboardData(text: 'superbos88@hotmail.com'));
                    showSnackBar(context, 'Copied email address');
                  },
                ),
                SettingsTile.navigation(
                  enabled: !_syncing,
                  leading: const Icon(Icons.sports_bar),
                  title: const Text('Buy Me a Beer!'),
                  value: Row(
                    children: [
                      const Text('if you like my work!'),
                      const SizedBox(width: 4.0),
                      Icon(
                        Icons.emoji_emotions,
                        color: _syncing ? Colors.grey : null,
                      ),
                    ],
                  ),
                  onPressed: (_) {
                    _buyMeABeer();
                  },
                ),
                SettingsTile.navigation(
                  enabled: !_syncing,
                  leading: const Icon(Icons.warning),
                  title: const Text('Disclaimer'),
                  value: const Text('read this before you complain!'),
                  onPressed: (_) {
                    _showDisclaimer();
                  },
                ),
              ],
            ),
            // SettingsSection(
            //   title: const Text('Data'),
            //   tiles: <SettingsTile>[
            //     SettingsTile.navigation(
            //       enabled: !_syncing,
            //       leading: const Icon(Icons.sync),
            //       title: const Text('Synchronize Data'),
            //       description: Text(
            //         lastDataSyncDate != null
            //             ? 'last synced: ${dateFormat.format(lastDataSyncDate)}'
            //             : 'did not sync before',
            //         softWrap: false,
            //       ),
            //       trailing: _syncing
            //           ? const Padding(
            //               padding: EdgeInsets.only(right: 20.0),
            //               child: SizedBox(
            //                 width: 20.0,
            //                 height: 20.0,
            //                 child: CircularProgressIndicator(
            //                   strokeWidth: 2.0,
            //                 ),
            //               ),
            //             )
            //           : null,
            //       onPressed: (_) => _syncData(),
            //     ),
            //   ],
            // ),
            _Actions(),
            _EmptyPlaceholder(),
          ],
        ),
      ),
    );
  }

  // _syncData() async {
  //   setState(() {
  //     _syncing = true;
  //   });
  //
  //   var busStops = await getAllBusStops();
  //   await Provider.of<Preferences>(context, listen: false)
  //       .database
  //       .updateBusStops(busStops);
  //   var busServices = await getAllBusServices();
  //   await Provider.of<Preferences>(context, listen: false)
  //       .database
  //       .updateBusServices(busServices);
  //   var busRoutes = await getAllBusRoutes();
  //   await Provider.of<Preferences>(context, listen: false)
  //       .database
  //       .updateBusRoutes(busRoutes);
  //   Provider.of<Preferences>(context, listen: false)
  //       .setLastDataSyncDate(DateTime.now());
  //   if (!mounted) {
  //     return;
  //   }
  //
  //   ScaffoldMessenger.of(context)
  //     ..hideCurrentSnackBar()
  //     ..showSnackBar(
  //       const SnackBar(
  //         content: Text('Synchronized successful!'),
  //       ),
  //     );
  //   setState(() {
  //     _syncing = false;
  //   });
  // }

  _buyMeABeer() async {
    if (!await showYesCancelDialog(
      context: context,
      title: 'Really Buying Me a Beer?',
      yesText: 'Definitely!',
      cancelText: 'Not now :(',
    )) {
      return;
    }
    var uri = Uri.parse('https://www.buymeacoffee.com/b0ssY');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showSnackBar(context, 'Failed to open webpage');
    }
  }

  _showDisclaimer() {
    showMessageDialog(
      context: context,
      title: 'Disclaimer',
      content: '1) This app is created for the purpose of learning Flutter.\n'
          '2) This app is FREE for use with ZERO ads.\n'
          '3) This app has only ONE software developer.\n'
          '4) Bus arrival, service and route data comes from LTA API.\n'
          '\n'
          'Please pardon if there are any bugs.\n'
          'Will try to solve them ASAP!',
    );
  }
}

class _Actions extends AbstractSettingsSection {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: TextButton(
            child: const Text('Restore Defaults'),
            onPressed: () => _restoreDefaults(context),
          ),
        ),
      ],
    );
  }

  _restoreDefaults(BuildContext context) async {
    if (!await showYesCancelDialog(
      context: context,
      title: 'Are you sure you want to restore default settings?',
      yesText: 'OK',
    )) {
      return;
    }
    Provider.of<Preferences>(context, listen: false).restoreDefaults();
  }
}

class _EmptyPlaceholder extends AbstractSettingsSection {
  @override
  Widget build(BuildContext context) {
    return Container(height: 100);
  }
}
