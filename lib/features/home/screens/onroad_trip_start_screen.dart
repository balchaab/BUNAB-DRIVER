import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/features/map/screens/map_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class OnRoadTripStartScreen extends StatefulWidget {
  const OnRoadTripStartScreen({super.key});

  @override
  State<OnRoadTripStartScreen> createState() => _OnRoadTripStartScreenState();
}

class _OnRoadTripStartScreenState extends State<OnRoadTripStartScreen> {
  static const double _cardRadius = 18;
  static const int _maxCarPassengers = 4;

  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  final List<int> _partySizes = [1];
  final TextEditingController _addressController = TextEditingController();

  bool _locationLoading = true;
  double? _startLatitude;
  double? _startLongitude;

  bool get _hasDriverLocation => _startLatitude != null && _startLongitude != null;

  @override
  void initState() {
    super.initState();
    _loadDriverLocation();
  }

  @override
  void dispose() {
    for (final c in _phoneControllers) {
      c.dispose();
    }
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverLocation() async {
    setState(() => _locationLoading = true);
    final LocationController lc = Get.find<LocationController>();
    final LatLng? latLng = await lc.getCurrentPosition();
    if (!mounted) return;

    if (latLng == null) {
      setState(() {
        _locationLoading = false;
        _addressController.text = '';
      });
      return;
    }

    _startLatitude = latLng.latitude;
    _startLongitude = latLng.longitude;
    setState(() {
      _locationLoading = false;
      _addressController.text = 'your_current_location'.tr;
    });
  }

  static String? normalizeEthiopianMobile(String raw) {
    String d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('251')) {
      d = d.substring(3);
    }
    while (d.startsWith('0')) {
      d = d.substring(1);
    }
    if (d.length != 9) return null;
    if (d[0] != '7' && d[0] != '9') return null;
    if (!RegExp(r'^[79]\d{8}$').hasMatch(d)) return null;
    return d;
  }

  Widget _ethiopiaPhonePrefix(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇪🇹', style: TextStyle(fontSize: 22, height: 1.1)),
          const SizedBox(width: 6),
          Text(
            '251',
            style: textMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  int _sumPartySizes() => _partySizes.fold(0, (a, b) => a + b);

  int _maxPartyForIndex(int index) {
    final int others = _sumPartySizes() - _partySizes[index];
    return (4 - others).clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color cardBg = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : const Color(0xFFF2F2F4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'where_do_you_want_to_go'.tr,
          style: textBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
          textAlign: TextAlign.center,
        ),
      ),
      body: _locationLoading
          ? _buildLocationLoadingBody(primary)
          : !_hasDriverLocation
              ? _buildLocationFailedBody(context, primary)
              : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(_cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLocationField(context, primary),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                    ),
                  ),
                  ...List.generate(_phoneControllers.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _phoneControllers.length - 1 ? 12 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _ethiopiaPhonePrefix(context),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneControllers[index],
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      _EthiopianNationalPhoneFormatter(),
                                    ],
                                    style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                                      hintText: 'phone_no'.tr,
                                      hintStyle: textRegular.copyWith(
                                        color: Theme.of(context).hintColor,
                                        fontSize: Dimensions.fontSizeLarge,
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: _phoneControllers.length > 1
                                          ? IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                              onPressed: () {
                                                final c = _phoneControllers.removeAt(index);
                                                c.dispose();
                                                _partySizes.removeAt(index);
                                                setState(() {});
                                              },
                                              icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildFamilyMemberTrigger(context, index),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_phoneControllers.length >= 4) {
                      showCustomSnackBar('Maximum 4 phones allowed');
                      return;
                    }
                    if (_sumPartySizes() + 1 > _maxCarPassengers) {
                      showCustomSnackBar('cannot_add_more_phones'.tr);
                      return;
                    }
                    setState(() {
                      _phoneControllers.add(TextEditingController());
                      _partySizes.add(1);
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'add_a_phone'.tr,
                          style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                8,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
              ),
              child: GetBuilder<RideController>(builder: (rideController) {
                final bool loading =
                    rideController.isOnRoadActionLoading && rideController.onRoadActionType == 'start';
                final bool canStart = !loading && _hasDriverLocation;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: canStart ? _onStartTripPressed : null,
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'start_trip'.tr,
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLoadingBody(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              'loading_location'.tr,
              textAlign: TextAlign.center,
              style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFailedBody(BuildContext context, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 56, color: Theme.of(context).hintColor),
            const SizedBox(height: 16),
            Text(
              'location_unavailable'.tr,
              textAlign: TextAlign.center,
              style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _locationLoading ? null : () => _loadDriverLocation(),
                child: Text('retry'.tr, style: textBold.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(BuildContext context, Color primary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _locationLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                      ),
                      const SizedBox(width: 10),
                      Text('loading_location'.tr, style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    ],
                  ),
                )
              : TextField(
                  controller: _addressController,
                  readOnly: true,
                  maxLines: 3,
                  minLines: 1,
                  style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'your_location'.tr,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFamilyMemberTrigger(BuildContext context, int phoneIndex) {
    final Color error = Theme.of(context).colorScheme.error;
    final int count = _partySizes[phoneIndex];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPartySizeBottomSheet(phoneIndex),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 4,
                child: Icon(Icons.person, size: 28, color: Theme.of(context).colorScheme.onSurface),
              ),
              Positioned(
                top: 2,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: error,
                    border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: textBold.copyWith(color: Colors.white, fontSize: 10, height: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onStartTripPressed() async {
    if (_startLatitude == null || _startLongitude == null) {
      showCustomSnackBar('location_unavailable'.tr);
      return;
    }

    final List<String> normalized = [];
    for (final controller in _phoneControllers) {
      final String? national = normalizeEthiopianMobile(controller.text);
      if (national == null) {
        showCustomSnackBar('ethiopian_phone_invalid'.tr);
        return;
      }
      normalized.add('251$national');
    }

    final int totalPassengers = _sumPartySizes();
    if (totalPassengers < 1 || totalPassengers > _maxCarPassengers) {
      showCustomSnackBar('passenger_capacity_exceeded'.tr);
      return;
    }
    for (final p in _partySizes) {
      if (p < 1 || p > 4) {
        showCustomSnackBar('passenger_capacity_exceeded'.tr);
        return;
      }
    }

    final RideController rideController = Get.find<RideController>();
    final response = await rideController.startOnRoadTrip(
      passengerPhones: normalized,
      familyCount: totalPassengers,
      passengerPartySizes: List<int>.from(_partySizes),
      startLatitude: _startLatitude,
      startLongitude: _startLongitude,
    );

    if (response?.statusCode == 200 && mounted) {
      String? tripRequestId;
      if (response?.body is Map<String, dynamic>) {
        final dynamic data = response?.body['data'];
        if (data is Map<String, dynamic>) {
          tripRequestId = data['id']?.toString();
        }
      }
      final bool ready = await rideController.prepareOnRoadTripForRideUi(tripRequestId: tripRequestId);
      if (ready && mounted) {
        Get.off(() => const MapScreen(fromScreen: 'on_road'));
      } else if (mounted) {
        showCustomSnackBar('Unable to load trip details. Please try again.');
      }
    }
  }

  Future<void> _showPartySizeBottomSheet(int phoneIndex) async {
    int temp = _partySizes[phoneIndex];
    final Color primary = Theme.of(context).primaryColor;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            final int maxForRow = _maxPartyForIndex(phoneIndex);
            final int minForRow = 1;

            void bump(int delta) {
              final int next = (temp + delta).clamp(minForRow, maxForRow);
              final int others = _sumPartySizes() - _partySizes[phoneIndex];
              if (others + next <= _maxCarPassengers) {
                setBottomState(() => temp = next);
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'add_family_members'.tr,
                          style: textBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'party_size_people'.tr,
                          textAlign: TextAlign.center,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _circleStepButton(
                              context: context,
                              icon: Icons.remove,
                              onTap: () => bump(-1),
                              enabled: temp > minForRow,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                '$temp',
                                style: textBold.copyWith(fontSize: 36, letterSpacing: 0.5),
                              ),
                            ),
                            _circleStepButton(
                              context: context,
                              icon: Icons.add,
                              onTap: () => bump(1),
                              enabled: temp < maxForRow,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'total'.tr}: ${_sumPartySizes() - _partySizes[phoneIndex] + temp}/$_maxCarPassengers',
                          style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              final int others = _sumPartySizes() - _partySizes[phoneIndex];
                              if (others + temp > _maxCarPassengers) {
                                showCustomSnackBar('passenger_capacity_exceeded'.tr);
                                return;
                              }
                              setState(() {
                                _partySizes[phoneIndex] = temp;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'confirm'.tr,
                              style: textBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _circleStepButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final Color border = Theme.of(context).dividerColor.withValues(alpha: 0.8);
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 1.5),
            ),
            child: Icon(icon, size: 24),
          ),
        ),
      ),
    );
  }
}

class _EthiopianNationalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String t = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (t.startsWith('251')) {
      t = t.substring(3);
    }
    while (t.startsWith('0')) {
      t = t.substring(1);
    }
    if (t.length > 9) {
      t = t.substring(0, 9);
    }
    if (t.isNotEmpty && t[0] != '7' && t[0] != '9') {
      return oldValue;
    }
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
