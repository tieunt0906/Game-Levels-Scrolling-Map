import 'package:game_levels_scrolling_map/model/point_model.dart';

List<PointModel> getListPointModel(String data) {
  final List<String> arrayOfPoints = data.split(' ');

  final List<double> xValues = [];
  final List<double> yValues = [];

  for (int i = 0; i < arrayOfPoints.length; i++) {
    if (i % 2 == 0) {
      xValues.add(double.parse(arrayOfPoints[i]));
    } else {
      yValues.add(double.parse(arrayOfPoints[i]));
    }
  }

  final List<PointModel> points = [];

  for (int i = 0; i < xValues.length; i++) {
    points.add(
      PointModel(
        top: yValues[i],
        left: xValues[i],
        width: 100,
      ),
    );
  }

  return points;
}
