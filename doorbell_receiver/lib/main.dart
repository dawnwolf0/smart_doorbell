import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'services/receiver_signaling.dart';
import 'screens/video_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ReceiverApp());
}

class ReceiverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doorbell Receiver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReceiverHomeScreen(),
    );
  }
}

class ReceiverHomeScreen extends StatefulWidget {
  @override
  _ReceiverHomeScreenState createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends State<ReceiverHomeScreen> {
  final ReceiverSignalingService _signaling = ReceiverSignalingService();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isInitialized = false;
  bool _isInCall = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _remoteRenderer.initialize();
    await _signaling.initialize();

    _signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    // Listen for incoming calls
    FirebaseFirestore.instance
        .collection('calls')
        .doc('currentCall')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
        _handleIncomingCall();
      }
    });

    setState(() {
      _isInitialized = true;
    });
  }

  void _handleIncomingCall() {
    if (!_isInCall) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Incoming Call'),
            content: Text('Someone is at the door!'),
            actions: [
              TextButton(
                child: Text('Decline'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Accept'),
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
  }

  void _acceptCall() {
    setState(() {
      _isInCall = true;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(),
      ),
    ).then((_) {
      setState(() {
        _isInCall = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doorbell Receiver'),
      ),
      body: Center(
        child: !_isInitialized
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  if (_isInCall)
                    Expanded(
                      child: RTCVideoView(
                        _remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }
}