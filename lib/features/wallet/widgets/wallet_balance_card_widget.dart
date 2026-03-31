import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/wallet_logo_watermark_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/top_up_wallet_screen.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class WalletBalanceCardWidget extends StatelessWidget {
  const WalletBalanceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final balance = profileController.profileInfo?.wallet?.walletBalance ?? 0;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          0,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 228),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(
                width: 0.25,
                color: Theme.of(context).hintColor.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              child: Stack(
                children: [
                  const WalletLogoWatermark(scale: 3.05),
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'wallet_balance'.tr,
                          style: textSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Text(
                          PriceConverter.convertPrice(context, balance),
                          style: textRobotoBold.copyWith(
                            fontSize: Dimensions.fontSizeOverLarge + 10,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => Get.to(() => const TopUpWalletScreen()),
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeExtraSmall,
                                horizontal: Dimensions.paddingSizeExtraSmall,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 22,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'add_to_wallet'.tr,
                                    style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
