import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'parcel_booking_screen.dart';
import '../../../core/theme/app_theme.dart';

class ParcelDropDetailsScreen extends StatefulWidget {
  final String serviceType;
  final String pickupLocation;
  final String dropLocation;

  const ParcelDropDetailsScreen({
    super.key,
    required this.serviceType,
    required this.pickupLocation,
    this.dropLocation = '',
  });

  @override
  State<ParcelDropDetailsScreen> createState() => _ParcelDropDetailsScreenState();
}

class _ParcelDropDetailsScreenState extends State<ParcelDropDetailsScreen> {
  final AppTheme _appTheme = AppTheme();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dropSearchController = TextEditingController();
  bool _useMyContact = false;
  String? _selectedFavoriteTag;
  String? _dropLocationName;
  LatLng? _dropLatLng;

  final List<Map<String, dynamic>> _favoriteTags = [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.work, 'label': 'Work'},
    {'icon': Icons.fitness_center, 'label': 'Gym'},
    {'icon': Icons.school, 'label': 'College'},
    {'icon': Icons.bed, 'label': 'Hostel'},
  ];

  @override
  void dispose() {
    _houseNoController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dropSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Blurred background
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
            ),
            // White modal sheet
            DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // House no./Building field
                        TextField(
                          controller: _houseNoController,
                          decoration: InputDecoration(
                            labelText: 'House no./ Building (optional)',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: const Icon(Icons.home, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Add contact details section
                        const Text(
                          'Add contact details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name*',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: const Icon(Icons.person, color: Colors.grey),
                            suffixIcon: const Icon(Icons.contact_page, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Use my contact checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _useMyContact,
                              onChanged: (value) {
                                setState(() {
                                  _useMyContact = value ?? false;
                                });
                              },
                              activeColor: _appTheme.brandRed,
                            ),
                            const Text(
                              'Use my contact for this booking',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Phone Number field
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number*',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Add to favourites section
                        const Text(
                          'Add to favourites',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Favorite tags
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._favoriteTags.map((tag) {
                              final isSelected = _selectedFavoriteTag == tag['label'];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFavoriteTag = isSelected ? null : tag['label'] as String;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _appTheme.brandRed.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? _appTheme.brandRed : Colors.grey.shade300,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tag['icon'] as IconData,
                                        size: 18,
                                        color: isSelected ? _appTheme.brandRed : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        tag['label'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected ? _appTheme.brandRed : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () {
                                // Add new favorite tag
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 18, color: Colors.grey.shade700),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Add New',
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Confirm drop details button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_nameController.text.isNotEmpty &&
                                  _phoneController.text.isNotEmpty) {
                                Navigator.pop(context); // Close the bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParcelBookingScreen(
                                      serviceType: widget.serviceType,
                                      pickupLocation: widget.pickupLocation,
                                      dropLocation: widget.dropLocation.isNotEmpty
                                          ? widget.dropLocation
                                          : 'Drop location',
                                      contactName: _nameController.text,
                                      contactPhone: _phoneController.text,
                                      houseNo: _houseNoController.text,
                                      favoriteTag: _selectedFavoriteTag,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _appTheme.brandRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Confirm drop details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

