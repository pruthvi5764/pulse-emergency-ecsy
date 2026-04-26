import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeline_nexus/providers/location_provider.dart';
import 'package:lifeline_nexus/ui/theme/app_theme.dart';
import 'dart:ui';

class CommunityMapScreen extends ConsumerStatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  ConsumerState<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends ConsumerState<CommunityMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String _activeCategory = 'Hospitals';
  bool _isPulseLinkActive = false;
  bool _locationPermissionGranted = false;

  final Map<String, List<Map<String, dynamic>>> _mockData = {
    'Hospitals': [
      {'name': 'City General Hospital', 'lat': 37.421, 'lng': -122.084, 'type': 'Hospital'},
      {'name': 'Mercy Trauma Center', 'lat': 37.425, 'lng': -122.089, 'type': 'Hospital'},
    ],
    'Blood Banks': [
      {'name': 'Red Cross Blood Center', 'lat': 37.418, 'lng': -122.080, 'type': 'Blood Bank'},
      {'name': 'Pulse Blood Bank', 'lat': 37.428, 'lng': -122.095, 'type': 'Blood Bank'},
    ],
    'Pharmacies': [
      {'name': '24/7 MedStore', 'lat': 37.423, 'lng': -122.082, 'type': 'Pharmacy'},
      {'name': 'Emergency Pharma', 'lat': 37.426, 'lng': -122.092, 'type': 'Pharmacy'},
    ],
    'Oxygen': [
      {'name': 'LifeBreath Oxygen', 'lat': 37.415, 'lng': -122.075, 'type': 'Oxygen'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _updateMarkers();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    // This is a simple check. In a real app, use the permission_handler package.
    // For now, we'll just check if the location provider has a value.
    ref.listenManual(locationProvider, (previous, next) {
      if (next.value != null && mounted) {
        setState(() => _locationPermissionGranted = true);
      }
    });
  }

  void _updateMarkers() {
    final List<Map<String, dynamic>> items = _mockData[_activeCategory] ?? [];
    setState(() {
      _markers = items.map((item) {
        return Marker(
          markerId: MarkerId(item['name']),
          position: LatLng(item['lat'], item['lng']),
          infoWindow: InfoWindow(title: item['name'], snippet: item['type']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _activeCategory == 'Hospitals' ? BitmapDescriptor.hueRed :
            _activeCategory == 'Blood Banks' ? BitmapDescriptor.hueAzure :
            _activeCategory == 'Pharmacies' ? BitmapDescriptor.hueGreen :
            BitmapDescriptor.hueViolet,
          ),
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final LatLng currentPos = locationState.value != null 
        ? LatLng(locationState.value!.latitude, locationState.value!.longitude)
        : const LatLng(37.42796133580664, -122.085749655962);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: currentPos, zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            // style: _mapStyle,
          ),
          
          // Header Overlay
          _buildHeaderOverlay(),
          
          // Category Selector
          _buildCategorySelector(),
          
          // Pulse Link Toggle
          _buildPulseLinkToggle(),
        ],
      ),
    );
  }

  Widget _buildHeaderOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMUNITY MAP',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'NEAREST RESPONDERS',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: _mockData.keys.map((cat) {
            final bool isActive = _activeCategory == cat;
            return GestureDetector(
              onTap: () {
                setState(() => _activeCategory = cat);
                _updateMarkers();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Text(
                    cat.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPulseLinkToggle() {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _isPulseLinkActive 
                  ? AppTheme.accentCyan.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isPulseLinkActive ? AppTheme.accentCyan : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded, 
                  color: _isPulseLinkActive ? AppTheme.accentCyan : Colors.white24,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PULSE LINK VOLUNTEER',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        _isPulseLinkActive ? 'ACTIVE • DISPATCHABLE' : 'REGISTER AS RESPONDER',
                        style: GoogleFonts.inter(
                          color: _isPulseLinkActive ? AppTheme.accentCyan : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPulseLinkActive,
                  activeColor: AppTheme.accentCyan,
                  onChanged: (val) => setState(() => _isPulseLinkActive = val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  }
]
''';
}
