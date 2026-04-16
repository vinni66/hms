import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart';
import 'api_service.dart';
import '../../presentation/widgets/incoming_call_dialog.dart';
import '../../presentation/screens/video_call_screen.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final _api = ApiService();
  Timer? _pollingTimer;
  bool _isCallActive = false; // prevents popping dialog multiple times

  void startListening() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_api.currentUser != null && !_isCallActive) {
        debugPrint('CallService: GLOBAL LISTENER ACTIVE - Polling for incoming calls...');
        _checkIncomingCall();
      }
    });
  }

  void stopListening() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isCallActive = false;
  }

  Future<void> _checkIncomingCall() async {
    try {
      final res = await _api.pingCallStatus();
      if (res != null && res['incoming'] != null) {
        final incoming = res['incoming'];
        debugPrint('CallService: Incoming call detected from ${incoming['caller_name']}');
        _showIncomingDialog(incoming['caller_name'], incoming['role'], incoming['caller_id']);
      }
    } catch (e) {
      debugPrint('CallService: Polling error: $e');
    }
  }

  void _showIncomingDialog(String callerName, String role, String callerId) {
    if (globalNavigatorKey.currentContext == null) return;
    _isCallActive = true;
    showGeneralDialog(
      context: globalNavigatorKey.currentContext!,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return IncomingCallDialog(
          callerName: callerName,
          role: role,
          onAccept: () async {
            await _api.endCall(callerId); // Clear signal immediately
            
            // Check permissions before connecting
            final status = await [Permission.camera, Permission.microphone].request();
            if (status[Permission.camera] != PermissionStatus.granted || 
                status[Permission.microphone] != PermissionStatus.granted) {
              debugPrint('CallService: Permissions denied');
              // Optionally show a snackbar or alert
            }

            Navigator.pop(context);
            Navigator.push(globalNavigatorKey.currentContext!, MaterialPageRoute(
              builder: (_) => VideoCallScreen(remoteName: callerName, role: role)
            ));
            // re-enable listening after a minute or when screen closed 
            // Setting isCallActive to false after push allows it to catch later
            Future.delayed(const Duration(seconds: 10), () => _isCallActive = false);
          },
          onDecline: () async {
            await _api.endCall(callerId);
            Navigator.pop(context);
            _isCallActive = false;
          },
        );
      },
    );
  }

  // Triggered by the caller
  Future<void> startCall(String targetId, String callerName, String role) async {
    await _api.startCall(targetId, callerName, role);
    
    // Check permissions before navigating
    await [Permission.camera, Permission.microphone].request();

    if (globalNavigatorKey.currentContext != null) {
      Navigator.push(globalNavigatorKey.currentContext!, MaterialPageRoute(
        builder: (_) => VideoCallScreen(remoteName: 'Patient/Doctor', role: role == 'doctor' ? 'patient' : 'doctor')
      ));
    }
  }
}
