import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/signaling_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DoorbellApp());
}

class DoorbellApp extends StatelessWidget {
  const DoorbellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DoorbellScreen(),
    );
  }
}

class DoorbellScreen extends StatefulWidget {
  const DoorbellScreen({super.key});

  @override
  State<DoorbellScreen> createState() => DoorbellScreenState();
}

class DoorbellScreenState extends State<DoorbellScreen> {
  final SignalingService _signaling = SignalingService();
  bool _isInitialized = false;
  bool _isInCall = false;

  @override
  void initState() {
    super.initState();
    _initializeSignaling();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  Future<void> _initializeSignaling() async {
    await _requestPermissions();
    await _signaling.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  void _handleButtonPress() async {
    setState(() {
      _isInCall = true;
    });
    await _signaling.makeCall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doorbell'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isInitialized)
              const CircularProgressIndicator()
            else if (!_isInCall)
              ElevatedButton(
                onPressed: _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child: const Text('Ring Doorbell'),
              )
            else
              Column(
                children: [
                  const Text('Call in progress...'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _signaling.endCall();
                      setState(() {
                        _isInCall = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('End Call'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _signaling.dispose();
    super.dispose();
  }
}
