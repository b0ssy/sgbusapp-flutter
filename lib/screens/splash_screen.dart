import 'package:flutter/material.dart';

import '../constants.dart' show icon3Path;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            Image.asset(icon3Path),
            const CircularProgressIndicator(),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Starting application...',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
