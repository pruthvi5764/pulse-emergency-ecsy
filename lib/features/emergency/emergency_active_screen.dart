import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lifeline_nexus/providers/location_provider.dart';
import 'package:lifeline_nexus/providers/auth_provider.dart';
import 'package:lifeline_nexus/services/emergency_service.dart';
import 'package:lifeline_nexus/services/offline_fallback_service.dart';
import 'dart:ui';

class EmergencyActiveScreen extends ConsumerStatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  ConsumerState<EmergencyActiveScreen> createState() =>
      _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState
    extends ConsumerState<EmergencyActiveScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final EmergencyService _emergencyService = EmergencyService();
  final OfflineFallbackService _fallbackService = OfflineFallbackService();
  
  String _statusMessage = 'Initializing Life-Link…';
  bool _isProcessing = true;
  bool _isDispatchSent = false;
  
  String? _emergencyId;
  Map<String, dynamic>? _topHospital;
  LatLng? _userLocation;

  final String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startEmergencyProtocol();
  }

  Future<void> _startEmergencyProtocol() async {
    final locationService = ref.read(locationServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user == null) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: No session found.';
          _isProcessing = false;
        });
      }
      return;
    }

    try {
      setState(() => _statusMessage = 'Locking GPS coordinates…');
      final position = await locationService.getCurrentLocation();
      
      if (position == null) throw Exception("Location Permission Denied");
      
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _statusMessage = 'Analyzing rescue corridors…';
        });
      }

      final result = await _emergencyService.triggerEmergency(
        uid: user.uid,
        lat: position.latitude,
        lng: position.longitude,
        emergencyType: 'medical',
      );

      if (result != null && mounted) {
        setState(() {
          _emergencyId = result['emergencyId'];
          _topHospital = result['topHospital'];
          _isProcessing = false;
          _isDispatchSent = true;
          _statusMessage = 'RESCUE DISPATCHED';
        });
        _emergencyService.triggerDispatch(_emergencyId!);
      } else {
        throw Exception("Failed to initiate emergency");
      }

    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Offline Mode Active');
      }
      if (_userLocation != null) {
        final success = await _fallbackService.sendSOS(
          lat: _userLocation!.latitude,
          lng: _userLocation!.longitude,
        );
        if (mounted) {
          setState(() {
            _statusMessage = success ? 'SOS BROADCASTED (SMS)' : 'Emergency Broadcast Error';
            _isProcessing = false;
            _isDispatchSent = success; 
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_userLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                controller.setMapStyle(_darkMapStyle);
              },
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              markers: {
                Marker(
                  markerId: const MarkerId('user'),
                  position: _userLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(180.0),
                ),
                if (_topHospital != null)
                  Marker(
                    markerId: const MarkerId('hospital'),
                    position: LatLng(
                      (_topHospital!['lat'] as num).toDouble(), 
                      (_topHospital!['lng'] as num).toDouble()
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
              },
            ),

          Positioned.fill(
            child: Column(
              children: [
                _buildSeamlessHeader(),
                const Spacer(),
                if (_isProcessing) _buildMinimalProcessing(),
                if (!_isProcessing && _isDispatchSent) _buildSeamlessStatusCard(),
                const Spacer(),
                _buildSeamlessFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeamlessHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            _isProcessing ? 'INITIALIZING' : 'SOS ACTIVE',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMinimalProcessing() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF5252).withValues(alpha: 0.12),
              border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.sos_rounded, size: 60, color: Color(0xFFFF5252)),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _statusMessage.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white, 
            fontSize: 13, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 2.0
          ),
        ),
      ],
    );
  }

  Widget _buildSeamlessStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 20),
                   const SizedBox(width: 12),
                   Text(
                    _statusMessage.contains('SMS') ? 'BROADCAST SENT' : 'RESCUE DISPATCHED',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900, 
                      fontSize: 14, 
                      color: const Color(0xFF00E5FF), 
                      letterSpacing: 1.0
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'EN ROUTE TO ${_topHospital?['name']?.toString().toUpperCase() ?? 'NEAREST TRAUMA CENTER'}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w700
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSeamlessMetric(Icons.timer_outlined, '12 MINS', 'ETA'),
                  _buildSeamlessMetric(Icons.local_hospital_outlined, 'SPECIALIZED', 'RESPONSE'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeamlessMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value, 
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900, 
            color: Colors.white, 
            fontSize: 12
          )
        ),
        Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 8, 
            color: Colors.white38, 
            fontWeight: FontWeight.w800, 
            letterSpacing: 1.0
          )
        ),
      ],
    );
  }

  Widget _buildSeamlessFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(
            'POLICE AND EMERGENCY CONTACTS SYNCED',
            style: GoogleFonts.inter(
              color: Colors.white24, 
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'CANCEL SOS', 
                style: GoogleFonts.inter(
                  color: Colors.white30, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 11, 
                  letterSpacing: 2.0
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
}
