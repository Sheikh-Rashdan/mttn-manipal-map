import 'package:flutter/material.dart';
import 'package:mttn_map/views/pages/map_view_page.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MTTN Manipal Map'), centerTitle: true),
      body: MapViewPage(),
    );
  }
}
