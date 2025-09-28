import 'package:flutter/material.dart';
import 'package:mttn_map/widgets/map_widget.dart';

final GlobalKey<MapWidgetState> mapKey = GlobalKey<MapWidgetState>();

List<IconData> mapButtonIcons = [
  Icons.home_rounded,
  Icons.north_rounded,
  Icons.add_rounded,
  Icons.remove_rounded,
];
List mapButtonFunctions = [
  () => mapKey.currentState?.resetMapToHome(),
  () => mapKey.currentState?.resetMapRotation(),
  () => mapKey.currentState?.zoomMapIn(),
  () => mapKey.currentState?.zoomMapOut(),
];

class MapViewPage extends StatelessWidget {
  const MapViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Stack(
          alignment: AlignmentGeometry.bottomRight,
          children: [
            MapWidget(key: mapKey),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 5,
                children: [
                  ...List.generate(mapButtonIcons.length, (index) {
                    return IconButton.filled(
                      onPressed: () => mapButtonFunctions[index](),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withAlpha(200),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(mapButtonIcons[index], size: 32),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
