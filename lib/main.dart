import 'package:camera/camera.dart';
import 'package:face_detaction_demo/home_screen.dart';
import 'package:flutter/material.dart';

import 'face_detector_page.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FaceDetectorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
