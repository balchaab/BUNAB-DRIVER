import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/util/images.dart';

/// Large, low-opacity app logo behind wallet UI (dashboard carousel + My Wallet card).
class WalletLogoWatermark extends StatelessWidget {
  /// Scale applied around the center so the mark fills the card like the design reference.
  final double scale;

  const WalletLogoWatermark({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: Get.isDarkMode ? 0.10 : 0.07,
          child: Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Image.asset(
                Images.logo,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
