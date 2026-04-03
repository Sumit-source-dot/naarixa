import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/accommodation_property.dart';

enum RentalType { room, flat, pg }

enum UserRole { owner, renter }

extension RentalTypeX on RentalType {
  String get label {
    switch (this) {
      case RentalType.room:
        return 'Room';
      case RentalType.flat:
        return 'Flat';
      case RentalType.pg:
        return 'PG';
    }
  }
}

class HomeUiState {
  const HomeUiState({
    required this.userName,
    this.userRole,
    required this.isSafeZone,
    required this.selectedCity,
    required this.selectedRentalType,
    required this.properties,
  });

  final String userName;
  final UserRole? userRole;
  final bool isSafeZone;
  final String? selectedCity;
  final RentalType selectedRentalType;
  final List<AccommodationProperty> properties;

  HomeUiState copyWith({
    String? userName,
    UserRole? userRole,
    bool clearUserRole = false,
    bool? isSafeZone,
    String? selectedCity,
    bool clearCity = false,
    RentalType? selectedRentalType,
    List<AccommodationProperty>? properties,
  }) {
    return HomeUiState(
      userName: userName ?? this.userName,
      userRole: clearUserRole ? null : userRole ?? this.userRole,
      isSafeZone: isSafeZone ?? this.isSafeZone,
      selectedCity: clearCity ? null : selectedCity ?? this.selectedCity,
      selectedRentalType: selectedRentalType ?? this.selectedRentalType,
      properties: properties ?? this.properties,
    );
  }
}

class HomeController extends StateNotifier<HomeUiState> {
  HomeController()
      : super(
          HomeUiState(
            userName: 'Aarohi',
            userRole: UserRole.owner,
            isSafeZone: true,
            selectedCity: null,
            selectedRentalType: RentalType.room,
            properties: _mockProperties,
          ),
        );

  void setUserRole(UserRole role) {
    state = state.copyWith(userRole: role);
  }

  void selectCity(String? city) {
    state = state.copyWith(selectedCity: city, clearCity: city == null || city.isEmpty);
  }

  void selectRentalType(RentalType type) {
    state = state.copyWith(selectedRentalType: type);
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeUiState>(
  (ref) => HomeController(),
);

final citiesProvider = Provider<List<String>>(
  (ref) => const ['Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Pune'],
);

final filteredPropertiesProvider = Provider<List<AccommodationProperty>>((ref) {
  final state = ref.watch(homeControllerProvider);
  if (state.selectedCity == null) {
    return const [];
  }

  return state.properties.where((property) {
    return property.city == state.selectedCity && property.type == state.selectedRentalType.label;
  }).toList();
});

const _mockProperties = <AccommodationProperty>[
  AccommodationProperty(
    id: 'p1',
    name: 'Sukoon Women PG',
    priceLabel: 'INR 11,500 / month',
    location: 'Andheri East',
    city: 'Mumbai',
    type: 'PG',
    imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
    safetyRating: 4.8,
    isVerified: true,
  ),
  AccommodationProperty(
    id: 'p2',
    name: 'Nurture Studio Flat',
    priceLabel: 'INR 18,000 / month',
    location: 'Powai',
    city: 'Mumbai',
    type: 'Flat',
    imageUrl: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb',
    safetyRating: 4.6,
    isVerified: true,
  ),
  AccommodationProperty(
    id: 'p3',
    name: 'Comfort Nest Room',
    priceLabel: 'INR 9,800 / month',
    location: 'Koregaon Park',
    city: 'Pune',
    type: 'Room',
    imageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85',
    safetyRating: 4.4,
    isVerified: true,
  ),
  AccommodationProperty(
    id: 'p4',
    name: 'HerSpace Premium PG',
    priceLabel: 'INR 12,900 / month',
    location: 'Whitefield',
    city: 'Bengaluru',
    type: 'PG',
    imageUrl: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e',
    safetyRating: 4.9,
    isVerified: true,
  ),
  AccommodationProperty(
    id: 'p5',
    name: 'Secure Living Flat',
    priceLabel: 'INR 16,500 / month',
    location: 'Gachibowli',
    city: 'Hyderabad',
    type: 'Flat',
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858',
    safetyRating: 4.5,
    isVerified: true,
  ),
  AccommodationProperty(
    id: 'p6',
    name: 'City Guardian Room',
    priceLabel: 'INR 10,200 / month',
    location: 'Saket',
    city: 'Delhi',
    type: 'Room',
    imageUrl: 'https://images.unsplash.com/photo-1495433324511-bf8e92934d90',
    safetyRating: 4.3,
    isVerified: true,
  ),
];