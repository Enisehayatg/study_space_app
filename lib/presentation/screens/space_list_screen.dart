import 'package:flutter/material.dart';
import '../../data/services/mongodb_service.dart';
import '../../core/global_state.dart';
import 'facility_detail_screen.dart';
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
        title: Text("Etüt Merkezleri", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
              future: MongoDBService().getFacilities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                }
                final facilities = snapshot.data ?? [];
                if (facilities.isEmpty) {
                  return Center(child: Text("Henüz bir etüt merkezi bulunmuyor.", style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: facilities.length,
                  itemBuilder: (context, index) {
                    final facility = facilities[index];
                    return _buildFacilityCard(
                      context,
                      id: facility['id'],
                      name: facility['name'],
                      location: facility['location'],
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

  Widget _buildFacilityCard(
    BuildContext context, {
    required String id,
    required String name,
    required String location,
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
              page: FacilityDetailScreen(
                facilityId: id,
                facilityName: name,
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
          child: const Icon(Icons.business, color: Colors.blueAccent),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(location, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent),
      ),
    );
  }
}