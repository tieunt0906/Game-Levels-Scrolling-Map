import 'package:flutter/material.dart';
import 'package:game_levels_scrolling_map/game_levels_scrolling_map.dart';
import 'package:game_levels_scrolling_map/model/point_model.dart';
import 'package:game_levels_scrolling_map_example/get_list_point_model.dart';

class MapHorizontalExample extends StatefulWidget {
  const MapHorizontalExample({Key? key}) : super(key: key);

  @override
  State<MapHorizontalExample> createState() => _MapHorizontalExampleState();
}

class _MapHorizontalExampleState extends State<MapHorizontalExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: GameLevelsScrollingMap.scrollable(
          imageUrl: "assets/drawable/map_horizontal.png",
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
        '24.26 381.2 306.13 381.2 193.79 176.95 455.23 66.65 755.49 119.76 532.85 516.01 851.49 562.99 882.13 403.67 1411.15 366.9 1290.64 176.95 1874.81 136.1 1631.74 509.88 1954.47 562.99 1989.19 407.76 2150.55 385.29';
    points = getListPointModel(data);
  }

  Widget testWidget(int order) {
    return InkWell(
      hoverColor: Colors.blue,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/drawable/map_horizontal_point.png",
            fit: BoxFit.fitWidth,
            width: 100,
          ),
          Text("$order",
              style: const TextStyle(color: Colors.black, fontSize: 40))
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
