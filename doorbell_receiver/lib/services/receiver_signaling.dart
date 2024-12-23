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

    // Handle incoming video streams
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        onAddRemoteStream?.call(event.streams[0]);
      }
    };

    // Set up local media stream
    localStream = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': true});

    // Add local stream tracks to peer connection
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Listen for ICE candidates
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _addCandidate(candidate);
    };

    // Listen for incoming calls
    _listenForCalls();
  }

  void _listenForCalls() {
    _firestore
        .collection('calls')
        .doc('currentCall')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
        handleOffer(snapshot.data()!);
      }
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offer) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(
        offer['offer']['sdp'],
        offer['offer']['type'],
      ),
    );

    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    await _firestore.collection('calls').doc('currentCall').update({
      'answer': answer.toMap(),
      'type': 'answer',
    });
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
