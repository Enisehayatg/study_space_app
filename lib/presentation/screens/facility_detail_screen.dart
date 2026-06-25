import 'package:flutter/material.dart';
import '../../data/services/mongodb_service.dart';
import '../../core/global_state.dart';
import 'space_detail_screen.dart';
import '../../core/animations.dart';

class FacilityDetailScreen extends StatelessWidget {
  final String facilityId;
  final String facilityName;

  const FacilityDetailScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  Widget build(BuildContext context) {
    final globalState = GlobalState();
    final isDark = globalState.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(facilityName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Bu Tesisteki Çalışma Odaları",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: MongoDBService().getSpacesByFacilityId(facilityId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                }
                final spaces = snapshot.data ?? [];
                if (spaces.isEmpty) {
                  return Center(child: Text("Bu tesiste henüz bir oda bulunmuyor.", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    return _buildRoomCard(
                      context,
                      id: space['id'],
                      name: space['name'],
                      capacity: space['capacity'] ?? 10,
                      occupiedSeats: (space['occupied_seats'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
                      price: "${space['hourly_price'] ?? 75} TL", // Dinamik fiyat veya varsayılan
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String id,
    required String name,
    required int capacity,
    required List<int> occupiedSeats,
    required String price,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            BouncePageRoute(
              page: SpaceDetailScreen(
                name: name,
                spaceId: id,
                capacity: capacity,
                occupiedSeats: occupiedSeats,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.blueAccent.withOpacity(0.2) : Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.meeting_room, color: Colors.blueAccent),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text("$capacity Masa Kapasitesi", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ),
    );
  }
}
