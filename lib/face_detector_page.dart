import 'package:camera/camera.dart';
import 'package:face_detaction_demo/camera_view.dart';
import 'package:face_detaction_demo/util/face_detector_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPage extends StatefulWidget {
  const FaceDetectorPage({Key? key}) : super(key: key);

  @override
  State<FaceDetectorPage> createState() => _FaceDetectorPageState();
}

class _FaceDetectorPageState extends State<FaceDetectorPage> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _conProcess = true;
  bool isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void dispose() {
    _conProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: '${_text}',
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  Future<void> processImage(final InputImage inputImage) async {
    if (!_conProcess) return;
    if (isBusy) return;
    isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
    _customPaint = CustomPaint(painter: painter,);
    }else{
      String text = 'faces found: ${faces.length}\n\n';
      for(final face in faces){
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    isBusy = false;
    if(mounted){
      setState(() {

      });
    }
  }
}
