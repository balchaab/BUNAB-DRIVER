import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_bottomsheet_widget.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/util/images.dart';


class BottomMenuController extends GetxController implements GetxService{
  int _currentTab = 0;
  int get currentTab => _currentTab;


  void resetNavBar(){
    _currentTab = 0;
  }
  void setTabIndex(int index) {
    _currentTab = index;
    if (index == 0) {
      try {
        final RideController rideController = Get.find<RideController>();
        rideController.fetchActiveOnRoadTrip();
        rideController.getLastRideDetail();
        rideController.ongoingTripList();
      } catch (_) {}
    }
    if (index == 1) {
      try {
        final TripController tripController = Get.find<TripController>();
        tripController.getTripList(1, '', '', 'ride_request',
            tripController.selectedFilterTypeName, tripController.selectedStatusName);
      } catch (_) {}
    }
    update();
  }

  void exitApp() {
    Get.bottomSheet(ConfirmationBottomsheetWidget(
      icon: Images.exitIcon,
      title: 'exit_app'.tr,
      description: 'do_you_want_to_exit_the_app'.tr,
      onYesPressed: ()=> SystemNavigator.pop(),
      onNoPressed: ()=> Get.back(),
    ));
  }

}
