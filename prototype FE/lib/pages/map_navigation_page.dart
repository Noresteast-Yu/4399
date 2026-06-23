import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class MapNavigationPage extends StatefulWidget {
  const MapNavigationPage({super.key});

  @override
  State<MapNavigationPage> createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage> {
  late AMapController _mapController;
  LatLng _currentLocation = const LatLng(39.9042, 116.4074); // 默认北京
  List<LatLng> _routePoints = [
    const LatLng(39.9042, 116.4074),
    const LatLng(39.9142, 116.4174),
    const LatLng(39.9242, 116.4274),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化定位
    _initLocation();
  }
  
  void _initLocation() {
    // 这里可以添加定位初始化代码
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '地图导航'),
      body: Column(
        children: [
          // 地图容器
          Expanded(
            child: AMapWidget(
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                // 添加路线
                _addRoute();
              },
              markers: {
                Marker(
                  markerId: const MarkerId('start'),
                  position: _routePoints[0],
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                Marker(
                  markerId: const MarkerId('end'),
                  position: _routePoints[_routePoints.length - 1],
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              },
              polylines: {
                _routePolyline,
              },
            ),
          ),
          // 导航控制栏
          Container(
            padding: EdgeInsets.all(AppTheme.spacingM),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // 开始导航
                  },
                  child: const Text('开始导航'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 暂停导航
                  },
                  child: const Text('暂停'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 结束导航
                  },
                  child: const Text('结束'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 路线Polyline
  final Polyline _routePolyline = Polyline(
    polylineId: const PolylineId('route'),
    points: [
      const LatLng(39.9042, 116.4074),
      const LatLng(39.9142, 116.4174),
      const LatLng(39.9242, 116.4274),
    ],
    width: 5,
    color: AppTheme.primaryColor,
  );

  void _addRoute() {
    // 路线已在AMapWidget的polylines参数中设置
  }
}
