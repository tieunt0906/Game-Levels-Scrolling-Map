import 'package:flutter/material.dart';
import 'package:game_levels_scrolling_map/game_levels_scrolling_map.dart';
import 'package:game_levels_scrolling_map/model/point_model.dart';
import 'package:game_levels_scrolling_map_example/get_list_point_model.dart';

class MapVerticalExample extends StatefulWidget {
  const MapVerticalExample({Key? key}) : super(key: key);

  @override
  State<MapVerticalExample> createState() => _MapVerticalExampleState();
}

class _MapVerticalExampleState extends State<MapVerticalExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: GameLevelsScrollingMap.scrollable(
          imageUrl: "assets/drawable/map_vertical.png",
          direction: Axis.vertical,
          reverseScrolling: true,
          pointsPositionDeltaX: 25,
          pointsPositionDeltaY: 25,
          points: points,
          pointBuilder: (context, point, index) {
            return testWidget(index);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fillTestData();
  }

  List<PointModel> points = [];

  void fillTestData() {
    final data =
        '64.65 1837.97 259.71 1843.07 422.1 1843.07 570.18 1843.07 611.03 1759.33 566.1 1685.8 436.39 1679.67 288.31 1686.82 142.27 1691.93 54.44 1627.59 54.44 1541.8 118.78 1489.71 239.29 1489.71 368.99 1494.82 484.39 1525.46 497.67 1611.24 611.03 1639.84 688.65 1582.65 688.65 1510.14 688.65 1443.76 581.41 1272.18 624.31 1178.22 664.14 1103.67 703.97 1020.95 596.73 947.41 474.18 972.95 428.22 1055.67 509.93 1135.84 526.78 1233.88 434.86 1302.82 278.61 1318.14 120.82 1305.88 74.86 1233.88 234.18 1215.5 398.1 1213.97 410.35 1157.29 203.54 1097.54 105.5 1140.44 64.14 1060.78 177.5 1022.48 168.31 961.2 54.44 924.44 192.82 901.46 344.48 930.56 419.54 887.67 263.29 857.03 125.41 834.05 88.65 765.12 234.18 789.63 379.2 827.93 522.18 860.1 661.59 844.78 560.48 749.8 395.03 731.41 212.73 720.69 76.39 677.8 235.71 657.88 387.37 665.54 540.56 668.61 687.63 648.69 703.97 567.5 557.41 558.31 401.16 588.95 319.97 549.12 456.31 516.95 609.5 493.97 703.97 418.9 656.99 333.12 451.71 276.44 355.2 323.93 312.31 395.93 289.33 470.99 243.37 552.18 151.46 611.93 54.44 567.5 54.44 492.44 64.14 412.78 54.44 343.84 54.44 271.84 54.44 190.65 172.9 173.8 313.84 187.59 433.33 207.5 565.07 205.97';
    points = getListPointModel(data);
  }

  Widget testWidget(int order) {
    return InkWell(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/drawable/map_vertical_point.png",
            fit: BoxFit.fitWidth,
            width: 50,
          ),
          Text("$order",
              style: const TextStyle(color: Colors.black, fontSize: 15))
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("Point $order"),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
