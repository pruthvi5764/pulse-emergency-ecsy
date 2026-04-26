import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifeline_nexus/services/location_service.dart';

// Provider for the LocationService instance
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// FutureProvider for retrieving the current location (Task T-35)
final locationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getCurrentLocation();
});
