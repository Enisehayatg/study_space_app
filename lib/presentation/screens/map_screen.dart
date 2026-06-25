import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/mongodb_service.dart';
import 'facility_detail_screen.dart';
import '../../core/animations.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Gaziantep Şehitkamil İbrahimli coordinates (Default)
  final LatLng _initialCenter = const LatLng(37.07687, 37.31682);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Canlı Etüt Haritası (OpenStreetMap)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white, // Made solid to avoid transparent overlaps
        elevation: 1,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: MongoDBService().getFacilities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Harita verileri yüklenemedi."));
          }

          final facilities = snapshot.data ?? [];
          final markers = facilities.map((facility) {
            final lat = facility['lat'] as double? ?? 37.07687; // Default lat
            final lng = facility['lng'] as double? ?? 37.31682; // Default lng
            
            return Marker(
              point: LatLng(lat, lng),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _showFacilityModal(context, facility),
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.redAccent,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 16.5, 
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.study_space_app',
                keepBuffer: 5,
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }

  void _showFacilityModal(BuildContext context, Map<String, dynamic> facility) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent.shade100,
              backgroundImage: facility['image_url'] != null ? NetworkImage(facility['image_url']) : null,
              child: facility['image_url'] == null 
                ? const Icon(Icons.business, color: Colors.white, size: 40)
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              facility['name'] ?? 'Bilinmeyen Merkez',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF334E68)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              facility['location'] ?? 'Bilinmeyen Konum',
              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    BouncePageRoute(page: FacilityDetailScreen(facilityId: facility['id'], facilityName: facility['name'] ?? 'Etüt Merkezi')),
                  );
                },
                child: const Text("İncele & Odaları Gör", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
