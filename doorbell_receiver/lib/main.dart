import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/receiver_signaling.dart';
import 'screens/video_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ReceiverApp());
}

class ReceiverApp extends StatelessWidget {
  const ReceiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doorbell Receiver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ReceiverHomeScreen(),
    );
  }
}

class ReceiverHomeScreen extends StatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  State<ReceiverHomeScreen> createState() => ReceiverHomeScreenState();
}

class ReceiverHomeScreenState extends State<ReceiverHomeScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isInitialized = false;
  late ReceiverSignalingService _signaling;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _remoteRenderer.initialize();
    _signaling = ReceiverSignalingService(_remoteRenderer);
    await _signaling.initialize();
    
    _signaling.onIncomingCall = () {
      _handleIncomingCall();
    };

    setState(() {
      _isInitialized = true;
    });
  }

  void _handleIncomingCall() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Incoming Call'),
          content: const Text('Someone is at the door!'),
          actions: [
            TextButton(
              child: const Text('Decline'),
              onPressed: () {
                Navigator.of(context).pop();
                _signaling.endCall();
              },
            ),
            TextButton(
              child: const Text('Accept'),
              onPressed: () {
                Navigator.of(context).pop();
                _acceptCall();
              },
            ),
          ],
        );
      },
    );
  }

  void _acceptCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          remoteRenderer: _remoteRenderer,
        ),
      ),
    ).then((_) {
      _signaling.endCall();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doorbell Receiver'),
      ),
      body: Center(
        child: !_isInitialized
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.doorbell_outlined,
                    size: 100,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Waiting for doorbell...',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _signaling.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}