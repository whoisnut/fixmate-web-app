import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceLocationScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const ServiceLocationScreen({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<ServiceLocationScreen> createState() => _ServiceLocationScreenState();
}

class _ServiceLocationScreenState extends State<ServiceLocationScreen> {
  GoogleMapController? mapController;
  late TextEditingController addressController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  bool isLoading = false;
  String? errorMessage;

  // Default location (San Francisco)
  static const LatLng defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    addressController =
        TextEditingController(text: widget.initialAddress ?? '');
    selectedLocation = LatLng(
      widget.initialLat ?? defaultLocation.latitude,
      widget.initialLng ?? defaultLocation.longitude,
    );
    _addMarker(selectedLocation!);
  }

  @override
  void dispose() {
    addressController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  void _addMarker(LatLng location) {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('service_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Service Location'),
        ),
      );
      selectedLocation = location;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final permission = await _requestLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Location permission denied';
          isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);
      _addMarker(location);

      await mapController?.animateCamera(
        CameraUpdate.newLatLng(location),
      );

      addressController.text =
          'Current Location\n${location.latitude}, ${location.longitude}';

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<LocationPermission> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission;
  }

  void _onMapTap(LatLng location) {
    _addMarker(location);
    addressController.text = '${location.latitude}, ${location.longitude}';
  }

  void _confirmLocation() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    Navigator.pop(
      context,
      {
        'address': addressController.text,
        'lat': selectedLocation!.latitude,
        'lng': selectedLocation!.longitude,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Location'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? defaultLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            markers: markers,
            onTap: _onMapTap,
          ),

          // Top controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Current location button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      mini: true,
                      onPressed: isLoading ? null : _getCurrentLocation,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      hintText: 'Enter or search address',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: addressController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                addressController.clear();
                              },
                            )
                          : null,
                    ),
                    maxLines: null,
                  ),
                ),

                // Error message
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Info card
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedLocation != null
                          ? 'Tap on map to select location\nor use current location'
                          : 'No location selected',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
