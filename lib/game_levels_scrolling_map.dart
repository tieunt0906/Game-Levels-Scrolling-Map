library game_levels_scrolling_map;

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../helper/utils.dart';
import 'config/q.dart';
import 'helper/debug_print.dart';
import 'model/point_model.dart';
import 'widgets/loading_progress.dart';

typedef OnMapFilledCallback = Function(
  List<Offset> positions,
  List<double> scrollOffsets,
);

class GameLevelsScrollingMap extends StatefulWidget {
  final double? height;
  final double? width;

  final double? imageHeight;
  final double? imageWidth;

  final double? currentPointDeltaY;
  final String imageUrl;
  final String svgUrl;

  final List<double>? xValues;
  final List<double>? yValues;

  final List<PointModel>? points;

  final double pointsPositionDeltaX;
  final double pointsPositionDeltaY;

  final bool isScrollable;
  final Axis direction;
  final bool reverseScrolling;
  final ScrollPhysics? physics;

  final Widget? backgroundImageWidget;
  final Color? bgColor;
  final Duration scrollDuration;
  final EdgeInsets padding;
  final bool scrollToCurrent;
  final ScrollController? scrollController;
  final OnMapFilledCallback? onMapFilled;
  final Widget? maskWidget;

  const GameLevelsScrollingMap({
    super.key,
    this.imageUrl = '',
    this.height,
    required this.width,
    this.imageWidth,
    this.imageHeight,
    this.direction = Axis.horizontal,
    this.svgUrl = '',
    this.points,
    this.xValues,
    this.yValues,
    this.pointsPositionDeltaX = 0,
    this.pointsPositionDeltaY = 0,
    this.currentPointDeltaY,
    this.backgroundImageWidget,
    this.reverseScrolling = false,
    this.physics,
    this.bgColor,
    this.padding = EdgeInsets.zero,
    this.onMapFilled,
    this.maskWidget,
  })  : isScrollable = false,
        scrollDuration = Duration.zero,
        scrollToCurrent = false,
        scrollController = null;

  const GameLevelsScrollingMap.scrollable({
    super.key,
    this.imageUrl = '',
    this.width,
    this.height,
    this.imageWidth,
    this.imageHeight,
    this.direction = Axis.horizontal,
    this.currentPointDeltaY,
    this.svgUrl = '',
    this.points,
    this.xValues,
    this.yValues,
    this.pointsPositionDeltaX = 0,
    this.pointsPositionDeltaY = 0,
    this.reverseScrolling = false,
    this.physics,
    this.backgroundImageWidget,
    this.bgColor,
    this.scrollDuration = const Duration(milliseconds: 1000),
    this.padding = EdgeInsets.zero,
    this.scrollToCurrent = true,
    this.scrollController,
    this.onMapFilled,
    this.maskWidget,
  }) : isScrollable = true;

  @override
  _GameLevelsScrollingMapState createState() => _GameLevelsScrollingMapState();
}

class _GameLevelsScrollingMapState extends State<GameLevelsScrollingMap> {
  List<double> _newXValues = [];
  List<double> _newYValues = [];
  List<double> _xValues = [];
  List<double> _yValues = [];
  double _height = 0;
  double _width = 0;

  ScrollController? _scrollController;
  Key? _key;
  List<Widget> widgets = [];

  @override
  void initState() {
    super.initState();

    _key = widget.key ?? GlobalKey();

    if (widget.isScrollable) {
      _scrollController = widget.scrollController ?? ScrollController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      initDeviceDimensions();
      initDefaults();

      if (widget.svgUrl.isNotEmpty) {
        await _getPathFromSVG();
      }
      await _loadImage(path: widget.imageUrl);
      animateToPosition();
    });
  }

  @override
  void didUpdateWidget(covariant GameLevelsScrollingMap oldWidget) {
    if (const IterableEquality().equals(
      widget.points,
      oldWidget.points,
    )) {
      _newXValues.clear();
      _newYValues.clear();

      widgets.clear();
      widgets.add(backgroundImage());
      drawPoints();
    }

    super.didUpdateWidget(oldWidget);
  }

  void animateToPosition() {
    if (!widget.scrollToCurrent ||
        !widget.isScrollable ||
        widget.points == null) return;

    final currentIndex =
        widget.points!.indexWhere((point) => point.isCurrent ?? false);
    final points =
        widget.direction == Axis.vertical ? _newYValues : _newXValues;

    if (currentIndex == -1 || currentIndex >= points.length) return;

    _scrollController?.animateTo(
      points[currentIndex],
      duration: widget.scrollDuration,
      curve: Curves.easeIn,
    );
  }

  void initDeviceDimensions() {
    Q.deviceWidth = MediaQuery.of(context).size.width;
    Q.deviceHeight = MediaQuery.of(context).size.height;

    '${Q.TAG} Device Dimensions : ${Q.deviceWidth} x ${Q.deviceHeight}'.log();
  }

  void initDefaults() {
    _xValues = widget.xValues ?? [];
    _yValues = widget.yValues ?? [];
    _height = widget.height ?? Q.deviceHeight;
    if (widget.direction == Axis.vertical) {
      _width = widget.width ?? Q.deviceWidth;
    } else if (widget.direction == Axis.horizontal) {
      _width = widget.width ?? 0;
    }
    if (widget.width == double.infinity) {
      _width = Q.deviceWidth;
    }

    'widget.height : $_height'.log();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      key: widget.key ?? _key,
      color: widget.bgColor,
      width: _width != 0 ? _width : maxWidth,
      height: maxHeight,
      child: widget.isScrollable
          ? SingleChildScrollView(
              padding: widget.padding,
              physics: widget.physics,
              controller: _scrollController,
              scrollDirection: widget.direction,
              reverse: widget.reverseScrolling,
              child: aspectRatioWidget(),
            )
          : aspectRatioWidget(),
    );
  }

  Widget aspectRatioWidget() {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return imageWidth != 0
              ? Stack(
                  textDirection: TextDirection.ltr,
                  clipBehavior: Clip.none,
                  children: [
                    ...widgets,
                    if (widget.maskWidget != null) widget.maskWidget!,
                  ],
                )
              : const LoadingProgress();
        },
      ),
    );
  }

  bool isImageLoaded = false;

  double aspectRatio = 1;
  double imageWidth = 0;
  double imageHeight = 0;
  double maxWidth = 0;
  double maxHeight = 0;

  Completer<ui.Image> completer = Completer<ui.Image>();
  ImageStream? stream;
  ImageStreamListener? listener;
  Future<ui.Image> _loadImage({String path = ''}) async {
    if (path.isEmpty) {
      imageStreamListenerCallBack();
    } else {
      if (path.contains('assets')) {
        stream = AssetImage(path).resolve(ImageConfiguration.empty);
      } else {
        stream = NetworkImage(path).resolve(ImageConfiguration.empty);
      }

      listener = ImageStreamListener((ImageInfo frame, bool synchronousCall) {
        imageStreamListenerCallBack(
            frame: frame, synchronousCall: synchronousCall);
      });

      stream?.addListener(listener!);
    }
    return completer.future;
  }

  ui.Image? image;
  void imageStreamListenerCallBack({
    ImageInfo? frame,
    bool? synchronousCall,
  }) {
    if (frame != null) {
      image = frame.image;
    }
    imageWidth = widget.imageWidth ?? image!.width.toDouble();
    imageHeight = widget.imageHeight ?? image!.height.toDouble();

    if (imageWidth == 0 || imageHeight == 0) return;

    '${Q.TAG} image path : ${widget.imageUrl}'.log();
    '${Q.TAG} image dimensions : $imageWidth x $imageHeight'.log();

    aspectRatio = imageWidth / imageHeight;

    if (widget.isScrollable) {
      if (widget.direction == Axis.horizontal) {
        maxHeight = _height;
        maxWidth = maxHeight * aspectRatio;
      } else if (widget.direction == Axis.vertical) {
        maxWidth = _width;
        maxHeight = maxWidth / aspectRatio;
      }
    } else {
      maxWidth = _width;
      maxHeight = maxWidth / aspectRatio;
    }

    '${Q.TAG} image all dimensions : $imageWidth : $imageHeight : $aspectRatio'
        .log();

    '${Q.TAG} image new dimensions : $maxWidth : $maxHeight : $aspectRatio'
        .log();

    widgets.add(backgroundImage());
    drawPoints();

    if (image != null) {
      completer.complete(image);
      stream?.removeListener(listener!);
    }

    setState(() => {});
  }

  Widget backgroundImage() {
    return SizedBox(
      height: maxHeight,
      width: maxWidth,
      child: imageWidth != 0
          ? widget.backgroundImageWidget ??
              (widget.imageUrl.contains('assets')
                  ? Image.asset(widget.imageUrl,
                      fit: BoxFit.fill, filterQuality: FilterQuality.high)
                  : Image.network(widget.imageUrl,
                      fit: BoxFit.fill, filterQuality: FilterQuality.high))
          : const LoadingProgress(),
    );
  }

  void drawPoints() {
    double halfScreenWidth = (MediaQuery.of(context).size.width) / 2;
    double halfScreenHeight = (MediaQuery.of(context).size.height) / 2;

    if (imageWidth == 0 || imageHeight == 0) return;

    '${Q.TAG} maxWidth / imageWidth : ${maxWidth / imageWidth}'.log();
    '${Q.TAG} maxHeight / imageHeight : ${maxHeight / imageHeight}'.log();

    List<Offset> positions = [];

    for (int i = 0; i < widget.points!.length; i++) {
      if (_xValues.length > i) {
        var x =
            (_xValues[i] * maxWidth / imageWidth) + widget.pointsPositionDeltaX;

        x = x - (widget.points![i].width! / 2);
        _newXValues.add((x - halfScreenWidth).abs());

        var y = ((_yValues[i] * maxHeight / imageHeight) +
            widget.pointsPositionDeltaY);
        if (widget.points![i].isCurrent! && widget.currentPointDeltaY != null) {
          y = y - widget.currentPointDeltaY!;
        }
        y = y - (widget.points![i].width! / 2);
        _newYValues.add((y - halfScreenHeight).abs());

        '${Q.TAG} old x,y : ${_xValues[i]},${_yValues[i]} ## new x,y : $x,$y'
            .log();

        positions.add(Offset(x, y));
        widgets.add(pointWidget(x, y, child: widget.points![i].child));
      } else {
        break;
      }
    }

    if (widget.reverseScrolling) {
      _newXValues = _newXValues.reversed.toList();
      _newYValues = _newYValues.reversed.toList();
    }

    final scrollOffsets =
        widget.direction == Axis.horizontal ? _newXValues : _newYValues;

    widget.onMapFilled?.call(positions, scrollOffsets);
  }

  Widget pointWidget(double x, double y, {Widget? child}) {
    return Positioned(
      left: x,
      top: y,
      child: child ?? Container(),
    );
  }

  String? _pathSVG;

  Future _getPathFromSVG() async {
    await getPointsPathFromXML().then((value) {
      _pathSVG = value.replaceAll(',', ' ');
      'pathSVG : $_pathSVG'.log();
      List<String> arrayOfPoints = _pathSVG!.split(' ');
      for (int i = 0; i < arrayOfPoints.length; i++) {
        if (i % 2 == 0) {
          _xValues.add(double.parse(arrayOfPoints[i]));
        } else {
          _yValues.add(double.parse(arrayOfPoints[i]));
        }
      }
    });
  }

  Future<String> getPointsPathFromXML() async {
    String path = '';
    XmlDocument x = await Utils.readSvg(widget.svgUrl);
    Utils.getXmlWithClass(x, 'st0').forEach((element) {
      path = element.getAttribute('points')!;
    });
    return path;
  }
}
