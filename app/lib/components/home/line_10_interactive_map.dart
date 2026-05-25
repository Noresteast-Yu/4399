import 'package:flutter/material.dart';

class MetroStation {
  final String id;
  final String name;
  final double x;
  final double y;
  final List<String> transferLines;
  final int order;

  const MetroStation({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.transferLines = const [],
    required this.order,
  });
}

class MetroLine {
  final String lineId;
  final String lineName;
  final Color lineColor;
  final List<MetroStation> stations;

  const MetroLine({
    required this.lineId,
    required this.lineName,
    required this.lineColor,
    required this.stations,
  });
}

class Line10InteractiveMap extends StatefulWidget {
  final Function(String station, bool isStart)? onStationSelected;
  final String? initialStartStation;
  final String? initialEndStation;

  const Line10InteractiveMap({
    super.key,
    this.onStationSelected,
    this.initialStartStation,
    this.initialEndStation,
  });

  @override
  State<Line10InteractiveMap> createState() => _Line10InteractiveMapState();
}

class _Line10InteractiveMapState extends State<Line10InteractiveMap> {
  String? _selectedStartStation;
  String? _selectedEndStation;
  String? _hoveredStation;
  final TransformationController _thumbnailController =
      TransformationController();

  static const Color line2Color = Color(0xFF8CC63F);
  static const Color line10Color = Color(0xFFC5A3FF);
  static const Color line11Color = Color(0xFF7A3E2F);

  late final List<MetroLine> _metroLines;

  @override
  void initState() {
    super.initState();
    _selectedStartStation = widget.initialStartStation;
    _selectedEndStation = widget.initialEndStation;
    _metroLines = _initializeLines();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final containerWidth = renderBox.size.width;

      const contentWidth = 2000.0;
      const contentHeight = 1200.0;
      const visibleHeight = 650.0;

      final scaleX = (containerWidth - 40) / contentWidth;
      final scaleY = (visibleHeight - 40) / contentHeight;
      final initialScale = (scaleX < scaleY ? scaleX : scaleY) * 0.8;

      final scaledWidth = contentWidth * initialScale;
      final scaledHeight = contentHeight * initialScale;
      // 居中放置
      final translateX = (containerWidth - scaledWidth) / 2;
      final translateY = (visibleHeight - scaledHeight) / 2;

      final matrix = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(initialScale);
      _thumbnailController.value = matrix;
    });
  }

  @override
  void dispose() {
    _thumbnailController.dispose();
    super.dispose();
  }

  void _openFullScreenMap() {
    final colorScheme = Theme.of(context).colorScheme;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: colorScheme.scrim.withOpacity(0.8),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenMetroMap(
            selectedStartStation: _selectedStartStation,
            selectedEndStation: _selectedEndStation,
            metroLines: _metroLines,
            onStationSelected: (station, isStart) {
              setState(() {
                if (isStart) {
                  _selectedStartStation = station;
                } else {
                  _selectedEndStation = station;
                }
              });
              widget.onStationSelected?.call(station, isStart);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  List<MetroLine> _initializeLines() {
    return [
      // 上海地铁2号线 - 横贯东西，连接浦东机场和徐泾东
      MetroLine(
        lineId: '2',
        lineName: '上海地铁2号线',
        lineColor: line2Color,
        stations: [
          const MetroStation(
              id: 'pudong_airport',
              name: '浦东国际机场',
              x: 1200 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 1),
          const MetroStation(
              id: 'yuanshen',
              name: '远东大道',
              x: 1170 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 2),
          const MetroStation(
              id: 'lingang',
              name: '凌空路',
              x: 1140 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 3),
          const MetroStation(
              id: 'huaxia',
              name: '华夏东路',
              x: 1110 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 4),
          const MetroStation(
              id: 'chuantang',
              name: '川沙',
              x: 1080 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 5),
          const MetroStation(
              id: 'shenjiang',
              name: '华夏镇',
              x: 1050 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 6),
          const MetroStation(
              id: 'shanghai_race_track',
              name: '创新中路',
              x: 1020 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 7),
          const MetroStation(
              id: 'guanglan_road',
              name: '广兰路',
              x: 990 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 8),
          const MetroStation(
              id: 'tianzhu_road',
              name: '唐镇',
              x: 960 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 9),
          const MetroStation(
              id: 'jinqiao_road',
              name: '创新路',
              x: 930 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 10),
          const MetroStation(
              id: 'jinyang_road',
              name: '金科路',
              x: 900 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 11),
          const MetroStation(
              id: 'zhangjiang_high_tech',
              name: '张江高科',
              x: 870 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 12),
          const MetroStation(
              id: 'longyang_road_2',
              name: '龙阳路',
              x: 840 + 500,
              y: 400 + 250,
              transferLines: ['7', '16', '18'],
              order: 13),
          const MetroStation(
              id: 'shanghai_science_tech',
              name: '上海科技馆',
              x: 810 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 14),
          const MetroStation(
              id: 'Century_Avenue',
              name: '世纪大道',
              x: 780 + 500,
              y: 400 + 250,
              transferLines: ['4', '6', '9'],
              order: 15),
          const MetroStation(
              id: 'dongchang_road',
              name: '东昌路',
              x: 750 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 16),
          const MetroStation(
              id: 'lujiazui',
              name: '陆家嘴',
              x: 720 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 17),
          const MetroStation(
              id: 'dongbei_road',
              name: '东门路',
              x: 690 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 18),
          const MetroStation(
              id: 'nanjing_east_road',
              name: '南京东路',
              x: 660 + 500,
              y: 400 + 250,
              transferLines: ['10'],
              order: 19),
          const MetroStation(
              id: 'renmin_square',
              name: '人民广场',
              x: 630 + 500,
              y: 400 + 250,
              transferLines: ['1', '8'],
              order: 20),
          const MetroStation(
              id: 'shimen_road',
              name: '石门一路',
              x: 600 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 21),
          const MetroStation(
              id: 'jingan_temple',
              name: '静安寺',
              x: 570 + 500,
              y: 400 + 250,
              transferLines: ['7'],
              order: 22),
          const MetroStation(
              id: 'west_nan_jing_road',
              name: '南京西路',
              x: 540 + 500,
              y: 400 + 250,
              transferLines: ['12', '13'],
              order: 23),
          const MetroStation(
              id: 'jiashan_road',
              name: '静安寺',
              x: 510 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 24),
          const MetroStation(
              id: 'jiangsu_road',
              name: '江苏路',
              x: 480 + 500,
              y: 400 + 250,
              transferLines: ['11'],
              order: 25),
          const MetroStation(
              id: 'zhongshan_park',
              name: '中山公园',
              x: 450 + 500,
              y: 400 + 250,
              transferLines: ['3', '4'],
              order: 26),
          const MetroStation(
              id: 'longxu_road',
              name: '龙路',
              x: 420 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 27),
          const MetroStation(
              id: 'caobao_road',
              name: '漕宝路',
              x: 390 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 28),
          const MetroStation(
              id: 'xujingdong',
              name: '徐泾东',
              x: 360 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 29),
          const MetroStation(
              id: 'hongqiao_railway_2',
              name: '虹桥火车站',
              x: 330 + 500,
              y: 400 + 250,
              transferLines: ['10', '17'],
              order: 30),
          const MetroStation(
              id: 'hongqiao_t2_2',
              name: '虹桥2号航站楼',
              x: 300 + 500,
              y: 400 + 250,
              transferLines: ['10'],
              order: 31),
          const MetroStation(
              id: 'songhong_road',
              name: '淞虹路',
              x: 270 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 32),
          const MetroStation(
              id: 'beixinjing',
              name: '北新泾',
              x: 240 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 33),
          const MetroStation(
              id: 'weining_road',
              name: '威宁路',
              x: 210 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 34),
          const MetroStation(
              id: 'loushanguan_road',
              name: '娄山关路',
              x: 180 + 500,
              y: 400 + 250,
              transferLines: [],
              order: 35),
        ],
      ),
      // 上海地铁10号线 - 东北西南走向
      MetroLine(
        lineId: '10',
        lineName: '上海地铁10号线',
        lineColor: line10Color,
        stations: [
          const MetroStation(
              id: 'hongqiao_railway_10',
              name: '虹桥火车站',
              x: 830,
              y: 650,
              transferLines: ['2', '17'],
              order: 1),
          const MetroStation(
              id: 'hongqiao_t2_10',
              name: '虹桥2号航站楼',
              x: 800,
              y: 650,
              transferLines: ['2'],
              order: 2),
          const MetroStation(
              id: 'hongqiao_t1_10',
              name: '虹桥1号航站楼',
              x: 770,
              y: 630,
              transferLines: [],
              order: 3),
          const MetroStation(
              id: 'shanghai_zoo',
              name: '上海动物园',
              x: 740,
              y: 610,
              transferLines: [],
              order: 4),
          const MetroStation(
              id: 'longxi_road',
              name: '龙溪路',
              x: 710,
              y: 590,
              transferLines: [],
              order: 5),
          const MetroStation(
              id: 'shuicheng_road',
              name: '水城路',
              x: 680,
              y: 570,
              transferLines: [],
              order: 6),
          const MetroStation(
              id: 'yili_road',
              name: '伊犁路',
              x: 650,
              y: 550,
              transferLines: [],
              order: 7),
          const MetroStation(
              id: 'songyuan_road',
              name: '宋园路',
              x: 620,
              y: 530,
              transferLines: [],
              order: 8),
          const MetroStation(
              id: 'hongqiao_road',
              name: '虹桥路',
              x: 590,
              y: 510,
              transferLines: ['3', '4'],
              order: 9),
          const MetroStation(
              id: 'jiaotong_university',
              name: '交通大学',
              x: 560,
              y: 490,
              transferLines: ['11'],
              order: 10),
          const MetroStation(
              id: 'shanghai_library',
              name: '上海图书馆',
              x: 530,
              y: 470,
              transferLines: [],
              order: 11),
          const MetroStation(
              id: 'shaanxi_south_road',
              name: '陕西南路',
              x: 500,
              y: 450,
              transferLines: ['1', '12'],
              order: 12),
          const MetroStation(
              id: 'xin_tian_di',
              name: '一大会址·新天地',
              x: 470,
              y: 430,
              transferLines: ['13'],
              order: 13),
          const MetroStation(
              id: 'lao_xi_men',
              name: '老西门',
              x: 440,
              y: 410,
              transferLines: ['8'],
              order: 14),
          const MetroStation(
              id: 'yu_yuan',
              name: '豫园',
              x: 410,
              y: 390,
              transferLines: ['14'],
              order: 15),
          const MetroStation(
              id: 'nanjing_east_road_10',
              name: '南京东路',
              x: 380,
              y: 370,
              transferLines: ['2'],
              order: 16),
          const MetroStation(
              id: 'tian_tong_road',
              name: '天潼路',
              x: 350,
              y: 350,
              transferLines: ['12'],
              order: 17),
          const MetroStation(
              id: 'hai_lun_road',
              name: '海伦路',
              x: 320,
              y: 330,
              transferLines: ['4'],
              order: 18),
          const MetroStation(
              id: 'si_ping_road',
              name: '四平路',
              x: 290,
              y: 310,
              transferLines: ['8'],
              order: 19),
          const MetroStation(
              id: 'tong_ji_university',
              name: '同济大学',
              x: 260,
              y: 290,
              transferLines: [],
              order: 20),
          const MetroStation(
              id: 'jiang_wan_new_town',
              name: '江湾新城',
              x: 230,
              y: 270,
              transferLines: [],
              order: 21),
          const MetroStation(
              id: 'weng_jing',
              name: '殷高东路',
              x: 200,
              y: 250,
              transferLines: [],
              order: 22),
          const MetroStation(
              id: 'xin_jiang_wan_city',
              name: '新江湾城',
              x: 170,
              y: 230,
              transferLines: [],
              order: 23),
          const MetroStation(
              id: 'shuang_jiang_road',
              name: '三门路',
              x: 140,
              y: 210,
              transferLines: [],
              order: 24),
          const MetroStation(
              id: 'hang_hai_road',
              name: '殷行路',
              x: 110,
              y: 190,
              transferLines: [],
              order: 25),
          const MetroStation(
              id: 'xinquan_road',
              name: '新园路',
              x: 80,
              y: 170,
              transferLines: [],
              order: 26),
          const MetroStation(
              id: 'shanghai_north_railway_station',
              name: '江湾镇',
              x: 50,
              y: 150,
              transferLines: [],
              order: 27),
        ],
      ),
      // 上海地铁11号线 - 西北东南走向
      MetroLine(
        lineId: '11',
        lineName: '上海地铁11号线',
        lineColor: line11Color,
        stations: [
          const MetroStation(
              id: 'hua_qiao',
              name: '花桥',
              x: 900,
              y: 850,
              transferLines: [],
              order: 1),
          const MetroStation(
              id: 'jiading_new_town',
              name: '光明路',
              x: 930,
              y: 820,
              transferLines: [],
              order: 2),
          const MetroStation(
              id: 'bao_an_road',
              name: '兆丰路',
              x: 960,
              y: 790,
              transferLines: [],
              order: 3),
          const MetroStation(
              id: 'anting',
              name: '安亭',
              x: 990,
              y: 760,
              transferLines: [],
              order: 4),
          const MetroStation(
              id: 'che_ding_zhen',
              name: '上海赛车场',
              x: 1020,
              y: 730,
              transferLines: [],
              order: 5),
          const MetroStation(
              id: 'jiading_new_city',
              name: '嘉定新城',
              x: 1050,
              y: 700,
              transferLines: [],
              order: 6),
          const MetroStation(
              id: 'jiading_old_town',
              name: '白银路',
              x: 1080,
              y: 670,
              transferLines: [],
              order: 7),
          const MetroStation(
              id: 'jiading_beilu',
              name: '嘉定北',
              x: 1110,
              y: 640,
              transferLines: [],
              order: 8),
          const MetroStation(
              id: 'nan_xiang',
              name: '南翔',
              x: 1140,
              y: 610,
              transferLines: [],
              order: 9),
          const MetroStation(
              id: 'ma_lu',
              name: '马陆',
              x: 1170,
              y: 580,
              transferLines: [],
              order: 10),
          const MetroStation(
              id: 'jiang_su_road_11',
              name: '桃浦新村',
              x: 1200,
              y: 550,
              transferLines: ['2'],
              order: 11),
          const MetroStation(
              id: 'wan_li_road',
              name: '武威路',
              x: 1230,
              y: 520,
              transferLines: [],
              order: 12),
          const MetroStation(
              id: 'qilian_mountain_road',
              name: '祁连山路',
              x: 1260,
              y: 490,
              transferLines: [],
              order: 13),
          const MetroStation(
              id: 'caoyang_road',
              name: '曹杨路',
              x: 1290,
              y: 460,
              transferLines: ['3', '4'],
              order: 14),
          const MetroStation(
              id: 'long_de_road',
              name: '隆德路',
              x: 1320,
              y: 430,
              transferLines: ['3', '4'],
              order: 15),
          const MetroStation(
              id: 'jiang_su_road',
              name: '江苏路',
              x: 1350,
              y: 400,
              transferLines: ['2'],
              order: 16),
          const MetroStation(
              id: 'jiao_tong_da_xue',
              name: '交通大学',
              x: 1380,
              y: 370,
              transferLines: ['10'],
              order: 17),
          const MetroStation(
              id: 'xu_jia_hui',
              name: '徐家汇',
              x: 1410,
              y: 340,
              transferLines: ['1', '9'],
              order: 18),
          const MetroStation(
              id: 'long_cao_road',
              name: '龙漕路',
              x: 1440,
              y: 310,
              transferLines: ['3', '12'],
              order: 19),
          const MetroStation(
              id: 'shang_hai_sports',
              name: '上海游泳馆',
              x: 1470,
              y: 280,
              transferLines: [],
              order: 20),
          const MetroStation(
              id: 'zhi_pu_road',
              name: '肇嘉浜路',
              x: 1500,
              y: 250,
              transferLines: ['7'],
              order: 21),
          const MetroStation(
              id: 'yuyao_road',
              name: '宜山路',
              x: 1530,
              y: 220,
              transferLines: ['3', '4', '9'],
              order: 22),
          const MetroStation(
              id: 'long_hua',
              name: '龙华',
              x: 1560,
              y: 190,
              transferLines: [],
              order: 23),
          const MetroStation(
              id: 'long_hua_middle',
              name: '龙华中路',
              x: 1590,
              y: 160,
              transferLines: ['12'],
              order: 24),
          const MetroStation(
              id: 'lu_jia_bang_road',
              name: '龙耀路',
              x: 1620,
              y: 130,
              transferLines: [],
              order: 25),
          const MetroStation(
              id: 'huating_road',
              name: '云锦路',
              x: 1650,
              y: 100,
              transferLines: [],
              order: 26),
          const MetroStation(
              id: 'long_arcs',
              name: '龙腾大道',
              x: 1680,
              y: 70,
              transferLines: [],
              order: 27),
          const MetroStation(
              id: 'pujiang_zhen',
              name: '东方体育中心',
              x: 1710,
              y: 40,
              transferLines: ['6', '8'],
              order: 28),
        ],
      ),
    ];
  }

  List<MetroStation> _getAllUniqueStations() {
    final unique = <String, MetroStation>{};
    for (final line in _metroLines) {
      for (final station in line.stations) {
        unique[station.name] = station;
      }
    }
    return unique.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Color _getLineColor(String line) {
    const lineColors = {
      '1': Color(0xFFE4002B),
      '2': line2Color,
      '3': Color(0xFFFFD100),
      '4': Color(0xFF5F259F),
      '7': Color(0xFFED6D00),
      '8': Color(0xFF009BDE),
      '9': Color(0xFF71B42B),
      '10': line10Color,
      '11': line11Color,
      '12': Color(0xFF007A3D),
      '13': Color(0xFFF4A6C8),
      '14': Color(0xFFB2A72C),
      '16': Color(0xFF00B5AD),
      '17': Color(0xFFB08A00),
      '18': Color(0xFFC8A45D),
    };
    return lineColors[line] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: line2Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '2号线',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: line10Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '10号线',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: line11Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '11号线',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_selectedStartStation != null || _selectedEndStation != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStartStation = null;
                      _selectedEndStation = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('清除'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedStartStation != null || _selectedEndStation != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (_selectedStartStation != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.trip_origin,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedStartStation!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_selectedStartStation != null &&
                      _selectedEndStation != null)
                    const SizedBox(width: 8),
                  if (_selectedEndStation != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag,
                                size: 16,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedEndStation!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Container(
            height: 650,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InteractiveViewer(
                  transformationController: _thumbnailController,
                  minScale: 0.1,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: SizedBox(
                    width: 2000,
                    height: 1200,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: const Size(2000, 1200),
                          painter: _MultiLineMetroPainter(
                            lines: _metroLines,
                            startStation: _selectedStartStation,
                            endStation: _selectedEndStation,
                            hoveredStation: _hoveredStation,
                          ),
                        ),
                        ..._buildStationWidgets(_getAllUniqueStations()),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _openFullScreenMap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fullscreen,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '点击放大',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('始发站', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('终点站', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 3,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  const Text('规划路线', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  List<Widget> _buildStationWidgets(List<MetroStation> stations) {
    return stations.map((station) {
      final isStart = _selectedStartStation == station.name;
      final isEnd = _selectedEndStation == station.name;
      final isHovered = _hoveredStation == station.name;
      final isTransfer = station.transferLines.isNotEmpty;
      final isSelected = isStart || isEnd;

      double nodeRadius = isTransfer ? 14 : 10;
      if (isSelected) nodeRadius = 16;

      Color nodeColor = Colors.grey.shade700;
      if (isStart) nodeColor = Colors.green;
      if (isEnd) nodeColor = Colors.red;
      if (isHovered) nodeColor = Colors.blue.withOpacity(0.7);

      final hasTransferLines = isTransfer && station.transferLines.isNotEmpty;

      return Positioned(
        left: station.x - nodeRadius - 4,
        top: station.y - nodeRadius - 4,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() {
              _hoveredStation = station.name;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredStation = null;
            });
          },
          child: GestureDetector(
            onTap: () => _selectStation(station.name),
            child: Container(
              width: nodeRadius * 2 + 8,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: nodeRadius * 2,
                    height: nodeRadius * 2,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: nodeColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isTransfer
                        ? const Icon(Icons.transfer_within_a_station,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                  if (hasTransferLines)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        runSpacing: 1,
                        children: station.transferLines.map((line) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getLineColor(line),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '$line号线',
                              style: const TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? nodeColor.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? nodeColor : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      station.name,
                      style: TextStyle(
                        fontSize: isSelected ? 11 : 9,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? nodeColor : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _selectStation(String stationName) {
    setState(() {
      if (_selectedStartStation == null || _selectedEndStation != null) {
        if (_selectedEndStation != null) {
          _selectedStartStation = stationName;
          _selectedEndStation = null;
        } else {
          _selectedStartStation = stationName;
        }
      } else {
        if (_selectedStartStation == stationName) {
          _selectedStartStation = null;
        } else {
          _selectedEndStation = stationName;
        }
      }
    });
    widget.onStationSelected?.call(stationName, _selectedEndStation == null);
  }
}

class _MultiLineMetroPainter extends CustomPainter {
  final List<MetroLine> lines;
  final String? startStation;
  final String? endStation;
  final String? hoveredStation;

  _MultiLineMetroPainter({
    required this.lines,
    this.startStation,
    this.endStation,
    this.hoveredStation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final highlightPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      final linePoints = line.stations.map((s) => Offset(s.x, s.y)).toList();

      final linePaint = Paint()
        ..color = line.lineColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final startStationIndex = startStation != null
          ? line.stations.indexWhere((s) => s.name == startStation)
          : -1;
      final endStationIndex = endStation != null
          ? line.stations.indexWhere((s) => s.name == endStation)
          : -1;

      if (startStationIndex >= 0 && endStationIndex >= 0) {
        final fromIndex = startStationIndex < endStationIndex
            ? startStationIndex
            : endStationIndex;
        final toIndex = startStationIndex < endStationIndex
            ? endStationIndex
            : startStationIndex;

        final path = Path();
        path.moveTo(linePoints[fromIndex].dx, linePoints[fromIndex].dy);
        for (int i = fromIndex + 1; i <= toIndex; i++) {
          path.lineTo(linePoints[i].dx, linePoints[i].dy);
        }
        canvas.drawPath(path, highlightPaint);
      }

      final path = Path();
      path.moveTo(linePoints[0].dx, linePoints[0].dy);
      for (int i = 1; i < linePoints.length; i++) {
        path.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final allStations = <MetroStation>{};
    for (final line in lines) {
      allStations.addAll(line.stations);
    }

    for (final station in allStations) {
      final isTransfer = station.transferLines.isNotEmpty;

      if (isTransfer) {
        final transferPaint = Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(station.x, station.y), 18, transferPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineMetroPainter oldDelegate) {
    return oldDelegate.startStation != startStation ||
        oldDelegate.endStation != endStation ||
        oldDelegate.hoveredStation != hoveredStation;
  }
}

class _FullScreenMetroMap extends StatefulWidget {
  final String? selectedStartStation;
  final String? selectedEndStation;
  final List<MetroLine> metroLines;
  final Function(String station, bool isStart) onStationSelected;

  const _FullScreenMetroMap({
    this.selectedStartStation,
    this.selectedEndStation,
    required this.metroLines,
    required this.onStationSelected,
  });

  @override
  State<_FullScreenMetroMap> createState() => _FullScreenMetroMapState();
}

class _FullScreenMetroMapState extends State<_FullScreenMetroMap> {
  final TransformationController _transformationController =
      TransformationController();
  String? _selectedStartStation;
  String? _selectedEndStation;
  String? _hoveredStation;

  @override
  void initState() {
    super.initState();
    _selectedStartStation = widget.selectedStartStation;
    _selectedEndStation = widget.selectedEndStation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      const contentWidth = 2000.0;
      const contentHeight = 1200.0;

      final scaleX = screenSize.width / contentWidth;
      final scaleY = screenSize.height / contentHeight;
      final initialScale = (scaleX < scaleY ? scaleX : scaleY) * 0.8;

      final scaledWidth = contentWidth * initialScale;
      final scaledHeight = contentHeight * initialScale;
      final translateX = (screenSize.width - scaledWidth) / 2;
      final translateY = (screenSize.height - scaledHeight) / 2;

      final matrix = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(initialScale);
      _transformationController.value = matrix;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  List<MetroStation> _getAllUniqueStations() {
    final unique = <String, MetroStation>{};
    for (final line in widget.metroLines) {
      for (final station in line.stations) {
        unique[station.name] = station;
      }
    }
    return unique.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Color _getLineColor(String line) {
    const lineColors = {
      '1': Color(0xFFE4002B),
      '2': Color(0xFF8CC63F),
      '3': Color(0xFFFFD100),
      '4': Color(0xFF5F259F),
      '7': Color(0xFFED6D00),
      '8': Color(0xFF009BDE),
      '9': Color(0xFF71B42B),
      '10': Color(0xFFC5A3FF),
      '11': Color(0xFF7A3E2F),
      '12': Color(0xFF007A3D),
      '13': Color(0xFFF4A6C8),
      '14': Color(0xFFB2A72C),
      '16': Color(0xFF00B5AD),
      '17': Color(0xFFB08A00),
      '18': Color(0xFFC8A45D),
    };
    return lineColors[line] ?? Colors.grey;
  }

  void _selectStation(String stationName) {
    setState(() {
      if (_selectedStartStation == null || _selectedEndStation != null) {
        if (_selectedEndStation != null) {
          _selectedStartStation = stationName;
          _selectedEndStation = null;
        } else {
          _selectedStartStation = stationName;
        }
      } else {
        if (_selectedStartStation == stationName) {
          _selectedStartStation = null;
        } else {
          _selectedEndStation = stationName;
        }
      }
    });
    widget.onStationSelected(stationName, _selectedEndStation == null);
  }

  List<Widget> _buildStationWidgets(List<MetroStation> stations) {
    return stations.map((station) {
      final isStart = _selectedStartStation == station.name;
      final isEnd = _selectedEndStation == station.name;
      final isHovered = _hoveredStation == station.name;
      final isTransfer = station.transferLines.isNotEmpty;
      final isSelected = isStart || isEnd;

      double nodeRadius = isTransfer ? 18 : 14;
      if (isSelected) nodeRadius = 20;

      Color nodeColor = Colors.grey.shade700;
      if (isStart) nodeColor = Colors.green;
      if (isEnd) nodeColor = Colors.red;
      if (isHovered) nodeColor = Colors.blue.withOpacity(0.7);

      final hasTransferLines = isTransfer && station.transferLines.isNotEmpty;

      return Positioned(
        left: station.x - nodeRadius - 4,
        top: station.y - nodeRadius - 4,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() {
              _hoveredStation = station.name;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredStation = null;
            });
          },
          child: GestureDetector(
            onTap: () => _selectStation(station.name),
            child: Container(
              width: nodeRadius * 2 + 8,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: nodeRadius * 2,
                    height: nodeRadius * 2,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: nodeColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isTransfer
                        ? const Icon(Icons.transfer_within_a_station,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                  if (hasTransferLines)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        runSpacing: 1,
                        children: station.transferLines.map((line) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLineColor(line),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '$line号线',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? nodeColor.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? nodeColor : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      station.name,
                      style: TextStyle(
                        fontSize: isSelected ? 14 : 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? nodeColor : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.3,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Center(
              child: SizedBox(
                width: 2000,
                height: 1200,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(2000, 1200),
                      painter: _MultiLineMetroPainter(
                        lines: widget.metroLines,
                        startStation: _selectedStartStation,
                        endStation: _selectedEndStation,
                        hoveredStation: _hoveredStation,
                      ),
                    ),
                    ..._buildStationWidgets(_getAllUniqueStations()),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon:
                      Icon(Icons.close, color: colorScheme.onSurface, size: 28),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.scrim.withOpacity(0.54),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_out_map,
                          color: colorScheme.onSurface, size: 24),
                      onPressed: () {
                        _transformationController.value = Matrix4.identity()
                          ..scale(1.0);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withOpacity(0.54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: Colors.white, size: 24),
                      onPressed: () {
                        setState(() {
                          _selectedStartStation = null;
                          _selectedEndStation = null;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withOpacity(0.54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_selectedStartStation != null ||
                    _selectedEndStation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (_selectedStartStation != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trip_origin,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedStartStation!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedStartStation = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_selectedStartStation != null &&
                            _selectedEndStation != null)
                          const SizedBox(width: 8),
                        if (_selectedEndStation != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 16,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedEndStation!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEndStation = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('始发站', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('终点站', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 3,
                        color: colorScheme.primaryContainer,
                      ),
                      const SizedBox(width: 6),
                      const Text('规划路线', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
