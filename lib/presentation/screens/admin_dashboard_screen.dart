import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/global_state.dart';
import '../../core/animations.dart';
import '../../data/services/mongodb_service.dart';
import 'login_selection_screen.dart';

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
      floatingActionButton: _CustomSpeedDial(
        isDark: isDark,
        onAddRoom: () => _showAddDialog(context, "Oda"),
        onAddSeat: () => _showAddSeatDialog(context),
      ),
      appBar: AppBar(
        title: Text(globalState.currentUser?['name'] ?? "Yönetici Paneli", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: BouncingWidget(
              onTap: () {
                _showNotificationsBottomSheet(context);
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
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent.shade200),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_role');
              await prefs.remove('auth_user_id');
              globalState.logoutUser();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
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
                  Color borderColor;
                  Color contentColor;
                  IconData seatIcon;
                  
                  if (isCleaning) {
                    seatColor = Colors.grey.shade100;
                    borderColor = Colors.grey.shade400;
                    contentColor = Colors.grey.shade700;
                    seatIcon = Icons.cleaning_services;
                  } else if (isOccupied) {
                    seatColor = Colors.red.shade50;
                    borderColor = Colors.red.shade700;
                    contentColor = Colors.red.shade700;
                    seatIcon = Icons.person;
                  } else {
                    seatColor = Colors.green.shade50;
                    borderColor = Colors.green.shade300;
                    contentColor = Colors.green.shade700;
                    seatIcon = Icons.event_seat;
                  }

                  return GestureDetector(
                    onTap: () {
                      if (isOccupied && _selectedSpaceId != null) {
                        _showSeatDetails(context, index);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: seatColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(seatIcon, color: contentColor, size: 20),
                              const SizedBox(height: 2),
                              Text(
                                "${index + 1}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: contentColor, fontSize: 12),
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

  Future<void> _showAddSeatDialog(BuildContext context) async {
    final seatsController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String? selectedId = _selectedSpaceId;
    if (selectedId == null && _spaces.isNotEmpty) {
      selectedId = _spaces.first['id'];
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E2630) : Colors.white,
          title: Text("Masa/Koltuk Ekle", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    decoration: InputDecoration(
                      labelText: "Oda Seçimi",
                      prefixIcon: const Icon(Icons.meeting_room, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _spaces.map((space) {
                      return DropdownMenuItem<String>(
                        value: space['id'],
                        child: Text(space['name'] ?? "İsimsiz Oda", overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      selectedId = val;
                    },
                    validator: (val) => val == null ? "Lütfen oda seçin" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: seatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Eklenecek Masa Sayısı",
                      prefixIcon: const Icon(Icons.event_seat, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty || int.tryParse(val) == null ? "Geçerli bir sayı girin" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate() && selectedId != null) {
                  final addedSeats = int.parse(seatsController.text.trim());
                  
                  Navigator.pop(ctx);
                  await _addSeatsToSpace(selectedId!, addedSeats);
                }
              },
              child: const Text("Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSeatsToSpace(String spaceId, int additionalSeats) async {
    setState(() => _isLoading = true);
    try {
      final dbService = MongoDBService();
      final space = _spaces.firstWhere((s) => s['id'] == spaceId);
      final int currentCap = space['capacity'] ?? 10;
      final int newCap = currentCap + additionalSeats;

      await dbService.updateSpace(spaceId, {
        '\$set': {
          'capacity': newCap
        }
      });
      
      await _fetchData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("${space['name']} kapasitesi $newCap oldu!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Kapasite Ekleme Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Ekleme sırasında hata oluştu."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddDialog(BuildContext context, String type) async {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    final priceController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E2630) : Colors.white,
          title: Text("Yeni $type Ekle", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "$type Adı",
                      prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Lütfen bir isim girin" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Kapasite",
                      prefixIcon: const Icon(Icons.people, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Lütfen kapasite girin" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Saatlik Ücret (TL)",
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Lütfen ücret girin" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final capacity = int.tryParse(capacityController.text.trim()) ?? 10;
                  final price = int.tryParse(priceController.text.trim()) ?? 0;
                  
                  Navigator.pop(ctx);
                  await _saveNewSpace(name, capacity, price, type);
                }
              },
              child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNewSpace(String name, int capacity, int price, String type) async {
    setState(() => _isLoading = true);
    try {
      final dbService = MongoDBService();
      
      await dbService.insertSpace(
        name: name,
        location: type == "Oda" ? "Mevcut Tesis" : "Yeni Adres",
        capacity: capacity,
        currentOccupancy: 0,
        amenities: ["wifi", "plug", "silent_zone"], 
        imageUrl: "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=600",
        occupiedSeats: [],
        hourlyPrice: price,
        facilityId: "elit_etut_merkezi",
      );
      
      await _fetchData(); // Listeyi güncelle
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("$name başarıyla eklendi!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Ekleme Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Ekleme sırasında hata oluştu."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSeatDetails(BuildContext context, int seatIndex) async {
    final spaceId = _selectedSpaceId;
    if (spaceId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return FutureBuilder<Map<String, dynamic>?>(
          future: MongoDBService().getActiveReservationForSeat(spaceId, seatIndex),
          builder: (context, snapshot) {
            Widget content;

            if (snapshot.connectionState == ConnectionState.waiting) {
              content = const Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data == null) {
              content = Center(
                child: Text("Rezervasyon detayı bulunamadı.", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              );
            } else {
              final resData = snapshot.data!['reservation'];
              final userData = snapshot.data!['user'];
              
              String userName = resData['user_name'] ?? (userData != null ? userData['name'] : 'Kayıtlı Öğrenci');
              if (userName.trim().isEmpty || userName == 'Bilinmeyen Öğrenci') {
                userName = 'Kayıtlı Öğrenci';
              }
              final startTime = DateTime.tryParse(resData['start_time'] ?? '') ?? DateTime.now();
              final endTime = DateTime.tryParse(resData['end_time'] ?? '') ?? DateTime.now().add(const Duration(hours: 1));
              
              final durationHrs = endTime.difference(startTime).inHours;
              final remainingMins = endTime.difference(DateTime.now()).inMinutes;
              final isExpired = remainingMins <= 0;

              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                            const SizedBox(height: 4),
                            Text("Masa ${seatIndex + 1}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard("Giriş", "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}", Icons.login, Colors.green, isDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard("Süre", "$durationHrs Saat", Icons.timer, Colors.orange, isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    "Kalan Süre", 
                    isExpired ? "Süresi Doldu" : "${(remainingMins / 60).floor()} sa ${remainingMins % 60} dk", 
                    Icons.hourglass_bottom, 
                    isExpired ? Colors.red : Colors.blueAccent, 
                    isDark,
                    isFullWidth: true
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        await MongoDBService().checkoutSeat(spaceId, seatIndex, resData['id']);
                        await _fetchData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Masa ${seatIndex + 1} başarıyla kapatıldı!"), backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text("Masayı Kapat / Check-out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              );
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2630) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    content,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, bool isDark, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    final isDark = globalState.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2630) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              Text("Yeni Rezervasyon Bildirimleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              if (_recentActivity.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Henüz yeni bir aktivite yok.", style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivity[index];
                    final date = DateTime.tryParse(activity['start_time'] ?? '') ?? DateTime.now();
                    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                    final String studentName = activity['user_name'] ?? activity['name'] ?? '';
                    final bool isLoadingName = studentName.isEmpty || studentName == 'Bilinmeyen Öğrenci';
                    
                    final seatsList = activity['seats'] as List<dynamic>?;
                    final String tableName = (seatsList != null && seatsList.isNotEmpty) 
                      ? seatsList.map((e) => "Masa ${(e as int) + 1}").join(", ") 
                      : (activity['space_name'] ?? '');
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        child: const Icon(Icons.person, color: Colors.blueAccent),
                      ),
                      title: isLoadingName 
                        ? Row(
                            children: const [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text("Bilgiler yükleniyor...", style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          )
                        : Text("$studentName isimli öğrenci $tableName'ü kiraladı", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                      subtitle: Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomSpeedDial extends StatefulWidget {
  final bool isDark;
  final VoidCallback onAddRoom;
  final VoidCallback onAddSeat;

  const _CustomSpeedDial({required this.isDark, required this.onAddRoom, required this.onAddSeat});

  @override
  State<_CustomSpeedDial> createState() => _CustomSpeedDialState();
}

class _CustomSpeedDialState extends State<_CustomSpeedDial> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAction(String title, IconData icon, VoidCallback onTap, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.1, 
          1.0, 
          curve: Curves.easeOutBack,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1, 
            1.0, 
            curve: Curves.easeOut,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'fab_child_$index',
                backgroundColor: widget.isDark ? Colors.blueAccent.shade100 : Colors.blueAccent,
                foregroundColor: Colors.white,
                onPressed: () {
                  _toggle();
                  onTap();
                },
                child: Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen || _controller.isAnimating)
          _buildAction("Yeni Oda Ekle", Icons.meeting_room, widget.onAddRoom, 1),
        if (_isOpen || _controller.isAnimating)
          _buildAction("Masa/Koltuk Ekle", Icons.event_seat, widget.onAddSeat, 0),
        FloatingActionButton(
          heroTag: 'fab_main',
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * (3.14159 / 4), // 45 derece dönüş
                child: const Icon(Icons.add),
              );
            },
          ),
        ),
      ],
    );
  }
}
