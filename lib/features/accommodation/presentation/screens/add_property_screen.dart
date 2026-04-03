import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/accommodation_provider.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({this.propertyToEdit, super.key});

  final OwnerProperty? propertyToEdit;

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _verificationProofController = TextEditingController();
  
  String _selectedType = 'Apartment';
  bool _womenFriendly = false;
  List<String> _imageUrls = [];
  Set<String> _selectedAmenities = {};
  bool _isLoading = false;

  final List<String> _propertyTypes = ['Apartment', 'PG/Co-Living', 'Plot', 'Room', 'Villa', 'Bungalow'];
  final List<String> _amenitiesList = [
    'WiFi',
    'Parking',
    'Gym',
    'Pool',
    'Security',
    'CCTV',
    'Lift',
    'Garden',
    'Pet Friendly',
    'Laundry',
    'Kitchen',
    'Balcony',
  ];

  @override
  void initState() {
    super.initState();
    // If editing, populate form with existing data
    if (widget.propertyToEdit != null) {
      final property = widget.propertyToEdit!;
      _titleController.text = property.title;
      _descriptionController.text = property.description;
      _locationController.text = property.location;
      _selectedType = property.propertyType;
      if (property.bedrooms != null) _bedroomsController.text = property.bedrooms.toString();
      if (property.bathrooms != null) _bathroomsController.text = property.bathrooms.toString();
      if (property.area != null) _areaController.text = property.area.toString();
      _budgetController.text = property.budget.toStringAsFixed(0);
      _womenFriendly = property.womenFriendly;
      _imageUrls = List.from(property.images);
      _selectedAmenities = Set.from(property.amenities);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _imageUrlController.dispose();
    _verificationProofController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final input = _imageUrlController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image URL')),
      );
      return;
    }

    final uri = Uri.tryParse(input);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid image URL (http/https)')),
      );
      return;
    }

    setState(() {
      _imageUrls.add(input);
      _imageUrlController.clear();
    });
  }

  void _removeImageUrl(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final pendingImageUrl = _imageUrlController.text.trim();
    final pendingUri = Uri.tryParse(pendingImageUrl);
    if (pendingImageUrl.isNotEmpty &&
        pendingUri != null &&
        (pendingUri.scheme == 'http' || pendingUri.scheme == 'https') &&
        !_imageUrls.contains(pendingImageUrl)) {
      _imageUrls.add(pendingImageUrl);
      _imageUrlController.clear();
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final propertyData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'propertytype': _selectedType,
        'bedrooms': int.tryParse(_bedroomsController.text),
        'bathrooms': int.tryParse(_bathroomsController.text),
        'area': double.tryParse(_areaController.text),
        'budget': double.parse(_budgetController.text),
        'womenfriendly': _womenFriendly,
        'amenities': _selectedAmenities.toList(),
        'images': _imageUrls,
        'safetyscore': 0,
        'verification_proof': _verificationProofController.text.trim().isEmpty 
            ? null 
            : _verificationProofController.text.trim(),
      };

      // Check if editing or creating
      if (widget.propertyToEdit != null) {
        // Update existing property
        await Supabase.instance.client
            .from('property')
            .update(propertyData)
            .eq('id', widget.propertyToEdit!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property updated successfully!')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Create new property
        await Supabase.instance.client.from('property').insert({
          'ownerid': user.id,
          ...propertyData,
          'verified': false,
          'status': 'Available',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property posted successfully!')),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        final message =
            e is PostgrestException && e.code == '42704'
                ? 'Database policy misconfiguration detected. Run SQL fix script and try again.'
                : 'Error: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyToEdit != null ? 'Edit Property' : 'Post Your Property'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Property Title *',
                  hintText: 'e.g., 3BHK Flat in Andheri',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your property...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g., Andheri East, Mumbai',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Location is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Property Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Property Type *',
                  border: OutlineInputBorder(),
                ),
                items: _propertyTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value ?? 'Apartment');
                },
              ),
              const SizedBox(height: 16),

              // Bedrooms & Bathrooms Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bedrooms',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bathrooms',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Area
              TextFormField(
                controller: _areaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Area (sq.ft / sq.m)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget (INR) *',
                  hintText: 'e.g., 15000',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Budget is required';
                  if (double.tryParse(value!) == null) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Women Friendly Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Women Friendly'),
                      Switch(
                        value: _womenFriendly,
                        onChanged: (value) => setState(() => _womenFriendly = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amenities
              Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _amenitiesList.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Property Verification Proof (Optional)
              Text('Property Verification Proof (Optional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Add any proof/certificate to increase trustworthiness',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _verificationProofController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Verification Proof',
                  hintText: 'e.g., Document ID, Certificate URL, or verification number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Images
              Text('Images', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/image.jpg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addImageUrl,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_imageUrls.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(_imageUrls[index], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeImageUrl(index),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.propertyToEdit != null ? 'Update Property' : 'Post Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
