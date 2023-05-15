import 'package:flutter/material.dart';

import 'face_detector_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Detector"),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: 350,
          height: 80,
          child: OutlinedButton(
            style: ButtonStyle(
              side: MaterialStateProperty.all(
                const BorderSide(
                    color: Colors.blue, width: 1.0, style: BorderStyle.solid),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FaceDetectorPage(),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconWidget(Icons.arrow_back_ios_new_outlined),
                const Text(
                  "Go to Face Detection",
                  style: TextStyle(fontSize: 20),
                ),
                _buildIconWidget(Icons.arrow_back_ios_new_outlined)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconWidget(final IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          icon,
          size: 24
        ),
      );
}
