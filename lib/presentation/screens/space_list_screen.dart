import 'package:flutter/material.dart';
import '../../data/services/mongodb_service.dart';
import '../../core/global_state.dart';
import 'space_detail_screen.dart';
import '../../core/animations.dart';

class SpaceListScreen extends StatelessWidget {
  const SpaceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final globalState = GlobalState();
    final isDark = globalState.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Çalışma Alanları", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: globalState,
            builder: (context, child) {
              if (globalState.activeBookingEndTime == null) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent.shade100]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_alarms_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(globalState.bookingStatusTitle, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            globalState.remainingTimeStr,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: MongoDBService().getSpaces(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                }
                final spaces = snapshot.data ?? [];
                if (spaces.isEmpty) {
                  return Center(child: Text("Henüz bir mekan bulunmuyor.", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    return _buildSpaceCard(
                      context,
                      id: space['id'],
                      name: space['name'],
                      location: space['location'],
                      price: "75 TL", // Şimdilik statik bir fiyat kurgusu
                      roomData: space['rooms'] ?? [],
                      capacity: space['capacity'] ?? 10,
                      occupiedSeats: (space['occupied_seats'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
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

  Widget _buildSpaceCard(
    BuildContext context, {
    required String id,
    required String name,
    required String location,
    required String price,
    required List<dynamic> roomData,
    required int capacity,
    required List<int> occupiedSeats,
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
                roomData: roomData,
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
          child: const Icon(Icons.school, color: Colors.blueAccent),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(location, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ),
    );
  }
}