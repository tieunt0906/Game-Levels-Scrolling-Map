import 'package:flutter/material.dart';

class PointModel {
  double? width;
  Widget? child;
  bool? isCurrent;

  PointModel(this.width, this.child, {this.isCurrent = false});

  PointModel.fromJson(Map<String, dynamic> json) {
    width = json['Width'];
    child = json['Child'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Width'] = width;
    data['Child'] = child;
    return data;
  }

  @override
  bool operator ==(covariant PointModel other) {
    return width == other.width && isCurrent == other.isCurrent;
  }

  @override
  int get hashCode => Object.hashAll(
        [
          width,
          isCurrent,
        ],
      );
}
