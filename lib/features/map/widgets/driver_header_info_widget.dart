import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';

import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverHeaderInfoWidget extends StatelessWidget {
  const DriverHeaderInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideController>(builder: (rideController){
      final trip = rideController.tripDetail;
      final bool canNavigate = _isShowNavigatorButton(trip?.currentStatus) &&
          _hasValidCoordinates(trip);
      return Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 60, Dimensions.paddingSizeDefault,0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Theme.of(context).primaryColor)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: ImageWidget(width: 50,height: 50,
                  image: '${Get.find<SplashController>().config!.imageBaseUrl!.profileImage}/${Get.find<ProfileController>().driverImage}',
                ),
              ),
            ),

            const Spacer(),

            if (canNavigate)
              InkWell(
                onTap: () async{
                  final coords = _targetCoordinates(trip);
                  if (coords != null) {
                    _openMaps(coords.$1, coords.$2);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
                    boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha: .25), blurRadius: 1,spreadRadius: 1, offset: const Offset(0,1))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: SizedBox(width: Dimensions.iconSizeMedium, height: Dimensions.iconSizeMedium,
                      child: Image.asset(Images.navigation, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              )
          ],
        ),
      );
    });
  }


  Future<void> _openMaps(double lat, double long) async {
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$long&key=${AppConstants.polylineMapKey}');
    final appleMapsUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$long&dirflg=d');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch maps';
    }
  }

  bool _isShowNavigatorButton(String? currentStatus){
    if(currentStatus == 'accepted' || currentStatus == 'pending' || currentStatus == 'ongoing' || currentStatus == 'out_for_pickup'){
      return true;
    }else{
      return false;
    }
  }

  bool _hasValidCoordinates(TripDetail? trip) {
    if (trip == null) return false;
    final bool isPickupPhase = trip.currentStatus == 'accepted' ||
        trip.currentStatus == 'pending' ||
        trip.currentStatus == 'out_for_pickup';
    final coords = isPickupPhase
        ? trip.pickupCoordinates?.coordinates
        : trip.destinationCoordinates?.coordinates;
    return coords != null &&
        coords.length >= 2 &&
        coords[0] != null &&
        coords[1] != null;
  }

  /// Returns (lat, long) for external maps, or null if unavailable.
  (double, double)? _targetCoordinates(TripDetail? trip) {
    if (!_hasValidCoordinates(trip)) return null;
    final bool isPickupPhase = trip!.currentStatus == 'accepted' ||
        trip.currentStatus == 'pending' ||
        trip.currentStatus == 'out_for_pickup';
    final List<dynamic>? coords = isPickupPhase
        ? trip.pickupCoordinates?.coordinates
        : trip.destinationCoordinates?.coordinates;
    if (coords == null || coords.length < 2) return null;
    final double? lat = (coords[1] as num?)?.toDouble();
    final double? long = (coords[0] as num?)?.toDouble();
    if (lat == null || long == null) return null;
    return (lat, long);
  }

}
