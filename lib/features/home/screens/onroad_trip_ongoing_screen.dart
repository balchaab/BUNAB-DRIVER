import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/swipable_button/slider_buttion_widget.dar.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class OnRoadTripOngoingScreen extends StatefulWidget {
  const OnRoadTripOngoingScreen({super.key});

  @override
  State<OnRoadTripOngoingScreen> createState() => _OnRoadTripOngoingScreenState();
}

class _OnRoadTripOngoingScreenState extends State<OnRoadTripOngoingScreen> {
  late final DateTime _startedAt;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startedAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  Future<void> _showCompleteDialog(BuildContext context, RideController rideController) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => Get.back(),
                    child: Icon(Icons.highlight_remove_rounded, color: Theme.of(context).hintColor),
                  ),
                ),
                Text('Seems you reached destination', style: textMedium),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await rideController.finishOnRoadTrip();
                        },
                        child: const Text('End'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GetBuilder<RideController>(builder: (rideController) {
          final int passengers = int.tryParse('${rideController.activeOnRoadTrip?['family_count'] ?? 1}') ?? 1;
          final bool loading = rideController.isOnRoadActionLoading && rideController.onRoadActionType == 'finish';
          return Column(
            children: [
              AppBarWidget(
                title: 'On-road Ongoing Trip',
                showBackButton: true,
                onBackPressed: () => Get.back(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trip is ongoing', style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('Passengers: $passengers', style: textMedium),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text('Elapsed Time: ${_formatDuration(_elapsed)}', style: textMedium),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          'Complete this trip when customer(s) reach destination.',
                          style: textRegular.copyWith(color: Theme.of(context).hintColor),
                        ),
                        const Spacer(),
                        if (loading)
                          const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else ...[
                          SliderButton(
                            action: () => _showCompleteDialog(context, rideController),
                            label: Text(
                              'complete'.tr,
                              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                            ),
                            dismissThresholds: 0.5,
                            dismissible: false,
                            shimmer: false,
                            width: Get.width,
                            height: 40,
                            buttonSize: 40,
                            radius: 20,
                            icon: Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
                                child: Center(
                                  child: Icon(
                                    Get.find<LocalizationController>().isLtr
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.keyboard_arrow_left,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            isLtr: Get.find<LocalizationController>().isLtr,
                            boxShadow: const BoxShadow(blurRadius: 0),
                            buttonColor: Colors.transparent,
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            baseColor: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          SliderButton(
                            action: () async {
                              await rideController.finishOnRoadTrip(cancelled: true);
                              if (mounted) {
                                Get.offAll(() => const DashboardScreen());
                              }
                            },
                            label: Text(
                              'cancel_ride'.tr,
                              style: textRegular.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: Dimensions.fontSizeLarge,
                              ),
                            ),
                            dismissThresholds: 0.5,
                            dismissible: false,
                            shimmer: false,
                            width: Get.width,
                            height: 40,
                            buttonSize: 40,
                            radius: 20,
                            icon: Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
                                child: Center(
                                  child: Icon(
                                    Get.find<LocalizationController>().isLtr
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.keyboard_arrow_left,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            isLtr: Get.find<LocalizationController>().isLtr,
                            boxShadow: const BoxShadow(blurRadius: 0),
                            buttonColor: Colors.transparent,
                            backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                            baseColor: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
