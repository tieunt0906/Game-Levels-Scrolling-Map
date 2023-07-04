library game_levels_scrolling_map;

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../helper/utils.dart';
import 'config/q.dart';
import 'model/point_model.dart';
import 'widgets/loading_progress.dart';

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

  final Widget? backgroundImageWidget;
  final Color? bgColor;
  final Duration scrollDuration;

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
    this.isScrollable = false,
    this.reverseScrolling = false,
    this.bgColor,
    this.scrollDuration = const Duration(milliseconds: 1000),
  });

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
    this.backgroundImageWidget,
    this.isScrollable = true,
    this.bgColor,
    this.scrollDuration = const Duration(milliseconds: 1000),
  });

  @override
  _GameLevelsScrollingMapState createState() => _GameLevelsScrollingMapState();
}

class _GameLevelsScrollingMapState extends State<GameLevelsScrollingMap> {
  final List<double> _newXValues = [];
  List<double> _xValues = [];
  List<double> _yValues = [];
  double _height = 0;
  double _width = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      initDeviceDimensions();
      initDefaults();

      if (widget.svgUrl.isNotEmpty) {
        await _getPathFromSVG();
      }
      await _loadImage(path: widget.imageUrl);
      if (widget.isScrollable) {
        int currentIndex =
            widget.points!.indexWhere((point) => point.isCurrent!);
        if (currentIndex != -1 && _newXValues.isNotEmpty) {
          _scrollController.animateTo(
            _newXValues[currentIndex],
            duration: widget.scrollDuration,
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

  void initDeviceDimensions() {
    Q.deviceWidth = MediaQuery.of(context).size.width;
    Q.deviceHeight = MediaQuery.of(context).size.height;

    print('${Q.TAG} Device Dimensions : ${Q.deviceWidth} x ${Q.deviceHeight}');
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

    print('widget.height : $_height');
  }

  final _scrollController = ScrollController();
  final _key = GlobalKey();
  List<Widget> widgets = [];

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
              ? Stack(textDirection: TextDirection.ltr, children: widgets)
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

    print('${Q.TAG} image path : ${widget.imageUrl}');
    print('${Q.TAG} image dimensions : $imageWidth x $imageHeight');

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

    print(
        '${Q.TAG} image all dimensions : $imageWidth : $imageHeight : $aspectRatio');
    print(
        '${Q.TAG} image new dimensions : $maxWidth : $maxHeight : $aspectRatio');

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
    double halfScreenSize = (MediaQuery.of(context).size.width) / 2;
    print('${Q.TAG} maxWidth / imageWidth : ${maxWidth / imageWidth}');
    print('${Q.TAG} maxHeight / imageHeight : ${maxHeight / imageHeight}');

    for (int i = 0; i < widget.points!.length; i++) {
      //widget.points!.add(PointModel(100, testWidget(i)));
      if (_xValues.length > i) {
        var x =
            (_xValues[i] * maxWidth / imageWidth) + widget.pointsPositionDeltaX;

        x = x - (widget.points![i].width! / 2);
        _newXValues.add((x - halfScreenSize).abs());

        var y = ((_yValues[i] * maxHeight / imageHeight) +
            widget.pointsPositionDeltaY);
        if (widget.points![i].isCurrent! && widget.currentPointDeltaY != null) {
          y = y - widget.currentPointDeltaY!;
        }
        y = y - (widget.points![i].width! / 2);

        print(
            '${Q.TAG} old x,y : ${_xValues[i]},${_yValues[i]} ## new x,y : $x,$y');
        widgets.add(pointWidget(x, y, child: widget.points![i].child));
      } else {
        break;
      }
    }
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
      print('pathSVG : $_pathSVG');
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
