import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  late TextEditingController addressController;
  late TextEditingController latController;
  late TextEditingController lngController;
  bool isLoading = false;
  String? errorMessage;

  final List<Map<String, dynamic>> suggestedLocations = [
    {
      'name': 'Downtown San Francisco',
      'address': '101 Market Street, San Francisco, CA',
      'lat': 37.7947,
      'lng': -122.3956,
    },
    {
      'name': 'Golden Gate Park',
      'address': 'Golden Gate Park, San Francisco, CA',
      'lat': 37.7694,
      'lng': -122.4862,
    },
    {
      'name': 'Mission District',
      'address': 'Mission District, San Francisco, CA',
      'lat': 37.7599,
      'lng': -122.4148,
    },
    {
      'name': 'Financial District',
      'address': 'Financial District, San Francisco, CA',
      'lat': 37.7927,
      'lng': -122.3975,
    },
    {
      'name': 'SoMa District',
      'address': 'South of Market, San Francisco, CA',
      'lat': 37.7749,
      'lng': -122.4194,
    },
  ];

  @override
  void initState() {
    super.initState();
    addressController =
        TextEditingController(text: widget.initialAddress ?? '');
    latController =
        TextEditingController(text: widget.initialLat?.toString() ?? '37.7749');
    lngController = TextEditingController(
        text: widget.initialLng?.toString() ?? '-122.4194');
  }

  @override
  void dispose() {
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
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
          errorMessage =
              'Location permission denied. Please enter address manually.';
          isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        addressController.text = 'Current Location';
        latController.text = position.latitude.toString();
        lngController.text = position.longitude.toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Could not get location: $e';
        isLoading = false;
      });
    }
  }

  Future<LocationPermission> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission;
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      addressController.text = location['address'];
      latController.text = location['lat'].toString();
      lngController.text = location['lng'].toString();
    });
  }

  void _confirmLocation() {
    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select an address')),
      );
      return;
    }

    double? lat;
    double? lng;

    try {
      lat = double.parse(latController.text);
      lng = double.parse(lngController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coordinates')),
      );
      return;
    }

    Navigator.pop(
      context,
      {
        'address': addressController.text,
        'lat': lat,
        'lng': lng,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Select Service Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Current Location Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : _getCurrentLocation,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                  isLoading ? 'Getting location...' : 'Use Current Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (errorMessage != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red),
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
              const SizedBox(height: 16),
            ],

            // Suggested Locations
            const Text(
              'Suggested Locations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: suggestedLocations.length,
                itemBuilder: (context, index) {
                  final location = suggestedLocations[index];
                  return GestureDetector(
                    onTap: () => _selectLocation(location),
                    child: Card(
                      margin: const EdgeInsets.only(right: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location['address'],
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${location['lat']}, ${location['lng']}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Address Input
            const Text(
              'Address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Enter address',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Coordinates
            const Text(
              'Coordinates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
