import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnRoadTripSummaryScreen extends StatelessWidget {
  final Map<String, dynamic>? tripData;
  const OnRoadTripSummaryScreen({super.key, this.tripData});

  double _numValue(List<String> keys) {
    for (final k in keys) {
      final dynamic v = tripData?[k];
      if (v is num) return v.toDouble();
      final double? parsed = double.tryParse('${v ?? ''}');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final double fare = _numValue(['total_fare', 'paid_fare', 'fare']);
    final double km = _numValue(['distance_km', 'actual_distance', 'distance']);
    final double mins = _numValue(['duration_minutes', 'actual_time', 'time_spent_minutes']);
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fare: $fare'),
            Text('Distance: ${km.toStringAsFixed(2)} km'),
            Text('Time Spent: ${mins.toStringAsFixed(0)} min'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
