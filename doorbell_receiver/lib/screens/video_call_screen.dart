import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final RTCVideoRenderer remoteRenderer;

  const VideoCallScreen({Key? key, required this.remoteRenderer}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

  }

  Future<void> _initializeCall() async {
    try {
    
    } catch (e) {
      debugPrint('Failed to enable wakelock: $e');
      // Continue without wakelock if it fails
    }
  }

  void _toggleMute() {
    if (_isDisposed) return;
    
    try {
      setState(() {
        _isMuted = !_isMuted;
        final audioTracks = widget.remoteRenderer.srcObject?.getAudioTracks();
        if (audioTracks != null) {
          for (var track in audioTracks) {
            track.enabled = !_isMuted;
          }
        }
      });
    } catch (e) {
      debugPrint('Error toggling mute: $e');
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle mute')),
        );
      }
    }
  }

  void _toggleSpeaker() {
    if (_isDisposed) return;
    
    try {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle speaker')),
        );
      }
    }
  }

  Future<void> _endCall() async {
    if (_isDisposed) return;

    try {
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      // Still try to pop the navigator even if wakelock disable fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isDisposed) return true;

    try {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Call'),
          content: const Text('Are you sure you want to end the call?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ?? false;
    } catch (e) {
      debugPrint('Error showing dialog: $e');
      return true; // Allow pop if dialog fails
    }
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              if (widget.remoteRenderer.srcObject != null)
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: RTCVideoView(
                    widget.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    mirror: true,
                  ),
                )
              else
                const Center(
                  child: Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              // Control buttons with gradient background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        onPressed: _toggleMute,
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        backgroundColor: _isMuted ? Colors.red : Colors.white,
                        iconColor: _isMuted ? Colors.white : Colors.black,
                      ),
                      _buildControlButton(
                        onPressed: _endCall,
                        icon: Icons.call_end,
                        backgroundColor: Colors.red,
                        iconColor: Colors.white,
                      ),
                      _buildControlButton(
                        onPressed: _toggleSpeaker,
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        backgroundColor: Colors.white,
                        iconColor: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
    } catch (e) {
      debugPrint('Error in dispose: $e');
    }
    super.dispose();
  }
}