import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Function(MediaStream)? onAddRemoteStream;
  bool _isCalling = false;

  Map<String, dynamic> configuration = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"},
      {
        "urls": "turn:numb.viagenie.ca",
        "username": "webrtc@live.com",
        "credential": "muazkh"
      }
    ]
  };

  Future<void> initialize() async {
    peerConnection = await createPeerConnection(configuration);

    // Get local media stream
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    });

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _addCandidate(candidate);
    };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams[0] != null) {
        onAddRemoteStream?.call(event.streams[0]);
      }
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE Connection State: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection State: $state');
    };
  }

  Future<void> makeCall() async {
    if (_isCalling) return;
    _isCalling = true;

    try {
      RTCSessionDescription offer = await peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1
      });

      await peerConnection!.setLocalDescription(offer);

      await _firestore.collection('calls').doc('currentCall').set({
        'offer': offer.toMap(),
        'type': 'offer',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _firestore.collection('calls').doc('currentCall').snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data()?['type'] == 'answer') {
          handleAnswer(snapshot.data()!);
        }
      });

      _firestore.collection('calls')
          .doc('currentCall')
          .collection('candidates')
          .snapshots()
          .listen((snapshot) {
        snapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added) {
            Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
            peerConnection?.addCandidate(
              RTCIceCandidate(
                data['candidate']['candidate'],
                data['candidate']['sdpMid'],
                data['candidate']['sdpMLineIndex'],
              ),
            );
          }
        });
      });
    } catch (e) {
      print("Error making call: $e");
      _isCalling = false;
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> answer) async {
    try {
      RTCSessionDescription description = RTCSessionDescription(
        answer['answer']['sdp'],
        answer['answer']['type'],
      );
      await peerConnection?.setRemoteDescription(description);
    } catch (e) {
      print("Error handling answer: $e");
    }
  }

  Future<void> _addCandidate(RTCIceCandidate candidate) async {
    try {
      await _firestore.collection('calls')
          .doc('currentCall')
          .collection('candidates')
          .add({
        'candidate': candidate.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding candidate: $e");
    }
  }

  Future<void> endCall() async {
    _isCalling = false;
    await _firestore.collection('calls').doc('currentCall').delete();
    localStream?.getTracks().forEach((track) => track.stop());
    await localStream?.dispose();
    await peerConnection?.close();
  }

  void dispose() {
    endCall();
  }
}
