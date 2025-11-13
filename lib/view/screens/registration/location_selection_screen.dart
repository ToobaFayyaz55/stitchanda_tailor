import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  bool initialFetched = false;

  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto attempt location fetch
    _autoFetch();
  }

  Future<void> _autoFetch() async {
    await _getCurrentLocation(auto: true);
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {

      // Guard if geocoding not linked yet
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final List<String?> rawParts = [
          p.street,
          p.subLocality,
          (p.locality?.isNotEmpty ?? false) ? p.locality : p.subAdministrativeArea,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ];
        print(rawParts);
        final parts = rawParts
            .where((e) => e != null && e.trim().isNotEmpty)
            .map((e) => _titleCase(e!.trim()))
            .toList();
        final formatted = parts.join(', ');
        return formatted.isNotEmpty ? formatted : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    } catch (e) {
      // swallow and fallback
    }
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  String _titleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _getCurrentLocation({bool auto = false}) async {
    if (isLoadingLocation) return;
    setState(() => isLoadingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && !auto) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Enable it in settings.'), backgroundColor: Colors.red),
          );
        }
        setState(() => isLoadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final resolved = await _reverseGeocode(position.latitude, position.longitude);

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        address = resolved;
        addressController.text = resolved;
        initialFetched = true;
      });

      if (mounted && !auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted && !auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingLocation = false);
    }
  }

  void _continueToNextScreen() {
    if (latitude == null || longitude == null || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for location. Please try again.'), backgroundColor: Colors.orange),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CnicUploadScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tailor Registration"), backgroundColor: AppColors.caramel),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Your Location", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.deepBrown)),
            const SizedBox(height: 10),
            const Text(
              "We auto-captured your location for delivery logistics. You can refresh if it seems inaccurate.",
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: latitude != null ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: latitude != null ? Colors.green : Colors.grey),
              ),
              child: Row(children: [
                Icon(latitude != null ? Icons.location_on : Icons.location_off, color: latitude != null ? Colors.green : Colors.grey, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      latitude != null ? 'Location Ready ✓' : 'Capturing Location...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: latitude != null ? Colors.green : Colors.red),
                    ),
                    const SizedBox(height: 4),
                    if (latitude != null && longitude != null)
                      Text('Lat: ${latitude!.toStringAsFixed(4)}  •  Lng: ${longitude!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey))
                    else
                      const Text('Please wait while we get your GPS fix', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: isLoadingLocation
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.my_location),
                onPressed: isLoadingLocation ? null : () => _getCurrentLocation(auto: false),
                label: Text(isLoadingLocation ? 'Refreshing...' : 'Refresh Location',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Detected Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepBrown)),
            const SizedBox(height: 8),
            TextFormField(
              controller: addressController,
              readOnly: true,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                labelText: 'Auto-detected full address',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.location_on_outlined),
                hintText: 'Resolving address...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textBlack),
            ),
            const SizedBox(height: 12),
            const Text(
              "Important: Accurate location helps with pick-up and delivery scheduling.",
              style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _continueToNextScreen,
                child: const Text("Continue to CNIC Upload",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
