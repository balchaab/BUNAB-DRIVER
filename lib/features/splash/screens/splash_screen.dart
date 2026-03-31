import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/login_helper.dart';
import 'package:ride_sharing_user_app/localization/language_selection_screen.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationData;
  final String? userName;

  const SplashScreen({super.key, this.notificationData, this.userName});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {

    Get.find<SplashController>().initSharedData();
    Get.find<TripController>().rideCancellationReasonList();
    Get.find<TripController>().parcelCancellationReasonList();
    Get.find<AuthController>().remainingTime();
    Get.find<WalletController>().getPaymentGetWayList();

    bool isSuccess = await Get.find<SplashController>().getConfigData();

    if (!mounted) return;

    if (isSuccess) {
      if (Get.find<LocalizationController>().haveLocalLanguageCode()) {
        LoginHelper().checkLoginRoutes(widget.notificationData, widget.userName);
      } else {
        Get.offAll(() => LanguageSelectionScreen(
          userName: widget.userName,
          notificationData: widget.notificationData,
        ));
      }
    } else {
      // fallback retry
      Future.delayed(const Duration(seconds: 2), () {
        _initializeApp();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAEFAC),
      body: Stack(
        children: [

          /// splash image
          SizedBox(
            width: Get.width,
            height: Get.height,
            child: Image.asset(
              'assets/image/splash.png',
              fit: BoxFit.cover,
            ),
          ),

          /// loading indicator
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF712F30),
              ),
            ),
          ),

        ],
      ),
    );
  }
}