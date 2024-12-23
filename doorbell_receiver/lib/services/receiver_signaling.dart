import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ReceiverSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Function(MediaStream)? onAddRemoteStream;

  Map<String, dynamic> configuration = {
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
      {
        "url": "turn:numb.viagenie.ca",
        "username": "webrtc@live.com",
        "credential": "muazkh"
      }
    ]
  };

  Future<void> initialize() async {
    peerConnection = await createPeerConnection(configuration);

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _addCandidate(candidate);
    };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        onAddRemoteStream?.call(event.streams[0]);
      }
    };

    // Listen for incoming calls
    _firestore.collection('calls').doc('currentCall').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
        handleOffer(snapshot.data()!);
      }
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offer) async {
    RTCSessionDescription description = RTCSessionDescription(
      offer['offer']['sdp'],
      offer['offer']['type'],
    );
    await peerConnection?.setRemoteDescription(description);

    // Create answer
    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    await _firestore.collection('calls').doc('currentCall').update({
      'answer': answer.toMap(),
      'type': 'answer',
    });
  }

  Future<void> _addCandidate(RTCIceCandidate candidate) async {
    await _firestore.collection('calls').doc('currentCall').collection('candidates').add({
      'candidate': candidate.toMap(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {
    localStream?.dispose();
    peerConnection?.dispose();
  }
}