import 'dart:convert';
import 'dart:developer' as devtools;
import 'dart:io';

import 'package:drivers_license_parser/drivers_license_parser.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

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

  FlutterBarcodeSdk? _barcodeReader;
  bool _isScanAvailable = true;
  bool _isScanRunning = false;
  String _barcodeResults = '';
  String _buttonText = 'Start Video Scan';

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }

      setState(() {});
      initBarcodeSDK();
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

  Future<void> initBarcodeSDK() async {
    devtools.log('Init Barcode SDK');
    _barcodeReader = FlutterBarcodeSdk();
    // Get 30-day FREEE trial license from https://www.dynamsoft.com/customer/license/trialLicense?product=dbr
    await _barcodeReader!.setLicense(
        'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
    await _barcodeReader!.init();
    await _barcodeReader!.setBarcodeFormats(BarcodeFormat.PDF417);
    // Get all current parameters.
    // Refer to: https://www.dynamsoft.com/barcode-reader/parameters/reference/image-parameter/?ver=latest
    String params = await _barcodeReader!.getParameters();
    // Convert parameters to a JSON object.
    dynamic obj = json.decode(params);
    // Modify parameters.
    obj['ImageParameter']['DeblurLevel'] = 5;
    // Update the parameters.
    int ret = await _barcodeReader!.setParameters(json.encode(obj));
    devtools.log('Parameter update: $ret');
    await controller.startImageStream((image) async {
      int format = ImagePixelFormat.IPF_NV21.index;

      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;

      _barcodeReader!
          .decodeImageBuffer(
        image.planes[0].bytes,
        image.width,
        image.height,
        image.planes[0].bytesPerRow,
        format,
      )
          .then((results) {
        final _barcodeResults2 = getBarcodeResults(results);
        devtools.log('Barcode Results: $_barcodeResults2');
        final parsedLicense = LicenseParser.parse(_barcodeResults2);
        devtools.log('First Name: ${parsedLicense.firstName}');
        devtools.log('Last Name: ${parsedLicense.lastName}');
        _isScanAvailable = true;
      }).catchError((error) {
        _isScanAvailable = false;
      });
    });
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
    //args support android / Web , i don't have a mac
    String text = await FlutterTesseractOcr.extractText(image.path, args: {
      "psm": "6",
      "preserve_interword_spaces": "0",
    });

    devtools.log('text: $text');
  }

  /// Convert List<BarcodeResult> to string for display.
  String getBarcodeResults(List<BarcodeResult> results) {
    StringBuffer sb = StringBuffer();
    for (BarcodeResult result in results) {
      sb.write(result.format);
      sb.write("\n");
      sb.write(result.text);
      sb.write("\n");
      sb.write((result.barcodeBytes).toString());
      sb.write("\n\n");
    }
    if (results.isEmpty) sb.write("No Barcode Detected");
    return sb.toString();
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
