import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_detaction_demo/util/screen_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import 'main.dart';

class CameraView extends StatefulWidget {
  final String title;
  final CustomPaint? customPaint;
  final String text;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;

  const CameraView(
      {Key? key,
      required this.title,
      this.customPaint,
      required this.text,
      required this.onImage,
      required this.initialDirection})
      : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  ScreenModel _mode = ScreenModel.live;
  CameraController? _controller;
  String? _path;
  File? _image;
  ImagePicker? _imagePicker;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  final bool _allowPicker = true;
  bool _changingCameraLens = false;

  @override
  void initState() {
    _imagePicker = ImagePicker();
    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
            (element) => element.lensDirection == widget.initialDirection),
      );
    }
    _startLive();
    super.initState();
  }

  Future _startLive() async {
    final camera = cameras[_cameraIndex];
    _controller =
        CameraController(camera, ResolutionPreset.high, enableAudio: false);
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      _controller?.getMinZoomLevel().then((value){
        zoomLevel = value;
        minZoomLevel = value;
      });

      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _processCameraImage(final CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;
    final planeData = image.planes.map((final Plane plane) {
      return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width);
    }).toList();
    final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData);
    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    widget.onImage(inputImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_allowPicker)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: _switchScreenMode,
                child: Icon(_mode == ScreenModel.live
                    ? Icons.photo_library_rounded
                    : (Platform.isIOS
                        ? Icons.camera_alt_outlined
                        : Icons.camera)),
              ),
            )
        ],
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _floatingActionButton() {
    if (_mode == ScreenModel.gallery) return null;
    if (cameras.length == 1) return null;
    return SizedBox(
      height: 70,
      width: 70,
      child: FloatingActionButton(
        onPressed: _switcherCamera,
        child: Icon(
          Platform.isIOS
              ? Icons.flip_camera_ios_outlined
              : Icons.flip_camera_android_outlined,
          size: 40,
        ),
      ),
    );
  }

  Future _switcherCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    await _stopLive();
    await _startLive();
    setState(() => _changingCameraLens = false);
  }

  Widget _galleryBody() => ListView(
        shrinkWrap: true,
        children: [
          _image != null
              ? SizedBox(
                  height: 400,
                  width: 400,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_image!),
                      if (widget.customPaint != null) widget.customPaint!,
                    ],
                  ),
                )
              : const Icon(Icons.image, size: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _getImage(ImageSource.gallery),
              child: const Text("From Gallery"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _getImage(ImageSource.camera),
              child: const Text("Take a Picture"),
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  '${_path == null ? '' : 'image path : $_path'}\n\n${widget.text ?? ''}'),
            )
        ],
      );

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }
    setState(() {});
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    widget.onImage(inputImage);
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenModel.live) {
      body = _liveBody();
    } else {
      body = _galleryBody();
    }
    return body;
  }

  Widget _liveBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text("Changing camera leans"),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Slider(
              value: zoomLevel,
              min: minZoomLevel,
              max: maxZoomLevel,
              onChanged: (final newSliderValue) {
                setState(() {
                  zoomLevel = newSliderValue;
                  _controller!.setZoomLevel(zoomLevel);
                });
              },
              divisions: (maxZoomLevel - 1).toInt() < 1
                  ? null
                  : (maxZoomLevel - 1).toInt(),
            ),
          ),
        ],
      ),
    );
  }

  void _switchScreenMode() {
    _image = null;
    if (_mode == ScreenModel.live) {
      _mode = ScreenModel.gallery;
      _stopLive();
    } else {
      _mode = ScreenModel.live;
      _startLive();
    }
    setState(() {});
  }

  Future _stopLive() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
