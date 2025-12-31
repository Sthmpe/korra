import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import 'package:korra/presentation/shared/widgets/show_app_snackbar.dart';
import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';

class PlanDetailsLoaderScreen extends StatefulWidget {
  final String planId;
  final CustomerRepository? repo; 

  const PlanDetailsLoaderScreen({
    super.key, 
    required this.planId,
    this.repo,
  });

  @override
  State<PlanDetailsLoaderScreen> createState() => _PlanDetailsLoaderScreenState();
}

class _PlanDetailsLoaderScreenState extends State<PlanDetailsLoaderScreen> {
  late final CustomerRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? CustomerRepository();
    _fetchAndRedirect();
  }

  Future<void> _fetchAndRedirect() async {
    try {
      // 1. Fetch the Plan Document
      final plan = await _repo.getPlanById(widget.planId);
      
      if (plan == null) {
        _handleError("This plan could not be found.");
        return;
      }

      // 2. Success: Replace this loader with the Real Screen
      Get.offNamed(
        Routes.customerPlanDetails,
        arguments: {
          'plan': plan,
          'customerRepo': _repo,
        }
      );

    } catch (e) {
      debugPrint("Error loading plan from notification: $e");
      _handleError("Unable to load plan details. Please check your connection.");
    }
  }

  void _handleError(String message) {
    // A. Show Error SnackBar
    showAppSnackbar(message, SnackbarType.error);
    // B. Safe Navigation Logic
   // 👇 FIX 1: Added parentheses () to canPop
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      // 👇 FIX 2: Get current UID from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        Get.offAllNamed(Routes.customerShell);
      } else {
        Get.offAllNamed(Routes.roleLoginScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple loader while processing
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: KorraColors.brand, // Korra Brand Color
        ),
      ),
    );
  }
}