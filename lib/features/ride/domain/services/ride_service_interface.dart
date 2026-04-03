

import 'package:image_picker/image_picker.dart';

abstract class RideServiceInterface {
  Future<dynamic> bidding(String tripId, String amount);
  Future<dynamic> getRideDetails(String tripId);
  Future<dynamic> uploadScreenShots(String id, XFile? file);
  Future<dynamic> getRideDetailBeforeAccept(String tripId);
  Future<dynamic> tripAcceptOrReject(String tripId, String action);
  Future<dynamic> ignoreMessage(String tripId);
  Future<dynamic> matchOtp(String tripId, String otp);
  Future<dynamic> startForPickup(String tripId);
  Future<dynamic> remainDistance(String id);
  Future<dynamic> tripStatusUpdate(String status, String id,String cancellationCause,String dateTime);
  Future<dynamic> getPendingRideRequestList(int offset, {int limit = 10});
  Future<dynamic> ongoingTripList();
  Future<dynamic> lastRideDetail();
  Future<dynamic> getFinalFare(String tripId);
  Future<dynamic> arrivalPickupPoint(String tripId);
  Future<dynamic> arrivalDestination(String tripId, String destination);
  Future<dynamic> waitingForCustomer (String tripId, String status);
  Future<dynamic> getOnGoingParcelList(int offset);
  Future<dynamic> getUnpaidParcelList(int offset);
  Future<dynamic> startOnRoadTrip(
    List<String> passengerPhones, {
    int familyCount = 1,
    List<int>? passengerPartySizes,
    double? baseFare,
    double? farePerKm,
    double? startLatitude,
    double? startLongitude,
  });
  Future<dynamic> finishOnRoadTrip(
    String id, {
    bool cancelled = false,
    double? distanceKm,
    double? idleFee,
    double? delayFee,
  });
  Future<dynamic> getOnRoadTripList({int limit = 20, int offset = 1});
  Future<dynamic> getOnRoadActiveTripRequest();
}