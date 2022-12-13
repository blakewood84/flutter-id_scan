import 'package:flutter/material.dart';

void main() {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('ID Scanning'),
        ],
      ),
    );
  }
}
