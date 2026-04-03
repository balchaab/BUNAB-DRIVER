import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/chat/controllers/chat_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class RiderDetailsWidget extends StatelessWidget {
  final RideController rideController;
  const RiderDetailsWidget({super.key, required this.rideController});

  @override
  Widget build(BuildContext context) {
    final TripDetail? trip = rideController.tripDetail;
    if (trip == null) {
      return const SizedBox.shrink();
    }
    final Customer? customer = trip.customer;
    final String? fallbackPhone = TripPassengerUiHelper.phoneFromNote(trip.note);
    final String rating = trip.customerAvgRating ?? '0';
    final String noteLabel = TripPassengerUiHelper.passengerLabelFromNote(trip);

    return Container(
      width: Get.width,
      margin: const EdgeInsets.only(
        left: Dimensions.paddingSizeLarge,
        right: Dimensions.paddingSizeLarge,
        bottom: Dimensions.paddingSizeLarge,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(width: .75, color: Theme.of(context).hintColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      transform: Matrix4.translationValues(
                        Get.find<LocalizationController>().isLtr ? -3 : 3,
                        -3,
                        0,
                      ),
                      child: CircularPercentIndicator(
                        radius: 28,
                        percent: .75,
                        lineWidth: 1,
                        backgroundColor: Colors.transparent,
                        progressColor: Theme.of(Get.context!).primaryColor,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: ImageWidget(
                        width: 50,
                        height: 50,
                        image: customer?.profileImage != null
                            ? '${Get.find<SplashController>().config!.imageBaseUrl!.profileImageCustomer}'
                                '/${customer?.profileImage ?? ''}'
                            : '',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customer != null &&
                        customer.firstName != null &&
                        customer.lastName != null)
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${customer.firstName!} ${customer.lastName!}',
                        ),
                      ),
                    if (customer == null)
                      SizedBox(
                        width: Get.width * 0.45,
                        child: Text(
                          noteLabel.isEmpty ? 'customer'.tr : noteLabel,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textRegular,
                        ),
                      ),
                    if (customer != null)
                      Row(
                        children: [
                          Icon(
                            Icons.star_rate_rounded,
                            color: Theme.of(Get.context!).primaryColor,
                            size: Dimensions.iconSizeMedium,
                          ),
                          Text(
                            double.parse(rating).toStringAsFixed(1),
                            style: textRegular,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            Container(
              width: 1,
              height: 25,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.15),
            ),
            InkWell(
              onTap: customer?.id != null
                  ? () => Get.find<ChatController>().createChannel(
                        customer!.id!,
                        tripId: trip.id,
                      )
                  : null,
              child: Opacity(
                opacity: customer?.id != null ? 1 : 0.35,
                child: SizedBox(
                  width: Dimensions.iconSizeLarge,
                  child: Image.asset(Images.customerMessage, color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 25,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.15),
            ),
            InkWell(
              onTap: () {
                final String? tel = (customer?.phone != null && customer!.phone!.trim().isNotEmpty)
                    ? customer.phone
                    : fallbackPhone;
                if (tel == null || tel.isEmpty) return;
                Get.find<SplashController>().sendMailOrCall('tel:$tel', false);
              },
              child: Opacity(
                opacity: ((customer?.phone != null && customer!.phone!.trim().isNotEmpty) || fallbackPhone != null)
                    ? 1
                    : 0.35,
                child: SizedBox(
                  width: Dimensions.iconSizeLarge,
                  child: Image.asset(Images.customerCall, color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            const SizedBox(),
          ],
        ),
      ),
    );
  }
}
