import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
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

    // Get local stream
    localStream = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': true});

    // Add local stream to peer connection
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });
  }

  Future<void> makeCall() async {
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await _firestore.collection('calls').doc('currentCall').set({
      'offer': offer.toMap(),
      'type': 'offer',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Listen for answer
    _firestore
        .collection('calls')
        .doc('currentCall')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['type'] == 'answer') {
        handleAnswer(snapshot.data()!);
      }
    });
  }

  void handleAnswer(Map<String, dynamic> answer) async {
    RTCSessionDescription description = RTCSessionDescription(
      answer['answer']['sdp'],
      answer['answer']['type'],
    );
    await peerConnection?.setRemoteDescription(description);
  }

  Future<void> _addCandidate(RTCIceCandidate candidate) async {
    await _firestore
        .collection('calls')
        .doc('currentCall')
        .collection('candidates')
        .add({
      'candidate': candidate.toMap(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {
    localStream?.dispose();
    peerConnection?.dispose();
  }
}
