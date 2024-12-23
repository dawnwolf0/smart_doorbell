import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/signaling_service.dart';

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
      home: DoorbellScreen(),
    );
  }
}

class DoorbellScreen extends StatefulWidget {
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

  Future<void> _initializeSignaling() async {
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
      appBar: AppBar(title: Text('Doorbell')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isInitialized)
              CircularProgressIndicator()
            else if (!_isInCall)
              ElevatedButton(
                onPressed: _handleButtonPress,
                child: Text('Ring Doorbell'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
              )
            else
              Text('Call in progress...'),
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
