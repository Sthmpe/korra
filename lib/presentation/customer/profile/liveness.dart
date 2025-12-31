// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:ui'; 
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart'; 
// import 'package:google_fonts/google_fonts.dart'; 
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LivenessScreen extends StatefulWidget {
//   final Function(String photoBase64) onVerificationSuccess;

//   const LivenessScreen({super.key, required this.onVerificationSuccess});

//   @override
//   State<LivenessScreen> createState() => _LivenessScreenState();
// }

// enum LivenessAction {
//   start,
//   blink,
//   turnLeft,
//   turnRight,
//   smile,
//   openMouth,
//   verify, 
//   success
// }

// class _LivenessScreenState extends State<LivenessScreen> {
//   // --- KORRA BRAND COLORS ---
//   static const Color _brandOrange = Color(0xFFA54600);
//   static const Color _textDark = Color(0xFF101828);
//   static const Color _textGrey = Color(0xFF667085);
//   static const Color _successGreen = Color(0xFF16A34A);
//   static const Color _errorRed = Color(0xFFD92D20); 
//   static const Color _bgWhite = Colors.white;

//   CameraController? _controller;
//   bool _isCameraInitialized = false;
//   bool _isProcessing = false;
//   bool _isTakingPicture = false;
//   XFile? _capturedFile;
  
//   // Logic State
//   List<LivenessAction> _actionQueue = [];
//   LivenessAction _currentAction = LivenessAction.start;
//   String _instruction = "Initializing...";
  
//   // Security State
//   int? _lockedFaceId; 
//   bool _isSecurityCompromised = false; 
  
//   // UI State
//   double _progress = 0.0; 
//   bool _eyesClosedDetected = false;
  
//   // Timeout Logic
//   Timer? _sessionTimer;
//   bool _hasTimedOut = false;

//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableClassification: true,
//       enableLandmarks: true,
//       enableTracking: true, 
//       performanceMode: FaceDetectorMode.accurate,
//       minFaceSize: 0.15,
//     ),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _resetLiveness();
//   }

//   void _startSessionTimer() {
//     _sessionTimer?.cancel();
//     _sessionTimer = Timer(const Duration(seconds: 30), () { 
//       if (mounted && 
//           !_hasTimedOut && 
//           !_isSecurityCompromised &&
//           _currentAction != LivenessAction.success && 
//           _currentAction != LivenessAction.verify) {
//         setState(() {
//           _hasTimedOut = true;
//           HapticFeedback.heavyImpact();
//         });
//       }
//     });
//   }

//   void _resetLiveness() {
//     setState(() {
//       _hasTimedOut = false;
//       _isSecurityCompromised = false;
//       _lockedFaceId = null; 
//       _currentAction = LivenessAction.start;
//       _eyesClosedDetected = false;
//       _capturedFile = null;
//       _isTakingPicture = false;
//       _progress = 0.0;
//       _actionQueue = [
//         LivenessAction.blink,
//         LivenessAction.smile,
//         LivenessAction.turnLeft,
//         LivenessAction.turnRight,
//         LivenessAction.openMouth,
//       ];
//       _instruction = "Position your face in the oval";
//     });
//     if (_isCameraInitialized) _startSessionTimer();
//   }

//   Future<void> _initializeCamera() async {
//     final status = await Permission.camera.request();
//     if (status != PermissionStatus.granted) {
//       if (mounted) Navigator.pop(context);
//       return;
//     }

//     final cameras = await availableCameras();
//     final frontCamera = cameras.firstWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.front,
//       orElse: () => cameras.first,
//     );

//     _controller = CameraController(
//       frontCamera,
//       ResolutionPreset.high,
//       enableAudio: false,
//       imageFormatGroup: Platform.isAndroid 
//           ? ImageFormatGroup.nv21 
//           : ImageFormatGroup.bgra8888,
//     );

//     try {
//       await _controller!.initialize();
//       if (!mounted) return;
//       setState(() {
//         _isCameraInitialized = true;
//         _instruction = "Position your face in the oval";
//       });
//       _startSessionTimer(); 
//       _controller!.startImageStream(_processCameraImage);
//     } catch (e) {
//       debugPrint("Camera init error: $e");
//     }
//   }

//   Future<void> _processCameraImage(CameraImage image) async {
//     if (_isProcessing || 
//         _isTakingPicture || 
//         _hasTimedOut || 
//         _isSecurityCompromised ||
//         _capturedFile != null || 
//         _currentAction == LivenessAction.verify) {
//       return;
//     }

//     _isProcessing = true;

//     try {
//       final inputImage = _inputImageFromCameraImage(image);
//       if (inputImage == null) return;

//       final faces = await _faceDetector.processImage(inputImage);

//       if (faces.isNotEmpty) {
//         _runLivenessLogic(faces.first);
//       }
//     } catch (e) {
//       debugPrint("Error processing face: $e");
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   void _runLivenessLogic(Face face) {
//     if (!mounted || _hasTimedOut || _isSecurityCompromised) return;

//     // --- SECURITY LAYER ---
//     if (_lockedFaceId == null) {
//       _lockedFaceId = face.trackingId;
//     } 
//     else if (face.trackingId != _lockedFaceId) {
//       setState(() {
//         _isSecurityCompromised = true;
//         _instruction = "Security Violation";
//         HapticFeedback.heavyImpact();
//       });
//       return;
//     }
//     // ----------------------

//     if (face.boundingBox.width < 120) { 
//       if (_instruction != "Move closer") {
//         setState(() => _instruction = "Move closer");
//       }
//       return;
//     }

//     if (_currentAction == LivenessAction.start) {
//       setState(() {
//          _instruction = "Perfect! Hold still...";
//       });
      
//       Future.delayed(const Duration(milliseconds: 1000), () {
//         if (mounted && _currentAction == LivenessAction.start) {
//           _nextAction();
//         }
//       });
//       return;
//     }

//     bool actionCompleted = false;

//     switch (_currentAction) {
//       case LivenessAction.blink:
//         double left = face.leftEyeOpenProbability ?? 1.0;
//         double right = face.rightEyeOpenProbability ?? 1.0;
//         if (left < 0.3 && right < 0.3) {
//           _eyesClosedDetected = true;
//         } else if (_eyesClosedDetected && left > 0.6 && right > 0.6) {
//           actionCompleted = true;
//           _eyesClosedDetected = false;
//         }
//         break;

//       case LivenessAction.smile:
//         if ((face.smilingProbability ?? 0) > 0.7) actionCompleted = true;
//         break;

//       case LivenessAction.turnLeft:
//         if ((face.headEulerAngleY ?? 0) > 20) actionCompleted = true;
//         break;

//       case LivenessAction.turnRight:
//         if ((face.headEulerAngleY ?? 0) < -20) actionCompleted = true;
//         break;

//       case LivenessAction.openMouth:
//         final bottomLip = face.landmarks[FaceLandmarkType.bottomMouth]?.position;
//         final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
//         if (bottomLip != null && nose != null) {
//           double noseToBottomLipDist = (bottomLip.y - nose.y).abs().toDouble();
//           double faceHeight = face.boundingBox.height.toDouble();
//           if (noseToBottomLipDist > (faceHeight * 0.15)) actionCompleted = true;
//         }
//         break;
        
//       default:
//         break;
//     }

//     if (actionCompleted) {
//       _completeCurrentAction();
//     }
//   }

//   void _completeCurrentAction() {
//     HapticFeedback.lightImpact(); 
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if(mounted) _nextAction();
//     });
//   }

//   void _nextAction() {
//     if (_actionQueue.isEmpty) {
//       _startVerificationPhase();
//     } else {
//       setState(() {
//         _currentAction = _actionQueue.removeAt(0);
//         _updateInstructionForAction(_currentAction);
//         _progress += 0.2; 
//       });
//     }
//   }

//   void _updateInstructionForAction(LivenessAction action) {
//     switch (action) {
//       case LivenessAction.blink: _instruction = "Blink your eyes"; break;
//       case LivenessAction.smile: _instruction = "Smile"; break;
//       case LivenessAction.turnLeft: _instruction = "Turn head Left"; break;
//       case LivenessAction.turnRight: _instruction = "Turn head Right"; break;
//       case LivenessAction.openMouth: _instruction = "Open mouth"; break;
//       default: _instruction = "Hold still";
//     }
//   }

//   void _startVerificationPhase() async {
//     _sessionTimer?.cancel();
//     setState(() {
//       _currentAction = LivenessAction.verify;
//       _instruction = "Verifying...";
//       _progress = 1.0; 
//     });

//     await Future.delayed(const Duration(milliseconds: 1500));
//     if (!mounted) return;
//     setState(() => _instruction = "Analyzing Biometrics...");

//     await Future.delayed(const Duration(milliseconds: 1500));
//     if (!mounted) return;
//     setState(() => _instruction = "Checking Liveness...");

//     await Future.delayed(const Duration(milliseconds: 1500));
//     if (!mounted) return;
//     setState(() => _instruction = "Finalizing...");

//     await Future.delayed(const Duration(milliseconds: 1500));
//     if (mounted) _captureAndFinish();
//   }

//   Future<void> _captureAndFinish() async {
//     if (_isTakingPicture) return;
//     _isTakingPicture = true;

//     try {
//       if (_controller == null || !_controller!.value.isInitialized) return;

//       await _controller!.stopImageStream();
//       await Future.delayed(const Duration(milliseconds: 100));

//       final XFile file = await _controller!.takePicture();
//       HapticFeedback.mediumImpact();
      
//       if (mounted) {
//         setState(() {
//           _capturedFile = file;
//           _currentAction = LivenessAction.success;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error taking picture: $e");
//     }
//   }

//   void _finalizeVerification() async {
//     if (_capturedFile == null) return;
//     try {
//       final bytes = await File(_capturedFile!.path).readAsBytes();
//       String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
//       widget.onVerificationSuccess(base64Image);
//     } catch (e) {
//       debugPrint("Error processing file: $e");
//     }
//   }

//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     final camera = _controller?.description;
//     if (camera == null) return null;
//     final rotation = _toInputRotation(camera.sensorOrientation);
//     if (rotation == null) return null;
//     if (Platform.isAndroid) {
//       final WriteBuffer allBytes = WriteBuffer();
//       for (final Plane plane in image.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();
//       return InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: rotation,
//           format: InputImageFormat.nv21,
//           bytesPerRow: image.planes[0].bytesPerRow,
//         ),
//       );
//     }
//     return null;
//   }

//   InputImageRotation? _toInputRotation(int sensorOrientation) {
//     switch (sensorOrientation) {
//       case 0: return InputImageRotation.rotation0deg;
//       case 90: return InputImageRotation.rotation90deg;
//       case 180: return InputImageRotation.rotation180deg;
//       case 270: return InputImageRotation.rotation270deg;
//       default: return null;
//     }
//   }

//   @override
//   void dispose() {
//     _sessionTimer?.cancel();
//     _faceDetector.close();
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_capturedFile != null) {
//       return _buildSuccessScreen();
//     }

//     final size = MediaQuery.of(context).size;
//     if (!_isCameraInitialized || _controller == null) {
//       return Scaffold(
//         backgroundColor: _bgWhite,
//         body: Center(child: CircularProgressIndicator(color: _brandOrange)),
//       );
//     }

//     // Calculations for Spacing
//     final ovalHeight = 380.h;
//     final ovalTop = (size.height - ovalHeight) / 2 - 30.h; // Centered but shifted up slightly
//     final ovalBottom = ovalTop + ovalHeight;
//     final textTop = ovalBottom + 32.h; // 32px gap between oval bottom and text

//     return Scaffold(
//       backgroundColor: _bgWhite, 
//       body: Stack(
//         children: [
//           // 1. Camera Feed
//           SizedBox.expand(
//             child: CameraPreview(_controller!),
//           ),

//           // 2. White Overlay Mask
//           CustomPaint(
//             size: size,
//             painter: WhiteOverlayPainter(),
//           ),

//           // 3. Progress Ring
//           Positioned(
//             top: ovalTop,
//             left: (size.width - 280.w) / 2,
//             child: TweenAnimationBuilder<double>(
//               duration: const Duration(milliseconds: 500),
//               curve: Curves.easeOut,
//               tween: Tween<double>(begin: 0, end: _progress),
//               builder: (context, val, _) {
//                 return SizedBox(
//                   width: 280.w,
//                   height: 380.h,
//                   child: CustomPaint(
//                     painter: ProgressRingPainter(
//                       progress: val,
//                       isVerifying: _currentAction == LivenessAction.verify,
//                       brandColor: _brandOrange,
//                       successColor: _successGreen,
//                       errorColor: _isSecurityCompromised ? _errorRed : null,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // 4. Header
//           Positioned(
//             top: 0,
//             left: 0, 
//             right: 0,
//             child: SafeArea(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: const Color(0xFFF2F4F7), 
//                       radius: 20.r,
//                       child: IconButton(
//                         icon: Icon(Icons.close, color: _textDark, size: 20.sp),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       "Liveness Check",
//                       style: GoogleFonts.inter(
//                         color: _textDark, 
//                         fontSize: 16.sp, 
//                         fontWeight: FontWeight.w600
//                       ),
//                     ),
//                     const Spacer(),
//                     SizedBox(width: 40.w), 
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // 5. Instruction Text
//           Positioned(
//             top: textTop, 
//             left: 20.w,
//             right: 20.w,
//             child: Column(
//               children: [
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 400),
//                   transitionBuilder: (Widget child, Animation<double> animation) {
//                     return FadeTransition(opacity: animation, child: SlideTransition(
//                       position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation),
//                       child: child,
//                     ));
//                   },
//                   child: Text(
//                     _instruction,
//                     key: ValueKey<String>(_instruction),
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.inter(
//                       color: _isSecurityCompromised ? _errorRed : _textDark,
//                       fontSize: 20.sp, // REDUCED FROM 24.sp
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 if (!_hasTimedOut && !_isSecurityCompromised && _currentAction != LivenessAction.verify)
//                   Text(
//                     "Keep your face within the frame",
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.inter(
//                       color: _textGrey, 
//                       fontSize: 12.sp, // REDUCED FROM 14.sp
//                       fontWeight: FontWeight.w500
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // 6. ERROR/TIMEOUT CARDS
//           if (_hasTimedOut || _isSecurityCompromised)
//             Positioned(
//               bottom: 40.h,
//               left: 20.w,
//               right: 20.w,
//               child: Container(
//                 padding: EdgeInsets.all(16.r),
//                 decoration: BoxDecoration(
//                   color: _isSecurityCompromised 
//                       ? const Color(0xFFFEF2F2) 
//                       : const Color(0xFFFFF7ED), 
//                   borderRadius: BorderRadius.circular(16.r),
//                   border: Border.all(
//                     color: _isSecurityCompromised 
//                         ? const Color(0xFFFECDCA) 
//                         : const Color(0xFFFFE4C2) 
//                   ),
//                   boxShadow: [
//                     BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           _isSecurityCompromised ? Icons.gpp_bad_rounded : Icons.timer_off_outlined, 
//                           color: _isSecurityCompromised ? _errorRed : _brandOrange, 
//                           size: 20.sp // Reduced size
//                         ),
//                         SizedBox(width: 10.w),
//                         Expanded(
//                           child: Text(
//                             _isSecurityCompromised ? "Security Alert" : "Session Expired",
//                             style: GoogleFonts.inter(
//                               fontSize: 14.sp, // Reduced from 16.sp
//                               fontWeight: FontWeight.w700, 
//                               color: _isSecurityCompromised ? const Color(0xFF7F1D1D) : const Color(0xFF7C2D12)
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 6.h),
//                     Text(
//                       _isSecurityCompromised 
//                           ? "Multiple faces or face swap detected."
//                           : "Time limit exceeded. Please retry.",
//                       style: GoogleFonts.inter(
//                         fontSize: 12.sp, // Reduced from 13.sp
//                         color: _isSecurityCompromised ? const Color(0xFF991B1B) : const Color(0xFF9A3412), 
//                         height: 1.4
//                       ),
//                     ),
//                     SizedBox(height: 12.h),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 40.h, // Fixed height for button
//                       child: ElevatedButton(
//                         onPressed: _resetLiveness,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _isSecurityCompromised ? _errorRed : _brandOrange,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           padding: EdgeInsets.zero, // Remove internal padding to use height
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
//                         ),
//                         child: Text("Retry", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.sp)),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // --- SUCCESS SCREEN ---
//   Widget _buildSuccessScreen() {
//     return Scaffold(
//       backgroundColor: _bgWhite,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.all(24.w),
//           child: Column(
//             children: [
//               const Spacer(),
//               TweenAnimationBuilder(
//                 duration: const Duration(milliseconds: 600),
//                 tween: Tween<double>(begin: 0, end: 1),
//                 builder: (context, double val, child) {
//                   return Transform.scale(
//                     scale: val,
//                     child: Container(
//                       padding: EdgeInsets.all(24.r),
//                       decoration: const BoxDecoration(
//                         color: Color(0xFFECFDF5), 
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(Icons.check_rounded, color: _successGreen, size: 60.sp),
//                     ),
//                   );
//                 },
//               ),
//               SizedBox(height: 32.h),
//               Text(
//                 "Identity Verified",
//                 style: GoogleFonts.inter(
//                   fontSize: 22.sp, // Reduced
//                   fontWeight: FontWeight.w700, 
//                   color: _textDark,
//                   letterSpacing: -0.5
//                 ),
//               ),
//               SizedBox(height: 12.h),
//               Text(
//                 "Facial verification successful.",
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.inter(
//                   color: _textGrey, 
//                   fontSize: 14.sp // Reduced
//                 ),
//               ),
              
//               SizedBox(height: 40.h),
              
//               // Captured Image Frame
//               Container(
//                 width: 160.w, // Slightly smaller
//                 height: 220.h,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20.r),
//                   border: Border.all(color: const Color(0xFFEAE6E2), width: 2),
//                   image: DecorationImage(
//                     image: FileImage(File(_capturedFile!.path)),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
              
//               const Spacer(),
              
//               SizedBox(
//                 width: double.infinity,
//                 height: 50.h, // Standard button height
//                 child: ElevatedButton(
//                   onPressed: _finalizeVerification,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _brandOrange,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     "Continue",
//                     style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // --- PAINTERS ---

// class WhiteOverlayPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white;
//     final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
//     // Manually calculating center to match the Positioned widget logic
//     // We shift it up by 30.h to visually center it above the fold
//     final holeRect = Rect.fromCenter(
//       center: Offset(size.width / 2, (size.height - 380.h) / 2 + 190.h - 30.h), 
//       width: 280.w, 
//       height: 380.h, 
//     );
    
//     final holePath = Path()..addOval(holeRect);
//     final path = Path.combine(PathOperation.difference, backgroundPath, holePath);
//     canvas.drawPath(path, paint);
//   }
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

// class ProgressRingPainter extends CustomPainter {
//   final double progress; 
//   final bool isVerifying;
//   final Color brandColor;
//   final Color successColor;
//   final Color? errorColor;

//   ProgressRingPainter({
//     required this.progress, 
//     required this.isVerifying,
//     required this.brandColor,
//     required this.successColor,
//     this.errorColor,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final rect = Rect.fromCenter(center: center, width: 280.w, height: 380.h);

//     final bgPaint = Paint()
//       ..color = const Color(0xFFF2F4F7) 
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 6;
//     canvas.drawOval(rect, bgPaint);

//     if (errorColor != null) {
//       final errorPaint = Paint()
//         ..color = errorColor!
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 6;
//        canvas.drawOval(rect, errorPaint);
//        return;
//     }

//     if (progress > 0) {
//       final activePaint = Paint()
//         ..color = brandColor 
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 6
//         ..strokeCap = StrokeCap.round;

//       if (isVerifying) {
//          activePaint.color = successColor; 
//          canvas.drawOval(rect, activePaint);
//       } else {
//         canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, activePaint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(ProgressRingPainter oldDelegate) {
//     return oldDelegate.progress != progress || 
//            oldDelegate.isVerifying != isVerifying ||
//            oldDelegate.errorColor != errorColor;
//   }
// }