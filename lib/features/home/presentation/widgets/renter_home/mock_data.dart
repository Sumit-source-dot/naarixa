import 'package:flutter/material.dart';

import 'models.dart';

const List<RenterProperty> popularRenterProperties = [
  RenterProperty(
    id: 'mock-popular-1',
    name: 'Sunrise Studio Flat',
    location: 'Model Town, Ludhiana',
    price: 'INR 7,500/mo',
    type: 'Studio',
    rating: 4.8,
    reviews: 34,
    tags: ['Furnished', 'WiFi', 'Parking'],
    gradient: [Color(0xFFFFD89B), Color(0xFF19547B)],
    isVerified: true,
    isFavorite: true,
  ),
  RenterProperty(
    id: 'mock-popular-2',
    name: 'Green Nest 2BHK',
    location: 'Sector 32, Chandigarh',
    price: 'INR 14,000/mo',
    type: '2 BHK',
    rating: 4.6,
    reviews: 21,
    tags: ['Semi-Furnished', 'AC', 'Lift'],
    gradient: [Color(0xFF96FBC4), Color(0xFF3E8D63)],
    isVerified: true,
  ),
  RenterProperty(
    id: 'mock-popular-3',
    name: 'Lakeview Apartment',
    location: 'BRS Nagar, Ludhiana',
    price: 'INR 11,000/mo',
    type: '1 BHK',
    rating: 4.5,
    reviews: 18,
    tags: ['Furnished', 'Gated'],
    gradient: [Color(0xFFBDE0FE), Color(0xFF4895EF)],
  ),
];

const List<RenterProperty> nearbyRenterProperties = [
  RenterProperty(
    id: 'mock-nearby-1',
    name: 'The Corner Suite',
    location: 'Civil Lines, Ludhiana',
    price: 'INR 9,200/mo',
    type: '1 BHK',
    rating: 4.7,
    reviews: 29,
    tags: ['AC', 'Balcony'],
    gradient: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    isVerified: true,
  ),
  RenterProperty(
    id: 'mock-nearby-2',
    name: 'Urban Nest Studio',
    location: 'Sarabha Nagar, Ludhiana',
    price: 'INR 6,000/mo',
    type: 'Studio',
    rating: 4.3,
    reviews: 12,
    tags: ['Furnished', 'WiFi'],
    gradient: [Color(0xFFFCCF31), Color(0xFFF55555)],
  ),
  RenterProperty(
    id: 'mock-nearby-3',
    name: 'Harmony 3BHK',
    location: 'Dugri, Ludhiana',
    price: 'INR 18,500/mo',
    type: '3 BHK',
    rating: 4.9,
    reviews: 41,
    tags: ['Fully Furnished', 'Parking', 'Lift'],
    gradient: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    isVerified: true,
    isFavorite: true,
  ),
];

const renterCategories = [
  RenterCategory(
    label: '1 BHK',
    icon: Icons.single_bed_outlined,
    color: Color(0xFF6366F1),
    bg: Color(0xFFEDE9FE),
  ),
  RenterCategory(
    label: '2 BHK',
    icon: Icons.bed_outlined,
    color: Color(0xFF10B981),
    bg: Color(0xFFD1FAE5),
  ),
  RenterCategory(
    label: '3 BHK',
    icon: Icons.holiday_village_outlined,
    color: Color(0xFFE8703A),
    bg: Color(0xFFFFF4EE),
  ),
  RenterCategory(
    label: 'Studio',
    icon: Icons.weekend_outlined,
    color: Color(0xFFF59E0B),
    bg: Color(0xFFFEF3C7),
  ),
  RenterCategory(
    label: 'PG',
    icon: Icons.group_outlined,
    color: Color(0xFF3B82F6),
    bg: Color(0xFFDBEAFE),
  ),
  RenterCategory(
    label: 'Villa',
    icon: Icons.villa_outlined,
    color: Color(0xFF8B5CF6),
    bg: Color(0xFFF3E8FF),
  ),
];
