import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';

class StepLiveness extends StatefulWidget {
  const StepLiveness({super.key});

  @override
  State<StepLiveness> createState() => _StepLivenessState();
}

enum LivenessAction { start, blink, turnLeft, turnRight, openMouth, smile, verify, success }

class _StepLivenessState extends State<StepLiveness> with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isTakingPicture = false;
  XFile? _capturedFile;
  
  // Logic State
  List<LivenessAction> _actionQueue = [];
  LivenessAction _currentAction = LivenessAction.start;
  String _instruction = "Position your face";

  // Security State
  int? _lockedFaceId; 
  bool _isSecurityCompromised = false; 

  double _progress = 0.0;
  bool _eyesClosedDetected = false;

  // Timeout Logic
  Timer? _sessionTimer;
  bool _hasTimedOut = false;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _resetLiveness();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(seconds: 30), () { 
      if (mounted && 
          !_hasTimedOut && 
          !_isSecurityCompromised &&
          _currentAction != LivenessAction.success && 
          _currentAction != LivenessAction.verify) {
        setState(() {
          _hasTimedOut = true;
          HapticFeedback.heavyImpact();
        });
      }
    });
  }

  void _resetLiveness() {
    setState(() {
      _hasTimedOut = false;
      _isSecurityCompromised = false;
      _lockedFaceId = null; 
      _currentAction = LivenessAction.start;
      _eyesClosedDetected = false;
      _capturedFile = null;
      _isTakingPicture = false;
      _progress = 0.0;
      _actionQueue = [
        LivenessAction.blink,
        LivenessAction.smile,
        LivenessAction.turnLeft,
        LivenessAction.turnRight,
        LivenessAction.openMouth,
      ];
      _instruction = "Position your face in the oval";
    });
    if (_isCameraInitialized) _startSessionTimer();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium, // Lower resolution for faster processing
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _instruction = "Position your face in the circle";
      });
      _startSessionTimer(); 
      _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing ||
        _hasTimedOut ||
        _isSecurityCompromised ||
        _isTakingPicture ||
        _capturedFile != null ||
        _currentAction == LivenessAction.verify ||
        _currentAction == LivenessAction.success) {
      return;
    }

    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint("⚠️ InputImage is NULL - Check rotation logic");
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        _runLivenessLogic(faces.first);
      }
    } catch (e) {
      debugPrint("Face Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _runLivenessLogic(Face face) {
    if (!mounted || _hasTimedOut || _isSecurityCompromised) return;


    // --- SECURITY LAYER ---
    if (_lockedFaceId == null) {
      _lockedFaceId = face.trackingId;
    } 
    else if (face.trackingId != _lockedFaceId) {
      setState(() {
        _isSecurityCompromised = true;
        _instruction = "Security Violation";
        HapticFeedback.heavyImpact();
      });
      return;
    }
    // ----------------------

    if (face.boundingBox.width < 50) { 
      if (_instruction != "Move closer") {
        setState(() => _instruction = "Move closer");
      }
      return;
    }

    if (_currentAction == LivenessAction.start) {
      setState(() {
         _instruction = "Perfect! Hold still...";
      });
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _currentAction == LivenessAction.start) {
          _nextAction();
        }
      });
      return;
    }

    bool actionCompleted = false;

    switch (_currentAction) {
      case LivenessAction.blink:
        double left = face.leftEyeOpenProbability ?? 1.0;
        double right = face.rightEyeOpenProbability ?? 1.0;
        if (left < 0.3 && right < 0.3) {
          _eyesClosedDetected = true;
        } else if (_eyesClosedDetected && left > 0.6 && right > 0.6) {
          actionCompleted = true;
          _eyesClosedDetected = false;
        }
        break;

      case LivenessAction.smile:
        if ((face.smilingProbability ?? 0) > 0.8) actionCompleted = true;
        break;

      case LivenessAction.turnLeft:
        if ((face.headEulerAngleY ?? 0) > 20) actionCompleted = true;
        break;

      case LivenessAction.turnRight:
        if ((face.headEulerAngleY ?? 0) < -20) actionCompleted = true;
        break;

      case LivenessAction.openMouth:
        final bottomLip = face.landmarks[FaceLandmarkType.bottomMouth]?.position;
        final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
        if (bottomLip != null && nose != null) {
          double noseToBottomLipDist = (bottomLip.y - nose.y).abs().toDouble();
          double faceHeight = face.boundingBox.height.toDouble();
          if (noseToBottomLipDist > (faceHeight * 0.15)) actionCompleted = true;
        }
        break; 

      default:
        break;
    }

    if (actionCompleted) {
      HapticFeedback.lightImpact();
      if(mounted) _nextAction();
    }
  }

  void _nextAction() {
    if (_actionQueue.isEmpty) {
      _captureAndFinish(); // Done!
    } else {
      setState(() {
        _currentAction = _actionQueue.removeAt(0);
        _updateInstruction(_currentAction);
        _progress += 0.5;
      });
    }
  }

 void _updateInstruction(LivenessAction action) {
    switch (action) {
      case LivenessAction.blink: _instruction = "Blink your eyes"; break;
      case LivenessAction.smile: _instruction = "Smile"; break;
      case LivenessAction.turnLeft: _instruction = "Turn head Left"; break;
      case LivenessAction.turnRight: _instruction = "Turn head Right"; break;
      case LivenessAction.openMouth: _instruction = "Open mouth"; break;
      default: _instruction = "Hold still";
    }
  }

  Future<void> _captureAndFinish() async {
    setState(() {
      _currentAction = LivenessAction.verify;
      _instruction = "Verifying...";
      _progress = 1.0;
    });
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    if (_isTakingPicture) return;
    _isTakingPicture = true;

    try {
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 1000));

      final XFile file = await _controller!.takePicture();
      HapticFeedback.mediumImpact();
      
      // ✅ UPDATE BLOC WITH IMAGE
      if (mounted) {
        context.read<SignupVendorBloc>().add(SelfieCaptured(file.path));
        setState(() => _currentAction = LivenessAction.success);
      }
    } catch (e) {
      _resetLiveness(); // Retry on fail
    }
  }

  // ... (Keep the _inputImageFromCameraImage helper from previous code) ...
  // I omitted it here to save space, but copy it from your LivenessScreen code.
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;
    final rotation = _toInputRotation(camera.sensorOrientation);
    if (rotation == null) return null;
    if (Platform.isAndroid) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
    return null;
  }

  InputImageRotation? _toInputRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0: return InputImageRotation.rotation0deg;
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return null;
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _faceDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;
    final isDone = s.selfiePath != null; // Check if Bloc has the image

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Face Verification', style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF111111))),
            SizedBox(height: 8.h),
            Text('Follow the instructions to verify you are a real person.', style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666))),
            
            SizedBox(height: 32.h),

            // --- CAMERA CONTAINER ---
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(200.r), // Circle/Oval
                child: Container(
                  width: 280.w,
                  height: 350.h,
                  color: Colors.black,
                  child: isDone
                      ? Image.file(File(s.selfiePath!), fit: BoxFit.cover) // Show captured image
                      : _isCameraInitialized
                          ? CameraPreview(_controller!)
                          : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // --- INSTRUCTION TEXT ---
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isDone ? "Verification Complete ✅" : _instruction,
                  key: ValueKey(_instruction),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.green : KorraColors.brand,
                  ),
                ),
              ),
            ),
            
            // --- ERROR MESSAGE (FROM BLOC) ---
            if (s.ninError != null || s.bvnError != null)
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: Center(
                  child: Text(
                    s.ninError ?? s.bvnError!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.red),
                  ),
                ),
              ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}