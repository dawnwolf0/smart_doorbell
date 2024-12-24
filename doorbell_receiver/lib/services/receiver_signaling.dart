// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter_webrtc/flutter_webrtc.dart';

// // class ReceiverSignalingService {
// //   Function? onIncomingCall;
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //   RTCPeerConnection? peerConnection;
// //   MediaStream? localStream;
// //   final RTCVideoRenderer remoteRenderer;

// //   ReceiverSignalingService(this.remoteRenderer);

// //   Map<String, dynamic> configuration = {
// //     "iceServers": [
// //       {"urls": "stun:stun.l.google.com:19302"},
// //       {
// //         "urls": "turn:numb.viagenie.ca",
// //         "username": "webrtc@live.com",
// //         "credential": "muazkh"
// //       }
// //     ]
// //   };

// //   Future<void> initialize() async {
// //     peerConnection = await createPeerConnection(configuration);

// //     // Get local media stream
// //     localStream = await navigator.mediaDevices.getUserMedia({
// //       'audio': true,
// //       'video': {
// //         'mandatory': {
// //           'minWidth': '640',
// //           'minHeight': '480',
// //           'minFrameRate': '30',
// //         },
// //         'facingMode': 'user',
// //         'optional': [],
// //       }
// //     });

// //     localStream?.getTracks().forEach((track) {
// //       peerConnection?.addTrack(track, localStream!);
// //     });

// //     peerConnection?.onTrack = (RTCTrackEvent event) {
// //       if (event.streams[0] != null) {
// //         remoteRenderer.srcObject = event.streams[0];
// //       }
// //     };

// //     peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
// //       _addCandidate(candidate);
// //     };

// //     peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
// //       print('ICE Connection State: $state');
// //     };

// //     _listenForCalls();
// //   }

// //   void _listenForCalls() {
// //     _firestore.collection('calls').doc('currentCall').snapshots().listen((snapshot) {
// //       if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
// //         onIncomingCall?.call();
// //         handleOffer(snapshot.data()!);
// //       }
// //     });

// //     _firestore.collection('calls').doc('currentCall').collection('candidates').snapshots().listen((snapshot) {
// //       snapshot.docChanges.forEach((change) {
// //         if (change.type == DocumentChangeType.added) {
// //           Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
// //           peerConnection?.addCandidate(
// //             RTCIceCandidate(
// //               data['candidate']['candidate'],
// //               data['candidate']['sdpMid'],
// //               data['candidate']['sdpMLineIndex'],
// //             ),
// //           );
// //         }
// //       });
// //     });
// //   }

// //   Future<void> handleOffer(Map<String, dynamic> offer) async {
// //     await peerConnection?.setRemoteDescription(
// //       RTCSessionDescription(
// //         offer['offer']['sdp'],
// //         offer['offer']['type'],
// //       ),
// //     );

// //     RTCSessionDescription answer = await peerConnection!.createAnswer();
// //     await peerConnection!.setLocalDescription(answer);

// //     await _firestore.collection('calls').doc('currentCall').update({
// //       'answer': answer.toMap(),
// //       'type': 'answer',
// //     });
// //   }

// //   Future<void> _addCandidate(RTCIceCandidate candidate) async {
// //     await _firestore.collection('calls').doc('currentCall').collection('candidates').add({
// //       'candidate': candidate.toMap(),
// //       'timestamp': FieldValue.serverTimestamp(),
// //     });
// //   }

// //   Future<void> endCall() async {
// //     localStream?.getTracks().forEach((track) => track.stop());
// //     await localStream?.dispose();
// //     await peerConnection?.close();
// //   }

// //   void dispose() {
// //     endCall();
// //   }
// // }


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class ReceiverSignalingService {
//   Function? onIncomingCall;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   RTCPeerConnection? peerConnection;
//   MediaStream? localStream;
//   final RTCVideoRenderer remoteRenderer;

//   ReceiverSignalingService(this.remoteRenderer);

//   Map<String, dynamic> configuration = {
//     "iceServers": [
//       {"urls": "stun:stun.l.google.com:19302"},
//       {
//         "urls": "turn:numb.viagenie.ca",
//         "username": "webrtc@live.com",
//         "credential": "muazkh"
//       }
//     ]
//   };

//   Future<void> initialize() async {
//     try {
//       peerConnection = await createPeerConnection(configuration);
      
//       localStream = await navigator.mediaDevices.getUserMedia({
//         'audio': true,
//         'video': {
//           'mandatory': {
//             'minWidth': '640',
//             'minHeight': '480',
//             'minFrameRate': '30',
//           },
//           'facingMode': 'user',
//           'optional': [],
//         }
//       });

//       if (localStream == null) {
//         throw Exception('Failed to get local media stream');
//       }

//       localStream?.getTracks().forEach((track) {
//         peerConnection?.addTrack(track, localStream!);
//       });

//       peerConnection?.onTrack = (RTCTrackEvent event) {
//         if (event.streams[0] != null) {
//           remoteRenderer.srcObject = event.streams[0];
//         }
//       };

//       peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//         addCandidate(candidate);
//       };

//       peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
//         print('ICE Connection State: $state');
//       };

//       _listenForCalls();
//     } catch (e) {
//       print('Failed to initialize WebRTC: $e');
//       rethrow;
//     }
//   }

//   void _listenForCalls() {
//     _firestore.collection('calls').doc('currentCall').snapshots().listen((snapshot) {
//       if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
//         onIncomingCall?.call();
//         handleOffer(snapshot.data()!);
//       }
//     });

//     _firestore.collection('calls').doc('currentCall').collection('candidates').snapshots().listen((snapshot) {
//       snapshot.docChanges.forEach((change) {
//         if (change.type == DocumentChangeType.added) {
//           Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
//           peerConnection?.addCandidate(
//             RTCIceCandidate(
//               data['candidate']['candidate'],
//               data['candidate']['sdpMid'],
//               data['candidate']['sdpMLineIndex'],
//             ),
//           );
//         }
//       });
//     });
//   }

//   Future<void> handleOffer(Map<String, dynamic> offer) async {
//   try {
//     await peerConnection?.setRemoteDescription(
//       RTCSessionDescription(
//         offer['offer']['sdp'],
//         offer['offer']['type'],
//       ),
//     );

//     RTCSessionDescription answer = await peerConnection!.createAnswer({
//       'offerToReceiveAudio': true,
//       'offerToReceiveVideo': true
//     });
    
//     await peerConnection!.setLocalDescription(answer);

//     await _firestore.collection('calls').doc('currentCall').update({
//       'answer': {
//         'type': answer.type,
//         'sdp': answer.sdp,
//       },
//       'type': 'answer',
//     });
//   } catch (e) {
//     print('Error handling offer: $e');
//     rethrow;
//   }
// }

//   Future<void> addCandidate(RTCIceCandidate candidate) async {
//     await _firestore.collection('calls').doc('currentCall').collection('candidates').add({
//       'candidate': candidate.toMap(),
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//   }

//   Future<void> endCall() async {
//     localStream?.getTracks().forEach((track) => track.stop());
//     await localStream?.dispose();
//     await peerConnection?.close();
//   }

//   void dispose() {
//     endCall();
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';  // Add this import for StreamSubscription

class ReceiverSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  final RTCVideoRenderer remoteRenderer;
  MediaStream? localStream;
  Function()? onIncomingCall;
  bool _isInitialized = false;
  StreamSubscription<DocumentSnapshot>? _callListener;
  StreamSubscription<QuerySnapshot>? _candidateListener;

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
    if (_isInitialized) return;

    try {
      peerConnection = await createPeerConnection(configuration);

      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        _addCandidate(candidate);
      };

      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams[0];
        }
      };

      // Listen for incoming calls
      _callListener = _firestore
          .collection('calls')
          .doc('currentCall')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data()?['type'] == 'offer') {
          onIncomingCall?.call();
          _handleOffer(snapshot.data()!);
        }
      });

      // Listen for ICE candidates
      _candidateListener = _firestore
          .collection('calls')
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

      _isInitialized = true;
    } catch (e) {
      print('Error initializing receiver signaling: $e');
      throw Exception('Failed to initialize receiver signaling');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      RTCSessionDescription description = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await peerConnection?.setRemoteDescription(description);

      // Create answer
      RTCSessionDescription answer = await peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1
      });

      await peerConnection?.setLocalDescription(answer);

      await _firestore.collection('calls').doc('currentCall').update({
        'answer': answer.toMap(),
        'type': 'answer',
      });
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  Future<void> _addCandidate(RTCIceCandidate candidate) async {
    try {
      await _firestore
          .collection('calls')
          .doc('currentCall')
          .collection('candidates')
          .add({
        'candidate': candidate.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding candidate: $e');
    }
  }

  Future<void> endCall() async {
    try {
      remoteRenderer.srcObject = null;
      await peerConnection?.close();
      peerConnection = null;
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  void dispose() {
    _callListener?.cancel();
    _candidateListener?.cancel();
    endCall();
  }
}