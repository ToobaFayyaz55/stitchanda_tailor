import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'cnic_upload_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  double? latitude;
  double? longitude;
  String? address;
  bool isLoadingLocation = false;

  final addressController = TextEditingController();

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required. Please enable it in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        addressController.text = address ?? '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  void _continueToNextScreen() {
    // Location is MANDATORY - must have latitude and longitude
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is mandatory. Please capture your location using GPS.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Save location to AuthCubit
    context.read<AuthCubit>().updateLocation(
      latitude: latitude!,
      longitude: longitude!,
      fullAddress: addressController.text,
    );

    // Navigate to next screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CnicUploadScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tailor Registration"),
        backgroundColor: AppColors.caramel,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Location",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBrown,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "We need your location for smooth delivery of cloth and stitched products. Location is MANDATORY.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 30),

              // Current Location Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: latitude != null ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: latitude != null ? Colors.green : Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      latitude != null ? Icons.location_on : Icons.location_off,
                      color: latitude != null ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latitude != null ? 'Location Captured ✓' : 'Location Not Captured ✗',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: latitude != null ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (latitude != null && longitude != null)
                            Text(
                              'Latitude: ${latitude!.toStringAsFixed(4)}\nLongitude: ${longitude!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            )
                          else
                            const Text(
                              'Press button below to capture location',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Get Current Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.caramel,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: isLoadingLocation
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location),
                  onPressed: isLoadingLocation ? null : _getCurrentLocation,
                  label: Text(
                    isLoadingLocation ? 'Getting Location...' : 'Get My Current Location (GPS)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Divider
              const Divider(height: 30),
              const Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 30),

              const SizedBox(height: 10),

              // Full Address TextField
              const Text(
                "Full Address",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBrown,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: "Enter your full address",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  hintText: "e.g., Landhi, Karachi",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 12),
              const Text(
                "Important: GPS location capture is MANDATORY. Please ensure the location is accurate as it will be used for delivery.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.caramel,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _continueToNextScreen,
                  child: const Text(
                    "Continue to CNIC Upload",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

