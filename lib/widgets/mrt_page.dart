import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
// import 'package:provider/provider.dart';
// import 'package:dijkstra/dijkstra.dart';

import '../constants.dart' show mrtImagePath;
// import '../preferences.dart';

class MrtPage extends StatefulWidget {
  const MrtPage({Key? key}) : super(key: key);

  @override
  State<MrtPage> createState() => _MrtPageState();
}

class _MrtPageState extends State<MrtPage> {
  @override
  void initState() {
    super.initState();

    // _initializeGraph();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PhotoView(
            wantKeepAlive: true,
            imageProvider: const AssetImage(mrtImagePath),
          ),
        ),
      ],
    );
  }

  // _initializeGraph() async {
  //   var mrtStations = await Provider.of<Preferences>(context, listen: false)
  //       .database
  //       .getMrtStations();
  // }
}
