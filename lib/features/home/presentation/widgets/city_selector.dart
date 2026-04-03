import 'package:flutter/material.dart';

class CitySelector extends StatelessWidget {
  const CitySelector({
    required this.cities,
    required this.selectedCity,
    required this.onChanged,
    super.key,
  });

  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCity,
      decoration: const InputDecoration(
        labelText: 'Select your city',
        prefixIcon: Icon(Icons.location_city_outlined),
      ),
      items: cities
          .map(
            (city) => DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}