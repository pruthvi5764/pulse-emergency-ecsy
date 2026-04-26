import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Task T-33 & T-34: Detailed Permission Handling
  Future<bool> handlePermission(BuildContext? context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null && context.mounted) {
        _showPermissionDialog(
          context,
          'Location Services Disabled',
          'Please enable location services in your system settings to use the emergency SOS features.',
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context != null && context.mounted) {
          _showPermissionDialog(
            context,
            'Location Access Denied',
            'LifeLine Nexus requires your location to dispatch emergency help to your exact coordinates. Please allow access.',
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context != null && context.mounted) {
        _showPermissionDialog(
          context,
          'Location Access Blocked',
          'Location access is permanently denied. Please enable it in App Settings to allow emergency response tracking.',
        );
      }
      return false;
    }

    return true;
  }

  void _showPermissionDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (title.contains('Blocked'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  // Get current position (Task T-33)
  Future<Position?> getCurrentLocation() async {
    // Note: handlePermission(null) is called here for service-level checks without UI
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error fetching location: $e');
      return null;
    }
  }

  // Live Location Stream
  Stream<Position> get liveLocationStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
