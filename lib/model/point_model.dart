class PointModel {
  final double top;
  final double left;
  final double width;
  final bool isCurrent;

  PointModel({
    required this.top,
    required this.left,
    required this.width,
    this.isCurrent = false,
  });

  @override
  bool operator ==(covariant PointModel other) {
    return top == other.top &&
        left == other.left &&
        width == other.width &&
        isCurrent == other.isCurrent;
  }

  @override
  int get hashCode => Object.hashAll(
        [
          top,
          left,
          width,
          isCurrent,
        ],
      );
}
