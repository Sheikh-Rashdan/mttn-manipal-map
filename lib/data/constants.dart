import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KConstants {
  static const LatLng manipalLatLng = LatLng(13.3524, 74.78725);
  static const String userAgentPackageName = 'com.MTTN.app';
  static LatLngBounds mapBounds = LatLngBounds.fromPoints([
    LatLng(13.298313, 74.837845),
    LatLng(13.409764, 74.658201),
    LatLng(13.409764, 74.658201),
    LatLng(13.298313, 74.837845),
  ]);

  static const double minMapZoom = 14;
  static const double maxMapZoom = 20;
  static const double labelVisibleZoom = 15;

  static const String markersKey = 'MarkersKey';
}
