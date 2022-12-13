import 'dart:developer' as devtools;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

late List<CameraDescription> _cameras;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  devtools.log('Cameras: $_cameras');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: const IDScanningScreen(),
    );
  }
}

class IDScanningScreen extends StatefulWidget {
  const IDScanningScreen({super.key});

  @override
  State<IDScanningScreen> createState() => _IDScanningScreenState();
}

class _IDScanningScreenState extends State<IDScanningScreen> {
  late CameraController controller;

  XFile? imagePath;

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }

      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _takePicture() async {
    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    final image = await controller.takePicture();
    setState(() {
      imagePath = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ID Scanning'),
              if (imagePath != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1,
                      color: Colors.red,
                    ),
                  ),
                  height: 300,
                  child: Image.file(File(imagePath!.path)),
                ),
              if (imagePath == null)
                SizedBox(
                  height: size.height * .75,
                  width: double.infinity,
                  child: CameraPreview(controller),
                ),
              ElevatedButton(
                onPressed: () {
                  _takePicture();
                },
                child: const Text('Take Picture'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
