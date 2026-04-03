import 'package:flutter/material.dart';

class RenterProperty {
  final String id;
  final String name;
  final String location;
  final String price;
  final double? monthlyRent;
  final String? ownerId;
  final String ownerName;
  final String? ownerImageUrl;
  final String? imageUrl;
  final String? ownerPhone;
  final String? ownerEmail;
  final String type;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final DateTime? postedAt;
  final double rating;
  final int reviews;
  final List<String> tags;
  final List<Color> gradient;
  final bool isVerified;
  final bool isFavorite;

  const RenterProperty({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    this.monthlyRent,
    this.ownerId,
    this.ownerName = 'Owner',
    this.ownerImageUrl,
    this.imageUrl,
    this.ownerPhone,
    this.ownerEmail,
    required this.type,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.postedAt,
    required this.rating,
    required this.reviews,
    required this.tags,
    required this.gradient,
    this.isVerified = false,
    this.isFavorite = false,
  });
}

class RenterCategory {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const RenterCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
}
