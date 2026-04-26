import 'package:flutter/foundation.dart';

@immutable
class Hospital {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> capabilities;
  final int aiRank;

  const Hospital({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.capabilities = const [],
    this.aiRank = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'capabilities': capabilities,
      'aiRank': aiRank,
    };
  }

  // Added safe type parsing
  factory Hospital.fromMap(Map<String, dynamic> map) {
    return Hospital(
      placeId: map['placeId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      lat: num.tryParse(map['lat']?.toString() ?? '')?.toDouble() ?? 0.0,
      lng: num.tryParse(map['lng']?.toString() ?? '')?.toDouble() ?? 0.0,
      capabilities: (map['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aiRank: num.tryParse(map['aiRank']?.toString() ?? '')?.toInt() ?? 0,
    );
  }

  // Added copyWith for state management
  Hospital copyWith({
    String? placeId,
    String? name,
    String? address,
    double? lat,
    double? lng,
    List<String>? capabilities,
    int? aiRank,
  }) {
    return Hospital(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      capabilities: capabilities ?? this.capabilities,
      aiRank: aiRank ?? this.aiRank,
    );
  }
}
