import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:ride_sharing_user_app/features/face_verification/controllers/face_verification_controller.dart';
import 'package:ride_sharing_user_app/features/face_verification/widgets/home_face_verification_warning_widget.dart';
import 'package:ride_sharing_user_app/features/home/screens/onroad_trip_start_screen.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_referral_view_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/refund_alert_bottomsheet.dart';
import 'package:ride_sharing_user_app/features/notification/widgets/notification_shimmer_widget.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/screens/out_of_zone_map_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/widgets/cash_in_hand_warning_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/home_screen_helper.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/home/widgets/add_vehicle_design_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/ongoing_ride_card_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/profile_info_card_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/vehicle_pending_widget.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_menu_screen.dart';
import 'package:ride_sharing_user_app/features/map/screens/map_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/sliver_delegate.dart';
import 'package:ride_sharing_user_app/common_widgets/zoom_drawer_context_widget.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeMenu extends GetView<ProfileController> {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) => ZoomDrawer(
        controller: controller.zoomDrawerController,
        menuScreen: const ProfileMenuScreen(),
        mainScreen: const HomeScreen(),
        borderRadius: 24.0,
        isRtl: !Get.find<LocalizationController>().isLtr,
        angle: -5.0,
        menuBackgroundColor: Theme.of(context).primaryColor,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        mainScreenScale: .4,
        mainScreenTapClose: true,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  JustTheController rideShareToolTip = JustTheController();
  JustTheController parcelDeliveryToolTip = JustTheController();
  final ScrollController _scrollController = ScrollController();
  bool _isShowRideIcon = true;
  bool _showOnRoadTripActions = false;


  @override
  void initState() {
    super.initState();

    _scrollController.addListener((){
      if(_scrollController.offset > 20){
        setState(() {
          _isShowRideIcon = false;
        });
      }else{
        setState(() {
          _isShowRideIcon = true;
        });
      }
    });
    // loadData() calls getProfileInfo() which sync-updates ProfileController before its first await.
    // HomeScreen is built under ZoomDrawer (RawGestureDetector) inside GetBuilder<ProfileController>;
    // updating the parent controller during this subtree's build triggers a framework assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadData();
    });
  }

  @override
  void dispose() {
    rideShareToolTip.dispose();
    parcelDeliveryToolTip.dispose();
    _scrollController.dispose();

    super.dispose();
  }


  Future<void> loadData() async{
    final RideController rideController = Get.find<RideController>();

    Get.find<ProfileController>().getCategoryList(1);
    Get.find<ProfileController>().getProfileInfo();
    Get.find<ProfileController>().getDailyLog();
    rideController.getLastRideDetail();
    HomeScreenHelper().checkAndShowBottomSheets();
    await loadOngoingList();
    rideController.fetchActiveOnRoadTrip();

    Get.find<ProfileController>().getProfileLevelInfo();
    if(rideController.ongoingRideList != null){
      HomeScreenHelper().ongoingLastRidePusherImplementation();
    }

    if(rideController.parcelListModel?.data != null){
      HomeScreenHelper().ongoingParcelListPusherImplementation();
    }

    await rideController.getPendingRideRequestList(1,limit: 100);
    if(rideController.getPendingRideRequestModel != null){
      HomeScreenHelper().pendingListPusherImplementation();
    }

    HomeScreenHelper().checkMaintanenceMode();
  }

  Future<void> _openActiveOnRoadTrip(RideController rideController) async {
    final bool ready = await rideController.prepareOnRoadTripForRideUi();
    if (ready && mounted) {
      Get.to(() => const MapScreen(fromScreen: 'on_road'));
    }
  }

  Future loadOngoingList() async {
    final RideController rideController = Get.find<RideController>();
    final SplashController splashController = Get.find<SplashController>();

    await rideController.getOngoingParcelList();
    await rideController.ongoingTripList();
    Map<String, dynamic>? lastRefundData = splashController.getLastRefundData();

    bool isShowBottomSheet = (rideController.liveOngoingRideCount == 0) && ((rideController.parcelListModel?.totalSize ?? 0) == 0 ) && lastRefundData != null;

    if(isShowBottomSheet) {
      await showModalBottomSheet(context: Get.context!, builder: (ctx)=> RefundAlertBottomSheet(
        title: lastRefundData['title'],
        description: lastRefundData['body'],
        tripId: lastRefundData['ride_request_id'],
      ));

      /// Removes the last refund data by setting it to null.
      splashController.addLastReFoundData(null);

    }
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () async{
        await loadData();
      },
      child: Scaffold(
          body: Stack(children: [
            CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(pinned: true, delegate: SliverDelegate(
                  height: GetPlatform.isIOS ? 150 : 120,
                  child: Column(children: [
                    AppBarWidget(
                      title: 'dashboard'.tr, showBackButton: false,
                      onTap: (){
                        Get.find<ProfileController>().toggleDrawer();
                      },
                    ),
                  ])
                  )),

                  SliverToBoxAdapter(child: GetBuilder<ProfileController>(builder: (profileController) {
                    return profileController.profileInfo != null ?
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 60.0),

                      if(profileController.profileInfo?.vehicle != null &&
                          profileController.profileInfo?.vehicle?.vehicleRequestStatus == 'approved'
                      )
                        GetBuilder<RideController>(builder: (rideController) {
                          final String? activeOnRoadId =
                              rideController.activeOnRoadTrip?['id']?.toString();
                          final String? firstLastId =
                              rideController.lastRideDetails != null &&
                                      rideController.lastRideDetails!.isNotEmpty
                                  ? rideController.lastRideDetails![0].id
                                  : null;
                          final bool showOnRoadBanner =
                              rideController.hasActiveOnRoadTrip &&
                                  (firstLastId == null ||
                                      firstLastId != activeOnRoadId);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showOnRoadBanner)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                  ),
                                  child: InkWell(
                                    onTap: () => _openActiveOnRoadTrip(rideController),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.paddingSizeDefault,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeDefault,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 0.25,
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.45),
                                        ),
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.paddingSizeDefault,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.directions_run_rounded,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(
                                            width: Dimensions.paddingSizeDefault,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'onroad_ride'.tr,
                                                  style: textBold.copyWith(
                                                    fontSize:
                                                        Dimensions.fontSizeLarge,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeExtraSmall,
                                                ),
                                                Text(
                                                  '${'trip_id'.tr}: ${rideController.activeOnRoadTrip?['ref_id'] ?? rideController.activeOnRoadTrip?['id'] ?? ''}',
                                                  style: textRegular.copyWith(
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (showOnRoadBanner)
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                              const OngoingRideCardWidget(),
                            ],
                          );
                        }),

                      if(profileController.profileInfo?.vehicle == null)
                        const AddYourVehicleWidget(),

                      GetBuilder<OutOfZoneController>(builder: (outOfZoneController){
                        return outOfZoneController.isDriverOutOfZone ?
                        InkWell(
                          onTap: ()=> Get.to(()=> const OutOfZoneMapScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.1)
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [
                            Icon(Icons.warning,size: 24,color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: Dimensions.paddingSizeDefault),

                            Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                              Text('you_are_out_of_zone'.tr,style: textBold.copyWith(fontSize: Dimensions.fontSizeSmall)),

                              Text('to_get_request_must'.tr,style: textRegular.copyWith(fontSize: 10,color: Theme.of(context).primaryColor))
                            ])
                          ]),

                          Image.asset(Images.homeOutOfZoneIcon,height: 30,width: 30)
                        ]),
                          ),
                        ) :
                        const SizedBox();
                      }),

                      if(profileController.profileInfo?.vehicle != null &&
                          (profileController.profileInfo?.vehicle?.vehicleRequestStatus == 'pending' || profileController.profileInfo?.vehicle?.vehicleRequestStatus == 'denied')
                      )
                        VehiclePendingWidget(),

                      if(
                      (!(profileController.profileInfo?.isVerified ?? false) ||
                          ((profileController.profileInfo?.isSuspended ?? false) && (profileController.profileInfo?.suspendReason == 'face_verification')) ||
                          (profileController.profileInfo?.needVerification ?? false)) && (Get.find<SplashController>().config?.verifyDriverIdentity ?? false)
                      )
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                              color: Theme.of(context).cardColor
                          ),
                          padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                          margin: EdgeInsets.all(Dimensions.paddingSizeDefault).copyWith(bottom: 0),
                          child: Row(children: [
                            Image.asset(Images.nonVerificationIcon, height: 25, width: 25),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Expanded(child: Text('verify_your_id_to_become_a_driver'.tr, style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)))),

                            InkWell(
                              onTap: ()=> Get.find<FaceVerificationController>().requestCameraPermission(),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                    color: Theme.of(context).primaryColor
                                ),
                                padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                                child: Text('verify'.tr, style: textRegular.copyWith(color: Theme.of(context).cardColor)),
                              ),
                            )
                          ]),
                        ),


                      if(Get.find<SplashController>().config?.referralEarningStatus ?? false)
                        const HomeReferralViewWidget(),

                      const SizedBox(height: 100),
                    ]) :
                    const NotificationShimmerWidget();
                  }))
                ]
            ),

            GetBuilder<ProfileController>(builder: (profileController){
              return profileController.isCashInHandHoldAccount ?
              CashInHandWarningWidget() :
              (profileController.profileInfo?.isSuspended ?? false) ?
              HomeFaceVerificationWarningWidget() : const SizedBox();
            }),

            Positioned(top: GetPlatform.isIOS ? 120 : 90, left: 0, right: 0,
              child: GetBuilder<ProfileController>(builder: (profileController) {
                return GestureDetector(
                    onTap: (){
                      Get.to(()=> const ProfileScreen());
                    },
                    child: ProfileStatusCardWidget(profileController: profileController));
              }),
            ),
          ]),

          floatingActionButton: GetBuilder<RideController>(builder: (rideController) {
            int ridingCount = rideController.liveOngoingRideCount;
            int parcelCount = rideController.parcelListModel?.totalSize ?? 0;

            if(Get.find<SplashController>().isShowToolTips){
              showToolTips(ridingCount,parcelCount);
            }

            final bool hasOnRoadItems = true;
            final bool canExpand = hasOnRoadItems;
            final bool hasOngoingTrip = ridingCount > 0 || rideController.hasActiveOnRoadTrip;

            return Padding(
              padding: EdgeInsets.only(bottom: Get.height * 0.08),
              child: SizedBox(
                width: 220,
                height: 170,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      right: 0,
                      bottom: _showOnRoadTripActions ? 72 : 60,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _showOnRoadTripActions ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !_showOnRoadTripActions,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                offset: _showOnRoadTripActions ? Offset.zero : const Offset(0.18, 0.2),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  scale: _showOnRoadTripActions ? 1 : 0.92,
                                  child: _buildOnRoadActionRow(
                                    context: context,
                                    label: 'onroad_ride'.tr,
                                    icon: Icons.directions_run_rounded,
                                    onLabelTap: () {
                                      if (rideController.hasActiveOnRoadTrip) {
                                        _openActiveOnRoadTrip(rideController);
                                      } else if (rideController.hasRegularOngoingRide) {
                                        showCustomSnackBar(
                                          'you_cannot_start_this_trip'.tr,
                                          isError: true,
                                        );
                                      } else {
                                        Get.to(() => const OnRoadTripStartScreen());
                                      }
                                    },
                                    onIconTap: () {
                                      if (rideController.hasActiveOnRoadTrip) {
                                        _openActiveOnRoadTrip(rideController);
                                      } else if (rideController.hasRegularOngoingRide) {
                                        showCustomSnackBar(
                                          'you_cannot_start_this_trip'.tr,
                                          isError: true,
                                        );
                                      } else {
                                        Get.to(() => const OnRoadTripStartScreen());
                                      }
                                    },
                                    isLoading: rideController.isOnRoadActionLoading && rideController.onRoadActionType == 'start',
                                  ),
                                ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              AnimatedSlide(
                                duration: const Duration(milliseconds: 290),
                                curve: Curves.easeOutCubic,
                                offset: _showOnRoadTripActions ? Offset.zero : const Offset(0.25, 0.35),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  scale: _showOnRoadTripActions ? 1 : 0.9,
                                  child: _buildOnRoadActionRow(
                                    context: context,
                                    label: 'ongoing_ride'.tr,
                                    icon: Icons.pause_rounded,
                                    onLabelTap: () async {
                                      if (rideController.hasActiveOnRoadTrip) {
                                        await _openActiveOnRoadTrip(rideController);
                                      } else if (rideController.hasRegularOngoingRide) {
                                        final String? id =
                                            rideController.firstBlockingOngoingTripId;
                                        if (id != null) {
                                          await rideController
                                              .openTripMapFromDashboard(id);
                                        }
                                      } else {
                                        showCustomSnackBar('no_trip_available'.tr);
                                      }
                                    },
                                    onIconTap: () async {
                                      if (rideController.hasActiveOnRoadTrip) {
                                        await _openActiveOnRoadTrip(rideController);
                                      } else if (rideController.hasRegularOngoingRide) {
                                        final String? id =
                                            rideController.firstBlockingOngoingTripId;
                                        if (id != null) {
                                          await rideController
                                              .openTripMapFromDashboard(id);
                                        }
                                      } else {
                                        showCustomSnackBar('no_trip_available'.tr);
                                      }
                                    },
                                    isLoading: rideController.isOnRoadActionLoading && rideController.onRoadActionType == 'finish',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (hasOnRoadItems)
                      JustTheTooltip(
                        backgroundColor: Get.isDarkMode
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyMedium!.color,
                        controller: rideShareToolTip,
                        preferredDirection: AxisDirection.right,
                        tailLength: 10,
                        tailBaseWidth: 20,
                        content: Container(
                          width: 120,
                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          child: Text(
                            'onroad_ride'.tr,
                            style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (canExpand) {
                              setState(() {
                                _showOnRoadTripActions = !_showOnRoadTripActions;
                              });
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                turns: _showOnRoadTripActions ? 0.06 : 0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  height: 50,
                                  width: 50,
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColor,
                                    boxShadow: _showOnRoadTripActions
                                        ? [
                                            BoxShadow(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.32),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ]
                                        : const [],
                                  ),
                                  child: Image.asset(Images.carFrontIcon),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 18,
                                      width: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      child: Center(
                                        child: Text(
                                          hasOngoingTrip ? '1' : '0',
                                          style: textRegular.copyWith(
                                            color: Theme.of(context).cardColor,
                                            fontSize: Dimensions.fontSizeSmall,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );

          })
      ),
    );
  }

  void showToolTips(int ridingCount, int parcelCount){
    WidgetsBinding.instance.addPostFrameCallback((_){
      Future.delayed(const Duration(seconds: 1)).then((_){
        if(ridingCount > 0 && _isShowRideIcon){
          rideShareToolTip.showTooltip();
          Get.find<SplashController>().hideToolTips();
          Future.delayed(const Duration(seconds: 5)).then((_){
            rideShareToolTip.hideTooltip();
          });
        }

        if(parcelCount > 0 && _isShowRideIcon){
          parcelDeliveryToolTip.showTooltip();
          Get.find<SplashController>().hideToolTips();
          Future.delayed(const Duration(seconds: 5)).then((_){
            parcelDeliveryToolTip.hideTooltip();
          });
        }

      });
    });
  }

  Widget _buildOnRoadActionRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onLabelTap,
    required VoidCallback onIconTap,
    required bool isLoading,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onLabelTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
              ),
              child: Text(label, style: textMedium),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: isLoading ? null : onIconTap,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

}





