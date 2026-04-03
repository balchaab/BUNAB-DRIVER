
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/features/ride/domain/repositories/ride_repository_interface.dart';
import 'package:ride_sharing_user_app/features/ride/domain/services/ride_service_interface.dart';

class RideService implements RideServiceInterface{
  final RideRepositoryInterface rideRepositoryInterface;
  RideService({required this.rideRepositoryInterface});

  @override
  Future arrivalDestination(String tripId, String destination) {
   return rideRepositoryInterface.arrivalDestination(tripId, destination);
  }

  @override
  Future arrivalPickupPoint(String tripId) {
   return rideRepositoryInterface.arrivalPickupPoint(tripId);
  }

  @override
  Future bidding(String tripId, String amount) {
    return rideRepositoryInterface.bidding(tripId, amount);
  }

  @override
  Future getFinalFare(String tripId) {
    return rideRepositoryInterface.getFinalFare(tripId);
  }

  @override
  Future getOnGoingParcelList(int offset) {
    return rideRepositoryInterface.getOnGoingParcelList(offset);
  }

  @override
  Future getPendingRideRequestList(int offset,{int limit = 10}) {
    return rideRepositoryInterface.getPendingRideRequestList(offset, limit: limit);
  }

  @override
  Future getRideDetailBeforeAccept(String tripId) {
    return rideRepositoryInterface.getRideDetailBeforeAccept(tripId);
  }

  @override
  Future getRideDetails(String tripId) {
    return rideRepositoryInterface.getRideDetails(tripId);
  }

  @override
  Future getUnpaidParcelList(int offset) {
    return rideRepositoryInterface.getUnpaidParcelList(offset);
  }

  @override
  Future ignoreMessage(String tripId) {
    return rideRepositoryInterface.ignoreMessage(tripId);
  }

  @override
  Future matchOtp(String tripId, String otp) {
    return rideRepositoryInterface.matchOtp(tripId, otp);
  }

  @override
  Future startForPickup(String tripId) {
    return rideRepositoryInterface.startForPickup(tripId);
  }

  @override
  Future ongoingTripList() {
   return rideRepositoryInterface.ongoingTripList();
  }

  @override
  Future lastRideDetail() {
   return rideRepositoryInterface.lastRideDetail();
  }

  @override
  Future remainDistance(String id) {
    return rideRepositoryInterface.remainDistance(id);
  }

  @override
  Future tripAcceptOrReject(String tripId, String action) {
   return rideRepositoryInterface.tripAcceptOrReject(tripId, action);
  }

  @override
  Future tripStatusUpdate(String status, String id, String cancellationCause, String dateTime) async {
    // Repository expects (trip_request_id, status, ...); controller passes (status, id, ...).
    return await rideRepositoryInterface.tripStatusUpdate(
        id, status, cancellationCause, dateTime);
  }

  @override
  Future uploadScreenShots(String id, XFile? file) {
    return rideRepositoryInterface.uploadScreenShots(id, file);
  }

  @override
  Future waitingForCustomer(String tripId, String status) {
    return rideRepositoryInterface.waitingForCustomer(tripId, status);
  }

  @override
  Future startOnRoadTrip(
    List<String> passengerPhones, {
    int familyCount = 1,
    List<int>? passengerPartySizes,
    double? baseFare,
    double? farePerKm,
    double? startLatitude,
    double? startLongitude,
  }) {
    return rideRepositoryInterface.startOnRoadTrip(
      passengerPhones,
      familyCount: familyCount,
      passengerPartySizes: passengerPartySizes,
      baseFare: baseFare,
      farePerKm: farePerKm,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
    );
  }

  @override
  Future finishOnRoadTrip(
    String id, {
    bool cancelled = false,
    double? distanceKm,
    double? idleFee,
    double? delayFee,
  }) {
    return rideRepositoryInterface.finishOnRoadTrip(
      id,
      cancelled: cancelled,
      distanceKm: distanceKm,
      idleFee: idleFee,
      delayFee: delayFee,
    );
  }

  @override
  Future getOnRoadTripList({int limit = 20, int offset = 1}) {
    return rideRepositoryInterface.getOnRoadTripList(limit: limit, offset: offset);
  }

  @override
  Future getOnRoadActiveTripRequest() {
    return rideRepositoryInterface.getOnRoadActiveTripRequest();
  }

}