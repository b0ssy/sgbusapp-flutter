import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletons/skeletons.dart';

import 'constants.dart' as constants;
import 'preferences.dart';
import 'providers/location.dart';
import 'providers/session.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  var prefs = Preferences(sharedPreferences);
  await prefs.load();

  var app = MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: prefs),
      ChangeNotifierProvider.value(value: Location()),
      ChangeNotifierProvider.value(value: Session()),
    ],
    child: SgBusApp(
      needsToLoadDatabase: prefs.needsToLoadDatabase,
    ),
  );
  runApp(app);
}

class SgBusApp extends StatefulWidget {
  final bool needsToLoadDatabase;

  const SgBusApp({
    Key? key,
    required this.needsToLoadDatabase,
  }) : super(key: key);

  @override
  State<SgBusApp> createState() => _SgBusAppState();
}

class _SgBusAppState extends State<SgBusApp> {
  var _isDatabaseLoaded = false;

  @override
  void initState() {
    super.initState();

    _isDatabaseLoaded = !widget.needsToLoadDatabase;
    if (!_isDatabaseLoaded) {
      _initializeDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeMode = Provider.of<Preferences>(context).themeMode;
    var lightTheme = _buildTheme(Brightness.light);
    var darkTheme = _buildTheme(Brightness.dark);
    return MaterialApp(
      title: constants.cAppTitle,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: SkeletonTheme(
        shimmerGradient: LinearGradient(
          colors: [
            lightTheme.colorScheme.onInverseSurface,
            lightTheme.colorScheme.surfaceVariant,
            lightTheme.colorScheme.onInverseSurface,
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
        darkShimmerGradient: LinearGradient(
          colors: [
            darkTheme.colorScheme.onInverseSurface,
            darkTheme.colorScheme.surfaceVariant,
            darkTheme.colorScheme.onInverseSurface,
          ],
          stops: const [0.1, 0.5, 0.9],
          begin: const Alignment(-2.4, -0.2),
          end: const Alignment(2.4, 0.2),
          tileMode: TileMode.clamp,
        ),
        child: !_isDatabaseLoaded ? const SplashScreen() : const HomeScreen(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    var seedColor = Colors.lightBlue;
    var colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    var baseTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.onInverseSurface,
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme),
    );
  }

  _initializeDatabase() async {
    var wait = Wait(duration: const Duration(seconds: 1));
    await Provider.of<Preferences>(context, listen: false).loadDatabase();
    await wait.wait();
    setState(() {
      _isDatabaseLoaded = true;
    });
  }
}
