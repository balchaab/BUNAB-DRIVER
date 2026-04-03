import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/common_widgets/swipable_button/slider_buttion_widget.dar.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/home/screens/onroad_trip_ongoing_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class OnRoadTripPrestartScreen extends StatefulWidget {
  final List<String> passengerPhones;
  const OnRoadTripPrestartScreen({super.key, required this.passengerPhones});

  @override
  State<OnRoadTripPrestartScreen> createState() => _OnRoadTripPrestartScreenState();
}

class _OnRoadTripPrestartScreenState extends State<OnRoadTripPrestartScreen> {
  bool _showOtp = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String get _firstPhone {
    if (widget.passengerPhones.isEmpty) return '-';
    final String p = widget.passengerPhones.first;
    return p.startsWith('251') ? p.replaceFirst('251', '0') : p;
  }

  void _verifyStaticOtp() {
    if (_otpController.text.trim() != '0000') {
      Get.snackbar('OTP', 'Use 0000 for on-road trip verification');
      return;
    }
    Get.off(() => const OnRoadTripOngoingScreen());
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initial = Get.find<LocationController>().initialPosition;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 14),
            zoomControlsEnabled: false,
            compassEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeLarge,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(children: const [
                          CircleAvatar(radius: 9, child: Text('A', style: TextStyle(fontSize: 10))),
                          SizedBox(width: 10),
                          Text('Your Location'),
                        ]),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        Row(children: [
                          const CircleAvatar(radius: 9, child: Text('B', style: TextStyle(fontSize: 10))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_firstPhone)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  if (!_showOtp)
                    SliderButton(
                      action: () => setState(() => _showOtp = true),
                      label: Text(
                        'Start Ride',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                      ),
                      dismissThresholds: 0.5,
                      dismissible: false,
                      shimmer: false,
                      width: Get.width,
                      height: 48,
                      buttonSize: 42,
                      radius: 24,
                      icon: _sliderIcon(context, isError: false),
                      isLtr: Get.find<LocalizationController>().isLtr,
                      boxShadow: const BoxShadow(blurRadius: 0),
                      buttonColor: Colors.transparent,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                      baseColor: Theme.of(context).primaryColor,
                    )
                  else
                    Column(
                      children: [
                        Text('Enter OTP (Use 0000)', style: textMedium),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '0000',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        SliderButton(
                          action: _verifyStaticOtp,
                          label: Text(
                            'Verify OTP',
                            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                          ),
                          dismissThresholds: 0.5,
                          dismissible: false,
                          shimmer: false,
                          width: Get.width,
                          height: 48,
                          buttonSize: 42,
                          radius: 24,
                          icon: _sliderIcon(context, isError: false),
                          isLtr: Get.find<LocalizationController>().isLtr,
                          boxShadow: const BoxShadow(blurRadius: 0),
                          buttonColor: Colors.transparent,
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          baseColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  SliderButton(
                    action: () async {
                      await Get.find<RideController>().finishOnRoadTrip(cancelled: true);
                      Get.offAll(() => const DashboardScreen());
                    },
                    label: Text(
                      'Cancel Ride',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeLarge),
                    ),
                    dismissThresholds: 0.5,
                    dismissible: false,
                    shimmer: false,
                    width: Get.width,
                    height: 48,
                    buttonSize: 42,
                    radius: 24,
                    icon: _sliderIcon(context, isError: true),
                    isLtr: Get.find<LocalizationController>().isLtr,
                    boxShadow: const BoxShadow(blurRadius: 0),
                    buttonColor: Colors.transparent,
                    backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                    baseColor: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderIcon(BuildContext context, {required bool isError}) {
    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
        child: Center(
          child: Icon(
            Get.find<LocalizationController>().isLtr ? Icons.arrow_forward_ios_rounded : Icons.keyboard_arrow_left,
            color: isError ? Theme.of(context).colorScheme.error : Colors.grey,
            size: 18,
          ),
        ),
      ),
    );
  }
}
