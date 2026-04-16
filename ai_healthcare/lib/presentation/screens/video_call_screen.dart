import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../core/colors.dart';

// --- CONFIGURATION ---
// Replace with your real Agora App ID from console.agora.io
const String AGORA_APP_ID = "16117d11d1504609a226e8c0221eccbb"; 

class VideoCallScreen extends StatefulWidget {
  final String remoteName;
  final String role; // 'doctor' or 'patient'
  final String channelName; // Added channel name for Agora

  const VideoCallScreen({
    super.key, 
    required this.remoteName, 
    required this.role,
    this.channelName = "teleconsultation_room", // Default room
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isConnecting = true;
  
  int? _remoteUid;
  late RtcEngine _engine;
  bool _localUserJoined = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      // 1. Initialize Engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: AGORA_APP_ID,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 2. Register Event Handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onError: (ErrorCodeType err, String msg) {
            debugPrint("Agora Error: $err - $msg");
            if (mounted) setState(() => _errorMessage = "Agora Error: $err");
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Local user ${connection.localUid} joined");
            if (mounted) setState(() {
              _localUserJoined = true;
              _errorMessage = null;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user $remoteUid joined");
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _isConnecting = false;
              });
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("Remote user $remoteUid left");
            if (mounted) {
              setState(() {
                _remoteUid = null;
                _isConnecting = true;
              });
            }
          },
        ),
      );

      // 3. Enable Video
      await _engine.enableVideo();
      await _engine.startPreview();

      // 4. Join Channel
      await _engine.joinChannel(
        token: '',
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint("Agora Init Exception: $e");
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  void dispose() {
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    if (AGORA_APP_ID == "YOUR_AGORA_APP_ID_HERE") {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Agora App ID Required',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please update video_call_screen.dart with your Agora App ID to enable real-time video calls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote Video Feed (Background)
          _buildRemoteFeed(),

          // 2. Overlay Gradients
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(150),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Header Info
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_isConnecting || _errorMessage != null) ? AppColors.warning.withAlpha(50) : AppColors.success.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.radio, size: 12, color: (_isConnecting || _errorMessage != null) ? AppColors.warning : AppColors.success)
                              .animate(onPlay: (c) => (_isConnecting || _errorMessage != null) ? c.repeat() : null)
                              .fade(duration: 800.ms),
                          const SizedBox(width: 6),
                          Text(
                            _errorMessage ?? (_isConnecting ? 'Awaiting Connection...' : 'Secure Connection Active'),
                            style: TextStyle(
                              color: (_isConnecting || _errorMessage != null) ? AppColors.warning : AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.role == 'doctor' ? 'Dr. ${widget.remoteName}' : widget.remoteName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black54)]),
                    ),
                    Text(
                      widget.role == 'doctor' ? 'Consultation' : 'Patient Session',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ).animate().slideY(begin: -0.5).fadeIn(),
          ),

          // 4. Local Video Feed (PiP)
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            right: 20,
            child: _buildLocalFeed(),
          ),

          // 5. Connecting State UI
          if (_isConnecting && _remoteUid == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text('Waiting for ${widget.remoteName} to join...', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),

          // 6. Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(240),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _controlBtn(
                      icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                      color: _isMuted ? AppColors.error : Colors.white,
                      bgColor: _isMuted ? AppColors.error.withAlpha(40) : Colors.white.withAlpha(20),
                      onTap: () {
                        setState(() => _isMuted = !_isMuted);
                        _engine.muteLocalAudioStream(_isMuted);
                      },
                    ),
                    const SizedBox(width: 16),
                    _controlBtn(
                      icon: _isVideoOff ? LucideIcons.videoOff : LucideIcons.video,
                      color: _isVideoOff ? AppColors.error : Colors.white,
                      bgColor: _isVideoOff ? AppColors.error.withAlpha(40) : Colors.white.withAlpha(20),
                      onTap: () {
                        setState(() => _isVideoOff = !_isVideoOff);
                        _engine.muteLocalVideoStream(_isVideoOff);
                      },
                    ),
                    const SizedBox(width: 16),
                    _controlBtn(
                      icon: LucideIcons.switchCamera,
                      color: Colors.white,
                      bgColor: Colors.white.withAlpha(20),
                      onTap: () => _engine.switchCamera(),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                        ),
                        child: const Icon(LucideIcons.phoneOff, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 1.0).fadeIn(delay: 200.ms),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteFeed() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        color: const Color(0xFF1E293B),
        child: Center(
          child: Icon(LucideIcons.user, color: Colors.white.withAlpha(20), size: 100),
        ),
      );
    }
  }

  Widget _buildLocalFeed() {
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _localUserJoined && !_isVideoOff
            ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            : Center(child: Icon(_isVideoOff ? LucideIcons.videoOff : LucideIcons.user, color: Colors.white.withAlpha(100), size: 30)),
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: 1.0);
  }

  Widget _controlBtn({required IconData icon, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
