import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/features/map/controllers/otp_time_count_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/services/ride_service_interface.dart';
import 'package:ride_sharing_user_app/features/safety_setup/controllers/safety_alert_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/controllers/trip_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/map/screens/map_screen.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/final_fare_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/on_going_trip_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/parcel_list_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/pending_ride_request_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/remaining_distance_model.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/trip/screens/payment_received_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';



class RideController extends GetxController implements GetxService{
  final RideServiceInterface rideServiceInterface;
  RideController({required this.rideServiceInterface});

  int _orderStatusSelectedIndex = 0;
  int get orderStatusSelectedIndex => _orderStatusSelectedIndex;
  bool isLoading = false;
  bool isPinVerificationLoading = false;
  String? _rideId;
  String? get rideId => _rideId;
  List<String>? _thumbnailPaths;
  List<String>? get thumbnailPaths => _thumbnailPaths;
  double totalParcelWeight = 0;
  int totalParcelCount = 0;
  TripDetail? tripDetail;
  JustTheController justTheController = JustTheController();


  void setRideId(String id){
    _rideId = id;
  }


  void setOrderStatusTypeIndex(int index){
    _orderStatusSelectedIndex = index;
    update();
  }



  Future<Response> bidding(String tripId, String amount) async {
    isLoading = true;
    update();
    Response response = await rideServiceInterface.bidding(tripId, amount);
    if (response.statusCode == 200) {
      Get.back();
      isLoading = false;
     showCustomSnackBar('bid_submitted_successfully'.tr, isError: false);
     getPendingRideRequestList(1);
    } else {
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }


  bool notSplashRoute= false;
  void updateRoute(bool showHideIcon, {bool notify = false}){
    notSplashRoute = showHideIcon;
    if(notify){
      update();
    }

  }

  Future<Response> getRideDetails(String tripId, {bool fromHomeScreen = false}) async {
    isLoading = true;
    _thumbnailPaths = null;
    if (kDebugMode) {
      print('details api call-====> $tripId');
    }
    Response response = await rideServiceInterface.getRideDetails(tripId);
    if (response.statusCode == 200) {
      final TripDetail? parsed = TripDetailsModel.fromJson(response.body).data;
      if (parsed == null) {
        isLoading = false;
        update();
        return response;
      }
      tripDetail = parsed;
      polyline = tripDetail!.encodedPolyline ?? '';
      isLoading = false;
      _syncOnRoadLocalStateWithTripDetail(tripId);

      List<Attachments> attachments = tripDetail?.parcelRefund?.attachments ?? [];
      _thumbnailPaths = List.filled(attachments.length, '');

      Future.forEach(attachments, (element) async{
        if(element.file?.contains('.mp4') ?? false){
          String? path = await generateThumbnail(element.file!);
          _thumbnailPaths?[tripDetail!.parcelRefund!.attachments!.indexOf(element)] =  path ?? '';

          update();
        }
      });

    }else if(response.statusCode == 403){
      isLoading = false;
    }else{
      isLoading = false;
      fromHomeScreen ? null : ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<Response> uploadScreenShots(String tripId, XFile file) async {
    Response response = await rideServiceInterface.uploadScreenShots(tripId, file);
    if (response.statusCode == 200) {
    }
    update();
    return response;
  }


  String polyline = '';

  Future<Response> getRideDetailBeforeAccept(String tripId) async {
    isLoading = true;
    update();
    Response response = await rideServiceInterface.getRideDetailBeforeAccept(tripId);
    if (response.statusCode == 200) {
      tripDetail = TripDetailsModel.fromJson(response.body).data!;
      isLoading = false;
      polyline = tripDetail!.encodedPolyline!;
      Get.find<RideController>().remainingDistance(tripId,mapBound: true);
      Get.find<RiderMapController>().getPickupToDestinationPolyline();
      if (kDebugMode) {
        print('polyline is ====> $polyline');
      }
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }

    update();
    return response;
  }


  List<TripDetail>? ongoingTrip, lastRideDetails;
  List<TripDetail>? get ongoingRideList => ongoingTrip;

  /// True for trips that still occupy the driver (not completed/cancelled). The
  /// all-ride-list API may still return completed rows — those must not block a new on-road trip.
  bool _rideStatusBlocksStartingAnother(String? raw) {
    final String s = (raw ?? '').toLowerCase().trim();
    return s == AppConstants.pending ||
        s == AppConstants.accepted ||
        s == AppConstants.outForPickup ||
        s == 'outforpickup' ||
        s == AppConstants.ongoing ||
        s == AppConstants.findingRider.toLowerCase() ||
        s == 'scheduled';
  }

  bool get hasRegularOngoingRide =>
      ongoingTrip != null &&
      ongoingTrip!.any((TripDetail t) => _rideStatusBlocksStartingAnother(t.currentStatus));

  /// Count for FAB badge: only live rides (excludes stale completed rows in the list).
  int get liveOngoingRideCount {
    if (ongoingTrip == null) {
      return 0;
    }
    return ongoingTrip!
        .where((TripDetail t) => _rideStatusBlocksStartingAnother(t.currentStatus))
        .length;
  }

  String? get firstBlockingOngoingTripId {
    if (ongoingTrip == null) {
      return null;
    }
    for (final TripDetail t in ongoingTrip!) {
      if (_rideStatusBlocksStartingAnother(t.currentStatus)) {
        return t.id;
      }
    }
    return null;
  }

  void _syncOnRoadLocalStateWithTripDetail(String requestedTripId) {
    final TripDetail? d = tripDetail;
    if (d?.id == null || d!.id != requestedTripId) {
      return;
    }
    final String s = (d.currentStatus ?? '').toLowerCase();
    if (s == AppConstants.completed || s == AppConstants.cancelled) {
      final String id = d.id ?? '';
      if (activeOnRoadTrip?['id']?.toString() == id ||
          _onRoadTripRequestId == id) {
        activeOnRoadTrip = null;
        setOnRoadTripMode(false, notify: false);
      }
    }
  }

  /// Opens map for a trip from dashboard / ongoing card; handles on-road vs regular.
  Future<void> openTripMapFromDashboard(String tripId) async {
    final Response value = await getRideDetails(tripId, fromHomeScreen: true);
    if (value.statusCode != 200 || tripDetail == null) {
      return;
    }

    final bool treatAsOnRoad = tripDetail!.isOnRoadBooking ||
        (hasActiveOnRoadTrip &&
            activeOnRoadTrip?['id']?.toString() == tripId);

    if (treatAsOnRoad) {
      setOnRoadTripMode(true, tripRequestId: tripId, notify: false);
      final String status = (tripDetail?.currentStatus ?? '').toLowerCase();
      if (status == AppConstants.ongoing) {
        Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
      } else if (status == AppConstants.outForPickup ||
          status == 'outforpickup') {
        Get.find<RiderMapController>().setRideCurrentState(RideState.outForPickup);
      } else {
        Get.find<RiderMapController>().setRideCurrentState(RideState.accepted);
      }
      Get.find<RiderMapController>().setMarkersInitialPosition();
      await remainingDistance(tripId, mapBound: true);
      updateRoute(false, notify: true);
      Get.to(() => const MapScreen(fromScreen: 'on_road'));
      update();
      return;
    }

    setOnRoadTripMode(false, notify: false);
    if (tripDetail?.currentStatus == AppConstants.accepted ||
        tripDetail?.currentStatus == AppConstants.outForPickup) {
      if (tripDetail?.currentStatus == AppConstants.accepted) {
        Get.find<RiderMapController>().setRideCurrentState(RideState.accepted);
      } else {
        Get.find<RiderMapController>().setRideCurrentState(RideState.outForPickup);
      }
      Get.find<RiderMapController>().setMarkersInitialPosition();
      await remainingDistance(tripId, mapBound: true);
      updateRoute(false, notify: true);
      Get.to(() => const MapScreen(fromScreen: 'splash'));
    } else if (tripDetail?.currentStatus == AppConstants.completed &&
        tripDetail?.paymentStatus == AppConstants.unPaid) {
      final Response finalFareResponse = await getFinalFare(tripId);
      if (finalFareResponse.statusCode == 200) {
        Get.to(() => const PaymentReceivedScreen());
      }
    } else {
      Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
      Get.find<RiderMapController>().setMarkersInitialPosition();
      await remainingDistance(tripId, mapBound: true);
      updateRoute(false, notify: true);
      Get.to(() => const MapScreen(fromScreen: 'splash'));
    }
  }

  Future<Response> ongoingTripList() async {
    Response response = await rideServiceInterface.ongoingTripList();
    if (response.statusCode == 200) {
      ongoingTrip = [];
      if(response.body['data'] != null){
        ongoingTrip!.addAll(OngoingTripModel.fromJson(response.body).data!);
      }

    }else{
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<void> getLastRideDetail() async {
    Response response = await rideServiceInterface.lastRideDetail();
    if (response.statusCode == 200) {
      lastRideDetails = [];
      if(response.body['data'] != null){
        lastRideDetails!.addAll(OngoingTripModel.fromJson(response.body).data!);
      }

    }else{
      ApiChecker.checkApi(response);
    }
    update();
  }

  bool accepting = false;
  String? onPressedTripId ;
  Future<Response> tripAcceptOrRejected(String tripId, String action, String type, String parcelWeight, {bool showSuccess = true}) async {
    onPressedTripId = tripId;

      accepting = true;
      update();
    Response response = await rideServiceInterface.tripAcceptOrReject(tripId, action);
    if (response.statusCode != 200) {
      // Backend variants sometimes expect accept/reject instead of accepted/rejected.
      final String? fallbackAction = action == 'accepted'
          ? 'accept'
          : (action == 'rejected' ? 'reject' : null);
      if (fallbackAction != null) {
        final Response retryResponse = await rideServiceInterface.tripAcceptOrReject(tripId, fallbackAction);
        if (retryResponse.statusCode == 200) {
          response = retryResponse;
        }
      }
    }
    if (response.statusCode == 200) {

      accepting = false;
      Get.find<RiderMapController>().getPickupToDestinationPolyline();
      if(action == 'rejected'){
        await rideServiceInterface.ignoreMessage(tripId);
        showCustomSnackBar('trip_is_rejected'.tr, isError: false);

      }else{
        if(type == 'parcel'){
          totalParcelCount ++;
          totalParcelWeight += double.parse(parcelWeight);
        }

        if(showSuccess){
          showCustomSnackBar('trip_is_accepted'.tr, isError: false);
        }

        Future.delayed(const Duration(seconds: 15)).then((_){
          if((Get.find<SplashController>().config?.maximumParcelRequestAcceptLimitStatus ?? false) && type == 'parcel'){
            if(totalParcelCount ==  Get.find<SplashController>().config?.maximumParcelRequestAcceptLimit){
              showCustomSnackBar(
                  isError: true,
                  'booking_acceptance_limit_reached'.tr,
                  subMessage: 'kindly_complete_the_delivery_of_the_ongoing'.tr,
                  seconds: 5
              );
            }
          }

          if(
          type == 'parcel' &&
              (totalParcelWeight > (Get.find<ProfileController>().profileInfo?.vehicle?.parcelWeightCapacity ?? 0)) &&
              (Get.find<ProfileController>().profileInfo?.vehicle?.parcelWeightCapacity != null)
          ){
            showCustomSnackBar(
                isError: true,
                'parcel_weight_limit_exceeded'.tr,
                subMessage: 'parcel_weight_exceeds_the_set_limit'.tr,
                seconds: 5
            );
          }
        });

        Get.find<OtpTimeCountController>().initialCounter();

      }

    }else{
      final String message = (response.body is Map<String, dynamic> && response.body['message'] != null)
          ? response.body['message'].toString()
          : 'server_error'.tr;
      showCustomSnackBar(message);
      accepting = false;
    }
    accepting = false;
    onPressedTripId = null;
    update();
    return response;
  }


  String _verificationCode = '';
  String _otp = '';
  String get otp => _otp;
  String get verificationCode => _verificationCode;

  void updateVerificationCode(String query) {
    _verificationCode = query;
    if(_verificationCode.isNotEmpty){
      _otp = _verificationCode;
    }
    update();
  }

  void clearVerificationCode() {
    _verificationCode = '';
    update();
  }


  Uint8List? imageFile;

  Future<Response> matchOtp(String tripId, String otp) async {
    isPinVerificationLoading = true;
    update();
    if (kDebugMode) {
      print('otp and id ===> $tripId/$otp');
    }
    Response response = await rideServiceInterface.matchOtp(tripId, otp);
    if (response.statusCode == 200) {

      if(tripDetail?.type != 'parcel'){
        Get.find<SafetyAlertController>().checkDriverNeedSafety();
      }

      clearVerificationCode();
      if(tripDetail!.type! == 'parcel' &&  tripDetail?.parcelInformation?.payer == 'sender'){
        Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
        getFinalFare(tripId).then((value) {
          if(value.statusCode == 200){
            Get.to(()=> const PaymentReceivedScreen(fromParcel: true,));
          }
        });
      }else{
        remainingDistance(tripDetail!.id!,mapBound: true);
        getRideDetails(tripDetail!.id!);
        Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
      }

      if(otp.isEmpty){
        showCustomSnackBar('trip_started'.tr, isError: false);
      }else{
        showCustomSnackBar('otp_verified_successfully'.tr, isError: false);
      }

      isPinVerificationLoading = false;
      Future.delayed(const Duration(seconds: 12)).then((value) async{
        imageFile = await Get.find<RiderMapController>().mapController!.takeSnapshot();
        if(imageFile!= null) {
          uploadScreenShots(tripDetail!.id!, XFile.fromData(imageFile!));
        }
      });

      PusherHelper().tripCancelAfterOngoing(tripDetail!.id!);
      PusherHelper().tripPaymentSuccessful(tripDetail!.id!);

    }else{
      if(otp.isNotEmpty){
        ApiChecker.checkApi(response);
      }
      isPinVerificationLoading = false;
    }
    update();
    return response;
  }



  String myDriveMode = '';
  RemainingDistanceModel? matchedMode;
  List<RemainingDistanceModel>? remainingDistanceItem = [];
  Future<Response> remainingDistance(String tripId,{bool mapBound = false}) async {
    myDriveMode = Get.find<ProfileController>().profileInfo!.vehicle!.category!.type!;
    isLoading = true;
    Response response = await rideServiceInterface.remainDistance(tripId);
     List<String> status = ['accepted','ongoing','outForPickup'];
    if (response.statusCode == 200) {
      isLoading = false;
      if(status.contains(Get.find<RiderMapController>().currentRideState.name)){
        Get.find<RiderMapController>().getDriverToPickupOrDestinationPolyline(response.body[0]['encoded_polyline'],mapBound: mapBound);
      }

      remainingDistanceItem = [];
      response.body.forEach((distance) {
        remainingDistanceItem!.add(RemainingDistanceModel.fromJson(distance));

      });
      if(remainingDistanceItem != null && remainingDistanceItem!.isNotEmpty){
        matchedMode =  remainingDistanceItem![0];
      }

      if(matchedMode != null && (matchedMode!.distance! * 1000) <= 100 && tripDetail != null && tripDetail!.currentStatus == 'pending' ){
        arrivalPickupPoint(tripId);
      }

      if(tripDetail != null && tripDetail!.currentStatus == 'ongoing' && !tripDetail!.isPaused! && matchedMode != null &&  Get.find<RiderMapController>().isInside && matchedMode!.isPicked!){
        arrivalDestination(tripId, "destination");
        getRideDetails(tripId);
        AudioPlayer audio = AudioPlayer();
        audio.play(AssetSource('notification.wav'));

      }

    }else{
      isLoading = false;
    }
    update();
    return response;
  }

  bool isStatusUpdating = false;
  bool isOnRoadActionLoading = false;
  String onRoadActionType = '';
  Map<String, dynamic>? activeOnRoadTrip;
  Map<String, dynamic>? lastCompletedOnRoadTrip;
  bool _isOnRoadTripMode = false;
  String? _onRoadTripRequestId;

  bool get isOnRoadTripMode => _isOnRoadTripMode;
  String? get onRoadTripRequestId => _onRoadTripRequestId;

  bool get hasActiveOnRoadTrip {
    if (activeOnRoadTrip == null) return false;
    final String status = (activeOnRoadTrip?['status'] ?? '').toString().toLowerCase();
    return status != 'completed' && status != 'cancelled';
  }

  void setOnRoadTripMode(bool value, {String? tripRequestId, bool notify = true}) {
    _isOnRoadTripMode = value;
    _onRoadTripRequestId = value ? tripRequestId : null;
    if (notify) {
      update();
    }
  }

  Future<bool> prepareOnRoadTripForRideUi({String? tripRequestId}) async {
    String? id = tripRequestId ?? activeOnRoadTrip?['id']?.toString();
    if (id == null || id.isEmpty) {
      await fetchActiveOnRoadTrip();
      id = activeOnRoadTrip?['id']?.toString();
    }
    if (id == null || id.isEmpty) {
      return false;
    }

    final Response detailsResponse = await getRideDetails(id, fromHomeScreen: true);
    if (detailsResponse.statusCode != 200 || tripDetail == null) {
      return false;
    }

    final String detailStatus = (tripDetail?.currentStatus ?? '').toLowerCase();
    if (detailStatus == AppConstants.completed || detailStatus == AppConstants.cancelled) {
      activeOnRoadTrip = null;
      setOnRoadTripMode(false, notify: false);
      update();
      return false;
    }

    setOnRoadTripMode(true, tripRequestId: id, notify: false);
    final String status = (tripDetail?.currentStatus ?? '').toLowerCase();
    if (status == 'ongoing') {
      Get.find<RiderMapController>().setRideCurrentState(RideState.ongoing);
    } else if (status == 'out_for_pickup' || status == 'outforpickup') {
      Get.find<RiderMapController>().setRideCurrentState(RideState.outForPickup);
    } else {
      Get.find<RiderMapController>().setRideCurrentState(RideState.accepted);
    }
    update();
    return true;
  }

  Future<Response> tripStatusUpdate(String status,String id, String message, String cancellationCause,{String? dateTime}) async {
    isLoading = true;
    isStatusUpdating = true;
    update();
    Response response = await rideServiceInterface.tripStatusUpdate(status, id,cancellationCause,dateTime ?? '');

    if (response.statusCode == 200) {
      Get.find<TripController>().othersCancellationController.clear();
      Get.find<SafetyAlertController>().cancelDriverNeedSafetyStream();
      showCustomSnackBar(message.tr, isError: false);
      isLoading = false;
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isStatusUpdating = false;
    update();
    return response;
  }

  Future<Response?> startOnRoadTrip({
    required List<String> passengerPhones,
    int familyCount = 1,
    List<int>? passengerPartySizes,
    double? baseFare,
    double? farePerKm,
    double? startLatitude,
    double? startLongitude,
  }) async {
    isOnRoadActionLoading = true;
    onRoadActionType = 'start';
    update();

    Response response = await rideServiceInterface.startOnRoadTrip(
      passengerPhones,
      familyCount: familyCount,
      passengerPartySizes: passengerPartySizes,
      baseFare: baseFare,
      farePerKm: farePerKm,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
    );

    if(response.statusCode == 200) {
      if (response.body is Map<String, dynamic>) {
        final dynamic trip = response.body['data'];
        if (trip is Map<String, dynamic>) {
          activeOnRoadTrip = trip;
          setOnRoadTripMode(true, tripRequestId: trip['id']?.toString(), notify: false);
        }
      }
      showCustomSnackBar('trip_status_updated_successfully'.tr, isError: false);
    } else {
      ApiChecker.checkApi(response);
    }

    isOnRoadActionLoading = false;
    onRoadActionType = '';
    update();
    return response;
  }

  Future<Response?> finishOnRoadTrip({
    bool cancelled = false,
    double? distanceKm,
    double? idleFee,
    double? delayFee,
  }) async {
    isOnRoadActionLoading = true;
    onRoadActionType = 'finish';
    update();

    String? activeOnRoadTripId = activeOnRoadTrip?['id']?.toString();
    String? activeOnRoadTripRefId = activeOnRoadTrip?['ref_id']?.toString();
    Response listResponse = await rideServiceInterface.getOnRoadTripList(limit: 20, offset: 1);
    if(listResponse.statusCode == 200) {
      final List<dynamic> trips = (listResponse.body is Map<String, dynamic> && listResponse.body['data'] is List)
          ? listResponse.body['data']
          : <dynamic>[];
      for(final dynamic trip in trips) {
        if(trip is Map<String, dynamic>) {
          final String status = (trip['status'] ?? '').toString().toLowerCase();
          final String bookingSource = (trip['booking_source'] ?? '').toString().toLowerCase();
          if(bookingSource == 'on_road' && status != 'completed' && status != 'cancelled' && trip['id'] != null) {
            activeOnRoadTripId = trip['id'].toString();
            activeOnRoadTripRefId = trip['ref_id']?.toString();
            activeOnRoadTrip = trip;
            break;
          }
        }
      }
    } else {
      isOnRoadActionLoading = false;
      onRoadActionType = '';
      update();
      ApiChecker.checkApi(listResponse);
      return null;
    }

    if(activeOnRoadTripId == null) {
      isOnRoadActionLoading = false;
      onRoadActionType = '';
      update();
      showCustomSnackBar('no_trip_available'.tr);
      return null;
    }

    Response response = await rideServiceInterface.finishOnRoadTrip(
      activeOnRoadTripId,
      cancelled: cancelled,
      distanceKm: distanceKm,
      idleFee: idleFee,
      delayFee: delayFee,
    );
    if(response.statusCode == 200) {
      if (cancelled) {
        activeOnRoadTrip = null;
        setOnRoadTripMode(false, notify: false);
        showCustomSnackBar('trip_is_rejected'.tr, isError: false);
        try {
          final TripController tripController = Get.find<TripController>();
          await tripController.getTripList(
              1,
              '',
              '',
              'ride_request',
              tripController.selectedFilterTypeName,
              tripController.selectedStatusName);
        } catch (_) {}
        isOnRoadActionLoading = false;
        onRoadActionType = '';
        update();
        return response;
      }
      await getRideDetails(activeOnRoadTripId, fromHomeScreen: true);
      if (tripDetail != null && tripDetail!.id == activeOnRoadTripId) {
        lastCompletedOnRoadTrip = <String, dynamic>{
          'id': tripDetail!.id,
          'ref_id': tripDetail!.refId ?? activeOnRoadTripRefId,
          'distance_km': tripDetail!.actualDistance,
          'total_fare': tripDetail!.paidFare,
          'status': 'completed',
          'booking_source': 'on_road',
        };
      } else if (response.body is Map<String, dynamic>) {
        final dynamic trip = response.body['data'];
        if (trip is Map<String, dynamic>) {
          lastCompletedOnRoadTrip = trip;
        }
      }
      activeOnRoadTrip = null;
      setOnRoadTripMode(false, notify: false);
      try {
        final TripController tripController = Get.find<TripController>();
        await tripController.getTripList(
            1,
            '',
            '',
            'ride_request',
            tripController.selectedFilterTypeName,
            tripController.selectedStatusName);
      } catch (_) {}

      Get.find<RiderMapController>().setRideCurrentState(RideState.initial);
      await getFinalFare(activeOnRoadTripId, showApiError: false);
      if (finalFare == null &&
          tripDetail != null &&
          tripDetail!.id == activeOnRoadTripId) {
        finalFare = FinalFare.fromTripDetail(tripDetail!);
      }
      if (finalFare != null) {
        showCustomSnackBar('trip_completed_successfully'.tr, isError: false);
        Get.off(() => const PaymentReceivedScreen());
      } else {
        showCustomSnackBar('trip_completed_successfully'.tr, isError: false);
        Get.offAll(() => const DashboardScreen());
      }
    } else {
      ApiChecker.checkApi(response);
    }

    isOnRoadActionLoading = false;
    onRoadActionType = '';
    update();
    return response;
  }

  /// Resolves [activeOnRoadTrip] via GET /api/driver/ride/on-road/active-trip-request when available;
  /// falls back to scanning [getOnRoadTripList] if the dedicated endpoint is missing or errors.
  Future<void> fetchActiveOnRoadTrip() async {
    try {
      final Response activeResponse = await rideServiceInterface
          .getOnRoadActiveTripRequest()
          .timeout(const Duration(seconds: 8));
      if (activeResponse.statusCode == 200 && activeResponse.body is Map<String, dynamic>) {
        final Map<String, dynamic> body =
            activeResponse.body as Map<String, dynamic>;
        final dynamic data = body['data'];
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          final String status = (data['status'] ?? '').toString().toLowerCase();
          final String bookingSource =
              (data['booking_source'] ?? '').toString().toLowerCase();
          if (bookingSource == 'on_road' &&
              status != 'completed' &&
              status != 'cancelled') {
            activeOnRoadTrip = data;
            update();
            return;
          }
        }
        activeOnRoadTrip = null;
        setOnRoadTripMode(false, notify: false);
        update();
        return;
      }
    } catch (_) {
      // Fall through to list-based discovery.
    }
    await _fetchActiveOnRoadTripFromRideListFallback();
  }

  Future<void> _fetchActiveOnRoadTripFromRideListFallback() async {
    try {
      final Response listResponse = await rideServiceInterface
          .getOnRoadTripList(limit: 20, offset: 1)
          .timeout(const Duration(seconds: 8));
      if (listResponse.statusCode == 200) {
        final List<dynamic> trips =
            (listResponse.body is Map<String, dynamic> &&
                    listResponse.body['data'] is List)
                ? listResponse.body['data']
                : <dynamic>[];
        Map<String, dynamic>? active;
        for (final dynamic trip in trips) {
          if (trip is Map<String, dynamic>) {
            final String status =
                (trip['status'] ?? '').toString().toLowerCase();
            final String bookingSource =
                (trip['booking_source'] ?? '').toString().toLowerCase();
            if (bookingSource == 'on_road' &&
                status != 'completed' &&
                status != 'cancelled') {
              active = trip;
              break;
            }
          }
        }
        activeOnRoadTrip = active;
        if (active == null) {
          setOnRoadTripMode(false, notify: false);
        }
        update();
      }
    } catch (_) {
      // Keep home usable even if on-road endpoints are slow/down.
    }
  }


  PendingRideRequestModel? pendingRideRequestModel;
  PendingRideRequestModel? get getPendingRideRequestModel => pendingRideRequestModel;

  Future<Response> getPendingRideRequestList(int offset, {int limit = 10, bool isUpdate = false}) async {
    isLoading = true;
    if(isUpdate){
      update();
    }
    Response response = await rideServiceInterface.getPendingRideRequestList(offset, limit: limit);
    if (response.statusCode == 200) {
      pendingRideRequestModel?.data = [];
      pendingRideRequestModel?.totalSize = 0;
      pendingRideRequestModel?.offset = '1';
      if(response.body['data'] != null && response.body['data'] != ''){
        if(offset == 1 ){
          pendingRideRequestModel = PendingRideRequestModel.fromJson(response.body);
        }else{
          pendingRideRequestModel!.totalSize =  PendingRideRequestModel.fromJson(response.body).totalSize;
          pendingRideRequestModel!.offset =  PendingRideRequestModel.fromJson(response.body).offset;
          pendingRideRequestModel!.data!.addAll(PendingRideRequestModel.fromJson(response.body).data!);
        }
      }

      isLoading = false;
    }
    else{
      pendingRideRequestModel?.data = [];
      pendingRideRequestModel?.totalSize = 0;
      pendingRideRequestModel?.offset = '1';
      isLoading = false;
      if(!(Get.find<ProfileController>().profileInfo?.vehicle == null  && Get.find<ProfileController>().isFirstTimeShowBottomSheet)){
       // ApiChecker.checkApi(response);
      }
    }
    update();
    return response;
  }


  FinalFare? finalFare;
  Future<Response> getFinalFare(String tripId, {bool showApiError = true}) async {
    isLoading = true;
    update();
    Response response = await rideServiceInterface.getFinalFare(tripId);
    if (response.statusCode == 200 ) {
      Get.find<RiderMapController>().initializeData();
      try {
        if (response.body['data'] != null) {
          finalFare = FinalFareModel.fromJson(response.body).data;
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('getFinalFare parse error: $e\n$st');
        }
        finalFare = null;
      }
      isLoading = false;
    }else{
      isLoading = false;
      if (showApiError) {
        ApiChecker.checkApi(response);
      }
    }
    update();
    return response;
  }

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-d');
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  DateFormat get dateFormat => _dateFormat;

  void selectDate(String type, BuildContext context){
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),

      lastDate: DateTime(2030),
    ).then((date) {
      if (type == 'start'){
        _startDate = date!;
      }else{
        _endDate = date!;
      }

      update();
    });
  }



  Future<Response> arrivalPickupPoint(String tripId) async {
    isLoading = true;
    if (kDebugMode) {
      print('details api call-====> $tripId');
    }
    Response response = await rideServiceInterface.arrivalPickupPoint(tripId);
    if (response.statusCode == 200) {
      isLoading = false;
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<Response> arrivalDestination(String tripId, String type) async {
    Response response = await rideServiceInterface.arrivalDestination(tripId, type);
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("===Arrived destination aria===");
      }
    }else{

      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<Response> waitingForCustomer (String tripId, String waitingStatus) async {
    isLoading = true;
    Response response = await rideServiceInterface.waitingForCustomer(tripId, waitingStatus);
    if (response.statusCode == 200) {
      getRideDetails(tripId);
      isLoading = false;
      showCustomSnackBar('trip_status_updated_successfully'.tr, isError: false);
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<void> focusOnBottomSheet(GlobalKey<ExpandableBottomSheetState> key) async {
    if(key.currentState?.expansionStatus == ExpansionStatus.expanded) {
      // ignore: invalid_use_of_protected_member
      key.currentState?.reassemble();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    key.currentState?.expand();
  }

  ParcelListModel? parcelListModel;
  Future<Response> getOngoingParcelList() async {
    isLoading = true;
    Response? response = await rideServiceInterface.getOnGoingParcelList(1);
    if(response!.statusCode == 200 ){
      isLoading = false;
      if(response.body['data'] != null){
        parcelListModel = ParcelListModel.fromJson(response.body);
      }
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    _calculateTotalParcelWeight();
    return response;
  }

  void _calculateTotalParcelWeight(){
    totalParcelWeight = 0;
    totalParcelCount = 0;
    if(parcelListModel != null){
      totalParcelCount = parcelListModel!.data!.length;
      for(int i = 0 ; i< parcelListModel!.data!.length ; i++){
        totalParcelWeight += double.parse(parcelListModel?.data?[i].parcelInformation?.weight ?? '0');
      }
    }
  }

  ParcelListModel? unpaidParcelListModel;
  Future<Response> getUnpaidParcelList() async {
    isLoading = true;
    Response? response = await rideServiceInterface.getUnpaidParcelList(1);
    if(response!.statusCode == 200 ){
      isLoading = false;
      if(response.body['data'] != null){
        unpaidParcelListModel = ParcelListModel.fromJson(response.body);
      }
    }else{
      isLoading = false;
      ApiChecker.checkApi(response);
    }
    isLoading = false;
    update();
    return response;
  }

  Future<String?> generateThumbnail(String filePath) async {
    final directory = await getTemporaryDirectory();

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: filePath, // Replace with your video URL
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.PNG,  // You can use JPEG or WEBP too
      maxHeight: 100,                 // Specify the height of the thumbnail
      maxWidth: 200,                 // Specify the Width of the thumbnail
      quality: 1,                    // Quality of the thumbnail
    );

    return thumbnailPath;
  }

  String loadingId = '';
  Future<Response> checkDriverReachedDestination(String tripId) async {
    isLoading = true;
    loadingId = tripId;
    update();
    Response response = await rideServiceInterface.remainDistance(tripId);
    if (response.statusCode == 200) {
      getRideDetails(tripId);
      isLoading = false;
      Get.find<RiderMapController>().checkDriverReachedDestination(response.body[0]['encoded_polyline']);

      remainingDistanceItem = [];
      response.body.forEach((distance) {
        remainingDistanceItem!.add(RemainingDistanceModel.fromJson(distance));
      });

      if(remainingDistanceItem != null && remainingDistanceItem!.isNotEmpty){
        matchedMode =  remainingDistanceItem![0];
      }

    }else{
      isLoading = false;
    }
    update();
    return response;
  }

  void showSafetyAlertTooltip(){
    justTheController.showTooltip();
  }

  Future<Response> startForPickup(String tripId) async {
    isPinVerificationLoading = true;
    update();

    Response response = await rideServiceInterface.startForPickup(tripId);
    if (response.statusCode == 200) {
        getRideDetails(tripDetail!.id!);
        Get.find<RiderMapController>().setRideCurrentState(RideState.outForPickup);

      // if(otp.isEmpty){
      //   showCustomSnackBar('trip_started'.tr, isError: false);
      // }else{
      //   showCustomSnackBar('otp_verified_successfully'.tr, isError: false);
      // }

      isPinVerificationLoading = false;

    }else{
      isPinVerificationLoading = false;
    }
    update();
    return response;
  }

}