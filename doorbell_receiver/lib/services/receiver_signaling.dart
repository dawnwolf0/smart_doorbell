import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ReceiverSignalingService {
  Function? onIncomingCall;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  final RTCVideoRenderer remoteRenderer;

  ReceiverSignalingService(this.remoteRenderer);

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

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams[0] != null) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _addCandidate(candidate);
    };

    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE Connection State: $state');
    };

    _listenForCalls();
  }

  void _listenForCalls() {
    _firestore.collection('calls').doc('currentCall').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
        onIncomingCall?.call();
        handleOffer(snapshot.data()!);
      }
    });

    _firestore.collection('calls').doc('currentCall').collection('candidates').snapshots().listen((snapshot) {
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
    await _firestore.collection('calls').doc('currentCall').collection('candidates').add({
      'candidate': candidate.toMap(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endCall() async {
    localStream?.getTracks().forEach((track) => track.stop());
    await localStream?.dispose();
    await peerConnection?.close();
  }

  void dispose() {
    endCall();
  }
}
