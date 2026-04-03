import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/helper/date_converter.dart';
import 'package:ride_sharing_user_app/helper/price_converter.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/home/widgets/last_trip_shimmer_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/custom_arrow_icon_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/custom_menu_driving_status_widget.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/trip_details_screen.dart';
import 'package:ride_sharing_user_app/common_widgets/no_data_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/wallet_logo_watermark_widget.dart';

class OngoingRideCardWidget extends StatelessWidget {
  const OngoingRideCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
    return GetBuilder<RideController>(builder: (rideController) {
      return GetBuilder<ProfileController>(builder: (profileController) {
      String tripDate = '0', suffix = 'st';
      List<dynamic> extraRoute =[];
      int count = 1;
      if(rideController.lastRideDetails != null && rideController.lastRideDetails!.isNotEmpty){
        tripDate = DateConverter.dateTimeStringToDateOnly(rideController.lastRideDetails![0].createdAt!);
        if(tripDate == "1"){
          suffix = "st";
        }else if(tripDate == "2"){
          suffix = "nd";
        }else if(tripDate == "3"){
          suffix = "rd";
        }else{
          suffix = "th";
        }

        for(int i =0; i< extraRoute.length; i++){
          if(extraRoute[i] != ''){
            count ++;
            if (kDebugMode) {
              print(count);
            }
          }
        }
      }

      return rideController.lastRideDetails != null ?
      rideController.lastRideDetails!.isNotEmpty ?
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: .25, color: Theme.of(context).hintColor.withValues(alpha: 0.4)),
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                  child: Column(children: [
                    Text('$tripDate $suffix', style: textBold.copyWith( fontSize: Dimensions.fontSizeLarge)),

                    Text(DateConverter.dateTimeStringToMonthAndYear(rideController.lastRideDetails![0].createdAt!), style: textRegular),
                  ]),
                ),
                const Spacer(),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3))
                  ),
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Text(capitalize(rideController.lastRideDetails![0].currentStatus!.tr), style: textRegular.copyWith()),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [

                CustomArrowIconWidget(
                  onTap: (){
                    if(rideController.orderStatusSelectedIndex != 0){
                      rideController.setOrderStatusTypeIndex(rideController.orderStatusSelectedIndex-1);
                    }
                  },
                  color: rideController.orderStatusSelectedIndex == 0 ?
                  Theme.of(context).hintColor.withValues(alpha: .35) :
                  Theme.of(context).primaryColor.withValues(alpha: .25),
                  icon: CupertinoIcons.left_chevron,
                  iconColor: rideController.orderStatusSelectedIndex == 0 ?
                  Theme.of(context).hintColor.withValues(alpha: .7) : Theme.of(context).primaryColor,
                ),

                InkWell(
                    onTap: (){
                      if(rideController.orderStatusSelectedIndex == 0){
                        Get.find<BottomMenuController>().setTabIndex(3);
                        return;
                      }
                      if(rideController.lastRideDetails![0].currentStatus == AppConstants.outForPickup ||
                          rideController.lastRideDetails![0].currentStatus == AppConstants.ongoing ||
                          rideController.lastRideDetails![0].currentStatus == AppConstants.accepted ||
                          (rideController.lastRideDetails![0].currentStatus == AppConstants.completed && rideController.lastRideDetails![0].paymentStatus == AppConstants.unPaid)){
                        _moveToMapScreen(rideController.lastRideDetails![0].id!);
                      }else{
                        Get.to(()=> TripDetails(tripId: rideController.lastRideDetails![0].id!));
                      }
                    },
                    child: rideController.orderStatusSelectedIndex == 0
                        ? SizedBox(
                            width: 220,
                            height: 210,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.hardEdge,
                              children: [
                                const WalletLogoWatermark(scale: 3.05),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'my_wallet'.tr,
                                      textAlign: TextAlign.center,
                                      style: textSemiBold.copyWith(
                                        color: Theme.of(context).hintColor,
                                        fontSize: Dimensions.fontSizeExtraLarge,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                      child: Text(
                                        PriceConverter.convertPrice(
                                          context,
                                          profileController.profileInfo?.wallet?.walletBalance ?? 0,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: textRobotoBold.copyWith(
                                          fontSize: Dimensions.fontSizeOverLarge + 8,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'balance'.tr,
                                      textAlign: TextAlign.center,
                                      style: textRegular.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: Get.isDarkMode
                                            ? Theme.of(context).hintColor
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 10.0,
                      percent: rideController.orderStatusSelectedIndex == 1 ? 0.90 : 0.70,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          "estimated".tr,
                          style: textRegular.copyWith(color: Theme.of(context).hintColor),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeExtraSmall),
                          child: Text(
                            rideController.orderStatusSelectedIndex == 1 ?
                            '${(rideController.lastRideDetails![0].actualDistance ?? 0).toStringAsFixed(2)} km' :
                            '${rideController.lastRideDetails![0].estimatedDistance!.toStringAsFixed(2)} km',
                            style: textRobotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
                          ),
                        ),

                        Text(
                          rideController.orderStatusSelectedIndex == 1 ?
                          'estimated_km_driven'.tr : 'estimated_km_for_this_trip'.tr,
                          style: textRegular.copyWith(color:Get.isDarkMode? Theme.of(context).hintColor : Theme.of(context).primaryColor),
                        ),
                      ]),
                      progressColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).hintColor.withValues(alpha: .18),
                    )
                ),

                CustomArrowIconWidget(
                    onTap: (){
                      if(rideController.orderStatusSelectedIndex != 2){
                        rideController.setOrderStatusTypeIndex(rideController.orderStatusSelectedIndex+1);
                      }},
                    color : rideController.orderStatusSelectedIndex != 2 ?
                    Theme.of(context).primaryColor.withValues(alpha: .25):
                    Theme.of(context).hintColor.withValues(alpha: .35),
                    icon: CupertinoIcons.right_chevron,
                    iconColor: rideController.orderStatusSelectedIndex != 2 ?
                    Theme.of(context).primaryColor:Theme.of(context).hintColor.withValues(alpha: .7)),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.only(top:Dimensions.paddingSizeSmall),
              child: rideController.orderStatusSelectedIndex == 2 ?
              Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                Text(
                  '${'ongoing_trip_distance'.tr}:',
                  style: textRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Text(
                    rideController.lastRideDetails![0].estimatedDistance!.toStringAsFixed(2),
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),

                Text(
                  'km'.tr,
                  style: textRegular.copyWith(
                    color:Get.isDarkMode ?
                    Theme.of(context).hintColor :
                    Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ]) :
              SizedBox(height: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            SizedBox(
              height: Dimensions.orderStatusIconHeight,
              child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                CustomMenuDrivingStatusWidget( index: 0, selectedIndex: rideController.orderStatusSelectedIndex,icon: Images.walletBalanceIcon),

                CustomMenuDrivingStatusWidget( index: 1, selectedIndex: rideController.orderStatusSelectedIndex,icon: Images.drivedIcon),

                CustomMenuDrivingStatusWidget( index: 2, selectedIndex: rideController.orderStatusSelectedIndex,icon: Images.drivingIcon),

              ]),
            )
          ]),
        ),
      ) :
      const NoDataWidget(title: 'no_trip_found', fromHome: true) :
      const Padding(
        padding: EdgeInsets.only(top: 60.0),
        child: LastTripShimmerWidget(),
      );
    });
    });
  }
}

void _moveToMapScreen(String tripId) {
  Get.find<RideController>().openTripMapFromDashboard(tripId);
}
