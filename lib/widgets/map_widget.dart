import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:mttn_map/data/constants.dart';
import 'package:mttn_map/data/notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkerInfo {
  MarkerInfo(this.point, this.label);
  LatLng point;
  String label;

  Map<String, dynamic> toJson() => {
    'lat': point.latitude,
    'lng': point.longitude,
    'label': label,
  };

  factory MarkerInfo.fromJson(Map<String, dynamic> json) =>
      MarkerInfo(LatLng(json['lat'], json['lng']), json['label']);
}

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    initMarkers();
  }

  void initMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? markersJsonString = prefs.getString(KConstants.markersKey);
    if (markersJsonString == null) return;
    setState(() {
      _markers = (jsonDecode(markersJsonString) as List)
          .map((markerInfoJson) => MarkerInfo.fromJson(markerInfoJson))
          .toList();
    });
  }

  void _saveMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
      KConstants.markersKey,
      jsonEncode(_markers.map((markerInfo) => markerInfo.toJson()).toList()),
    );
  }

  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(vsync: this);

  late List<MarkerInfo> _markers = [];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _animatedMapController.mapController,
      options: MapOptions(
        initialCenter: KConstants.manipalLatLng,
        initialZoom: mapZoomNotifier.value,
        minZoom: KConstants.minMapZoom,
        maxZoom: KConstants.maxMapZoom,
        cameraConstraint: CameraConstraint.contain(
          bounds: KConstants.mapBounds,
        ),
        onMapEvent: (MapEvent mapEvent) {
          setState(() {
            mapZoomNotifier.value = mapEvent.camera.zoom;
          });
        },
        onTap: (tapPosition, LatLng point) => _handleMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: KConstants.userAgentPackageName,
        ),
        MarkerLayer(markers: _buildMarkerIcons()),
        if (mapZoomNotifier.value > KConstants.labelVisibleZoom)
          MarkerLayer(markers: _buildMarkerLabels()),
        RichAttributionWidget(
          popupBackgroundColor: Colors.black.withAlpha(200),
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  List<Marker> _buildMarkerIcons() {
    return _markers.map((markerInfo) {
      return Marker(
        width: 150,
        height: 150,
        point: markerInfo.point,
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(bottom: mapZoomNotifier.value * 3),
          child: GestureDetector(
            onTap: () => _displayMarkerEdit(markerInfo),
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: mapZoomNotifier.value * 3,
              shadows: [BoxShadow(offset: Offset(0, 2), blurRadius: 5)],
            ),
          ),
        ),
        rotate: true,
      );
    }).toList();
  }

  List<Marker> _buildMarkerLabels() {
    return _markers.map((markerInfo) {
      return Marker(
        width: 300,
        height: 300,
        point: markerInfo.point,
        child: Padding(
          padding: EdgeInsetsGeometry.only(
            bottom: mapZoomNotifier.value * 3 * 2.75,
          ),
          child: Center(
            child: Card(
              color: Colors.black.withAlpha(120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                child: FittedBox(
                  child: Text(
                    markerInfo.label,
                    maxLines: 1,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
        rotate: true,
      );
    }).toList();
  }

  void _displayMarkerEdit(MarkerInfo markerInfo) {
    showDialog(
      context: context,
      builder: (context) {
        String oldMarkerLabel = markerInfo.label;
        TextEditingController labelEditingController = TextEditingController(
          text: markerInfo.label,
        );

        return AlertDialog(
          title: Text('Edit Marker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              TextField(
                controller: labelEditingController,
                decoration: InputDecoration(
                  hint: Text('Label'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => markerInfo.label = value,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _markers.remove(markerInfo);
                          _saveMarkers();
                          Navigator.pop(context);
                        });
                      },
                      child: Text('Delete Marker'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () {
                markerInfo.label = oldMarkerLabel;
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _saveMarkers();
                  Navigator.pop(context);
                });
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _handleMapTap(LatLng point) async {
    String? label = await _getMarkerLabel();
    if (label != null) {
      setState(() {
        _markers.add(MarkerInfo(point, label));
        _saveMarkers();
      });
    }
  }

  Future<String?> _getMarkerLabel() async {
    TextEditingController labelEditingController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Marker'),
          content: TextField(
            controller: labelEditingController,
            decoration: InputDecoration(
              hint: Text('Label'),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => labelEditingController.text = value,
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (labelEditingController.text.isNotEmpty) {
                  Navigator.pop(context, labelEditingController.text);
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void resetMapToHome() {
    setState(() {
      _animatedMapController.centerOnPoint(KConstants.manipalLatLng);
    });
  }

  void resetMapRotation() {
    setState(() {
      _animatedMapController.animatedRotateTo(0);
    });
  }

  void zoomMapIn() {
    setState(() {
      mapZoomNotifier.value = min(
        mapZoomNotifier.value + 0.5,
        KConstants.maxMapZoom,
      );
      _animatedMapController.animatedZoomTo(mapZoomNotifier.value);
    });
  }

  void zoomMapOut() {
    setState(() {
      mapZoomNotifier.value = max(
        mapZoomNotifier.value - 0.5,
        KConstants.minMapZoom,
      );
      _animatedMapController.animatedZoomTo(mapZoomNotifier.value);
    });
  }
}
