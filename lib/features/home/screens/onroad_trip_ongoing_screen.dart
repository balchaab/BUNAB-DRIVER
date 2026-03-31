import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/features/home/screens/onroad_trip_summary_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                                    final response = await rideController.finishOnRoadTrip();
                                    if (response?.statusCode == 200 && mounted) {
                                      Get.off(() => OnRoadTripSummaryScreen(
                                            tripData: rideController.lastCompletedOnRoadTrip,
                                          ));
                                    }
                                  },
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Complete Trip'),
                          ),
                        ),
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
