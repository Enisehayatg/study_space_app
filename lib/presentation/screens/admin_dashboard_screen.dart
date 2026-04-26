import 'package:flutter/material.dart';
import '../../core/global_state.dart';
import '../../core/animations.dart';
import '../../data/services/mongodb_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalState globalState = GlobalState();
  List<Map<String, dynamic>> _spaces = [];
  List<Map<String, dynamic>> _recentActivity = [];
  String? _selectedSpaceId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    globalState.addListener(_onStateChanged);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = MongoDBService();
      _spaces = await dbService.getSpaces();
      
      if (_spaces.isNotEmpty && _selectedSpaceId == null) {
        _selectedSpaceId = _spaces.first['id'];
      }
      
      _recentActivity = await dbService.getAdminRecentBookings(spaceId: _selectedSpaceId);
    } catch (e) {
      debugPrint("Veri Çekme Hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    globalState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic>? selectedSpace;
    if (_selectedSpaceId != null) {
      try {
        selectedSpace = _spaces.firstWhere((s) => s['id'] == _selectedSpaceId);
      } catch (e) {
        selectedSpace = _spaces.isNotEmpty ? _spaces.first : null;
      }
    }

    int capacity = selectedSpace != null ? (selectedSpace['capacity'] ?? 10) : 10;
    List<int> occupiedSeats = selectedSpace != null ? 
        ((selectedSpace['occupied_seats'] as List<dynamic>?)?.map((e) => e as int).toList() ?? []) 
        : [];
    int occupiedCount = occupiedSeats.length;
    String spaceName = selectedSpace != null ? selectedSpace['name'] : "Etüt Merkezi";

    int profit = occupiedCount * 75; // dynamic profit base
    final isDark = globalState.isDarkMode;
    Color textColor = isDark ? Colors.white : const Color(0xFF334E68);
    Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(globalState.currentUser?['name'] ?? "Yönetici Paneli", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: BouncingWidget(
              onTap: () {
                globalState.clearNotifications();
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications, size: 28, color: isDark ? Colors.grey.shade400 : Colors.blueAccent),
                  if (globalState.newBookingsCount > 0)
                    Positioned(
                      right: -5,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          globalState.newBookingsCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yönetim Paneli",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Oda Seçimi
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _spaces.length,
                itemBuilder: (context, index) {
                  final room = _spaces[index];
                  bool isSelected = room['id'] == _selectedSpaceId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                         _selectedSpaceId = room['id'];
                      });
                      _fetchData();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDark ? Colors.blueAccent.withOpacity(0.3) : Colors.blueAccent)
                            : cardColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : (isDark ? Colors.white24 : Colors.black12),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          room['name'] ?? 'Mekan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isSelected ? (isDark ? Colors.blueAccent.shade100 : Colors.white) : textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$spaceName Durumu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      globalState.isSpaceCleaning(_selectedSpaceId ?? '') ? "Temizlikte" : "Açık",
                      style: TextStyle(fontSize: 14, color: globalState.isSpaceCleaning(_selectedSpaceId ?? '') ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: !globalState.isSpaceCleaning(_selectedSpaceId ?? ''),
                      onChanged: (val) {
                        if (_selectedSpaceId != null) {
                          globalState.toggleSpaceCleaning(_selectedSpaceId!, !val);
                        }
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.shade200,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Circular Occupancy Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: occupiedCount / capacity,
                          strokeWidth: 8,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                             occupiedCount / capacity > 0.8 ? Colors.redAccent 
                             : (occupiedCount > 0 ? Colors.blueAccent : Colors.green)
                          ),
                        ),
                        Center(
                          child: Text(
                            "%${((occupiedCount / capacity) * 100).toInt()}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Doluluk Oranı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 4),
                        Text(
                          "$occupiedCount / $capacity Masa Kullanımda",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats Overview
            Row(
              children: [
                Expanded(child: _buildStatCard("Oda Kazancı", "$profit TL", Icons.account_balance_wallet, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Aktif Öğrenci", "$occupiedCount", Icons.people, isDark)),
              ],
            ),
            const SizedBox(height: 30),
            
            // Live Grid Modern
            Text(
              "Canlı Masa Durumu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF1E2630), const Color(0xFF2A3644)]
                    : [Colors.blue.shade50.withOpacity(0.5), Colors.purple.shade50.withOpacity(0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1, // Kare
                ),
                itemCount: capacity,
                itemBuilder: (context, index) {
                  bool isOccupied = occupiedSeats.contains(index);
                  bool isCleaning = globalState.isSpaceCleaning(_selectedSpaceId ?? '');

                  Color seatColor;
                  Color shadowColor;
                  IconData seatIcon;
                  // Zengin, modern ve göz yormayan (Apple / Material 3) renkler
                  if (isCleaning) {
                    seatColor = const Color(0xFF8E8E93);
                    shadowColor = Colors.transparent;
                    seatIcon = Icons.cleaning_services;
                  } else if (isOccupied) {
                    seatColor = const Color(0xFFFF3B30); // iOS Red
                    shadowColor = const Color(0xFFFF3B30).withOpacity(0.3);
                    seatIcon = Icons.person;
                  } else {
                    seatColor = const Color(0xFF34C759); // iOS Green
                    shadowColor = const Color(0xFF34C759).withOpacity(0.3);
                    seatIcon = Icons.event_seat;
                  }

                  return Container(
                    margin: const EdgeInsets.all(6), // Masaların devasa olmasını engelleyip boyutunu sınırlar
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      decoration: BoxDecoration(
                        color: seatColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: isOccupied || !isCleaning ? 8 : 0,
                            spreadRadius: isOccupied || !isCleaning ? 1 : 0,
                            offset: const Offset(0, 3), // Modern gölge açısı
                          )
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(seatIcon, color: Colors.white, size: 20),
                            const SizedBox(height: 2),
                            Text(
                              "${index + 1}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Recent Activity
            Text(
              "Son Hareketler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _recentActivity.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text("Henüz bir işlem kaydedilmedi.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivity.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final booking = _recentActivity[index];
                        final isLogin = booking["status"] == "login";
                        return _buildActivityTile(
                          booking["name"] ?? "",
                          booking["detail"] ?? "",
                          booking["time"] ?? "",
                          isLogin ? Icons.login : Icons.logout,
                          isLogin ? Colors.green : Colors.red,
                          isDark,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    Color iconColor = Colors.blueAccent;
    Color bgColor = isDark ? Colors.blueAccent.withOpacity(0.2) : Colors.blue.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String name, String detail, String time, IconData icon, Color color, bool isDark) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(detail, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      trailing: Text(time, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
    );
  }
}
