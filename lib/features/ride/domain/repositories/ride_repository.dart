import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/features/ride/domain/repositories/ride_repository_interface.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';

class RideRepository implements RideRepositoryInterface{
  ApiClient apiClient;
  RideRepository({required this.apiClient});


  @override
  Future<Response> bidding(String tripId, String amount) async {
    return await apiClient.postData(AppConstants.bidding,{
      "trip_request_id" : tripId,
      "bid_fare" : amount
    });
  }


  @override
  Future<Response> getRideDetails(String tripId) async {
    return await apiClient.getData('${AppConstants.tripDetails}$tripId');
  }

  @override
  Future<Response> uploadScreenShots(String id, XFile? file) async {
    Map<String, String> fields = {};
    fields.addAll(<String, String>{
      'trip_request_id': id
    });

    return await apiClient.postMultipartData(AppConstants.uploadScreenShots,
      fields,
      [],
        MultipartBody('file', file),
      []
    );
  }

  @override
  Future<Response> getRideDetailBeforeAccept(String tripId) async {
    return await apiClient.getData('${AppConstants.tripDetails}$tripId?type=overview');
  }

  @override
  Future<Response> tripAcceptOrReject(String tripId, String action) async {
    return await apiClient.postData(AppConstants.tripAcceptOrReject,{
      "trip_request_id": tripId,
      "action" : action
    });
  }

  @override
  Future<Response> ignoreMessage(String tripId) async {
    return await apiClient.postData(AppConstants.tripAcceptOrReject,{
      "trip_request_id": tripId
    });
  }

  @override
  Future<Response> matchOtp(String tripId, String otp) async {
    return await apiClient.postData(AppConstants.matchOtp,{
      "trip_request_id": tripId,
      "otp" : otp
    });
  }

  @override
  Future<Response> startForPickup(String tripId) async {
    return await apiClient.putData("${AppConstants.outForPickupUri}$tripId",{});
  }

  @override
  Future<Response> remainDistance(String id) async {
    return await apiClient.postData(AppConstants.remainDistance,
    {
      "trip_request_id": id,
    });
  }

  @override
  Future<Response> tripStatusUpdate(String id, String status, String cancellationCause, String dateTime) async {
    return await apiClient.postData(AppConstants.tripStatusUpdate,
        {
          "status": status,
          "cancel_reason": cancellationCause,
          "trip_request_id" : id,
          "_method" : 'put',
          "return_time" : dateTime
        });
  }

  @override
  Future<Response> getPendingRideRequestList(int offset, {int limit = 10}) async {
    return await apiClient.getData('${AppConstants.rideRequestList}?limit=$limit&offset=$offset');
  }

  @override
  Future<Response> ongoingTripList() async {
    return await apiClient.getData(AppConstants.ongoingRideList);
  }

  @override
  Future<Response> lastRideDetail() async {
    return await apiClient.getData(AppConstants.lastRideDetails);
  }

  @override
  Future<Response> getFinalFare(String tripId) async {
    return await apiClient.getData('${AppConstants.finalFare}?trip_request_id=$tripId');
  }


  @override
  Future<Response> arrivalPickupPoint(String tripId) async {
    return await apiClient.postData(AppConstants.arrivalPickupPoint,
        {
          "trip_request_id" : tripId,
          "_method" : "put"
        });
  }

  @override
  Future<Response> arrivalDestination(String tripId, String destination) async {
    return await apiClient.postData(AppConstants.arrivedDestination,
        {
          "trip_request_id" : tripId,
          "is_reached": destination,
          "_method" : "put"
        });
  }

  @override
  Future<Response> waitingForCustomer (String tripId, String status) async {
    return await apiClient.postData(AppConstants.waitingUri,
        {
          "waiting_status": status,
          "trip_request_id" : tripId,
          "_method" : "put"
        });
  }

  @override
  Future<Response> getOnGoingParcelList(int offset) async {
    return await apiClient.getData(AppConstants.parcelOngoingList);
  }

  @override
  Future<Response> getUnpaidParcelList(int offset) async {
    return await apiClient.getData(AppConstants.parcelUnpaidList);
  }

  /// Many backends expect Ethiopian local format `0[79]XXXXXXXX`, not `251...`.
  static String _ethiopianLocalPhone(String raw) {
    String d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('251')) {
      d = d.substring(3);
    }
    while (d.startsWith('0')) {
      d = d.substring(1);
    }
    if (d.length == 9 && (d[0] == '7' || d[0] == '9')) {
      return '0$d';
    }
    return raw.trim();
  }

  @override
  Future<Response> startOnRoadTrip(
    List<String> passengerPhones, {
    int familyCount = 1,
    List<int>? passengerPartySizes,
    double? baseFare,
    double? farePerKm,
    double? startLatitude,
    double? startLongitude,
  }) async {
    if (passengerPhones.isEmpty) {
      return Response(statusCode: 400, statusText: 'customer_phone is required');
    }

    final Map<String, dynamic> body = {
      "customer_phone": _ethiopianLocalPhone(passengerPhones.first),
    };
    if (familyCount > 1) {
      body["note"] = 'Passengers: $familyCount';
    }
    if (baseFare != null) {
      body["estimated_fare"] = baseFare;
    }
    if (startLatitude != null && startLongitude != null) {
      final String locNote = 'GPS: $startLatitude,$startLongitude';
      body["note"] = ((body["note"] ?? '') as String).trim().isEmpty
          ? locNote
          : '${body["note"]}; $locNote';
    }
    if (passengerPhones.length > 1) {
      final String extras = passengerPhones.skip(1).map(_ethiopianLocalPhone).join(', ');
      body["note"] = ((body["note"] ?? '') as String).trim().isEmpty
          ? 'Additional phones: $extras'
          : '${body["note"]}; Additional phones: $extras';
    }
    if (passengerPartySizes != null && passengerPartySizes.isNotEmpty) {
      final String party = passengerPartySizes.join(',');
      body["note"] = ((body["note"] ?? '') as String).trim().isEmpty
          ? 'Party sizes: $party'
          : '${body["note"]}; Party sizes: $party';
    }
    return await apiClient.postData(AppConstants.startOnRoadTrip, body);
  }

  @override
  Future<Response> finishOnRoadTrip(
    String id, {
    bool cancelled = false,
    double? distanceKm,
    double? idleFee,
    double? delayFee,
  }) async {
    // Match tripStatusUpdate: POST with Laravel method spoof (same as normal cancel/complete).
    final Map<String, dynamic> body = {
      'trip_request_id': id,
      'status': cancelled ? 'cancelled' : 'completed',
      '_method': 'put',
      'return_time': '',
    };
    if (cancelled) {
      body['cancel_reason'] = 'driver_cancelled';
    }
    if (!cancelled) {
      if (distanceKm != null) {
        body['distance_km'] = distanceKm;
      }
      if (idleFee != null) {
        body['idle_fee'] = idleFee;
      }
      if (delayFee != null) {
        body['delay_fee'] = delayFee;
      }
    }
    return await apiClient.postData(AppConstants.tripStatusUpdate, body);
  }

  @override
  Future<Response> getOnRoadTripList({int limit = 20, int offset = 1}) async {
    return await apiClient.getData('${AppConstants.onRoadTripList}?limit=$limit&offset=$offset');
  }

  @override
  Future<Response> getOnRoadActiveTripRequest() async {
    return await apiClient.getData(AppConstants.onRoadActiveTripRequest);
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }

}