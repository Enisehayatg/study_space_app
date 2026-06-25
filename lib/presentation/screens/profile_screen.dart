import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:async';
import '../../core/global_state.dart';
import '../../data/services/mongodb_service.dart';
import 'package:confetti/confetti.dart';
import 'login_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalState globalState = GlobalState();
  int _totalStudyTimeHours = 0;
  int _claimedStudyHours = 0;
  bool _hasFreeHourCoupon = false;
  Timer? _timer;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    globalState.addListener(_onStateChanged);
    _fetchStudyTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchStudyTime());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    globalState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    _fetchStudyTime();
  }

  Future<void> _fetchStudyTime() async {
    final user = globalState.currentUser;
    if (user == null) return;
    
    final reservations = await MongoDBService().getUserReservations(user['id']);
    int totalMinutes = 0;
    final now = DateTime.now();

    for (var res in reservations) {
      final status = res['status'];
      if (status == 'completed' || status == 'active') {
        final start = DateTime.tryParse(res['start_time'] ?? '') ?? now;
        final end = DateTime.tryParse(res['end_time'] ?? '') ?? now;
        
        if (status == 'active') {
          if (start.isBefore(now)) {
            final validEnd = end.isBefore(now) ? end : now;
            totalMinutes += validEnd.difference(start).inMinutes;
          }
        } else {
          totalMinutes += end.difference(start).inMinutes;
        }
      }
    }

    final userMap = await MongoDBService().getUser(user['id']);
    int claimedHours = 0;
    bool hasCoupon = false;
    if (userMap != null) {
       claimedHours = userMap['claimed_study_hours'] ?? 0;
       hasCoupon = userMap['hasFreeHourCoupon'] ?? false;
       globalState.currentUser!['hasFreeHourCoupon'] = hasCoupon; 
    }

    if (mounted) {
      setState(() {
        _totalStudyTimeHours = (totalMinutes / 60).floor();
        _claimedStudyHours = claimedHours;
        _hasFreeHourCoupon = hasCoupon;
        
        final effectiveHours = _totalStudyTimeHours - _claimedStudyHours;
        if (effectiveHours >= 4 && !_hasFreeHourCoupon) {
          _triggerCouponReward(user['id']);
        }
      });
    }
  }

  void _triggerCouponReward(String userId) {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                  SizedBox(width: 10),
                  Text("Tebrikler!"),
                ],
              ),
              content: const Text(
                "Odak Döngüsünü Tamamladın! 🏆 Sonraki rezervasyonunda geçerli '1 Saatlik Ücretsiz Çalışma Kuponu' hesabına tanımlandı!",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await MongoDBService().awardCoupon(userId, 4);
                    _fetchStudyTime(); // Refresh state
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("Harika!", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = globalState.currentUser;
    final isDark = globalState.isDarkMode;

    int totalStudyTime = _totalStudyTimeHours;
    int effectiveHours = totalStudyTime - _claimedStudyHours;
    if (effectiveHours < 0) effectiveHours = 0;

    int completedCycles = _claimedStudyHours ~/ 4;
    int currentCycleHours = effectiveHours % 4;
    
    if (effectiveHours >= 4 && _hasFreeHourCoupon) {
       currentCycleHours = 4;
    }
    
    String userName = user?['name'] ?? 'Misafir Öğrenci';
    String userRole = user?['role'] == 'admin' ? 'Yönetici' : 'Gümüş Odaklanıcı';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (user != null)
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
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : Colors.blueGrey),
            onPressed: () {
              globalState.toggleTheme();
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1E2630), const Color(0xFF2A3644), const Color(0xFF192A40)] 
              : [const Color(0xFFF0F4F8), Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Glassmorphism Profile Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: const Icon(Icons.face_retouching_natural, size: 60, color: Colors.blueAccent),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF334E68)),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                   message: userRole,
                                   child: Icon(Icons.military_tech, color: Colors.blueGrey.shade300, size: 28),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Toplam Çalışma Süresi: $totalStudyTime Saat", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Puan: ${globalState.currentPoints}",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // ODAK BAHÇESİ (Gamification) - Otomatik Büyüme
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.greenAccent.withOpacity(0.05) : Colors.green.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Odak Bahçesi",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.green.shade800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              completedCycles > 0 
                                ? "Tebrikler! Bugüne kadar $completedCycles adet kahve/ödül döngüsü tamamladın! ☕🎉" 
                                : "Her 1 saatte 1 ağaç yeşerir. 4 ağaca ulaştığında bir ödül döngüsü tamamlanır!",
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                bool isGrown = index < currentCycleHours;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.elasticOut,
                                  transform: Matrix4.identity()..scale(isGrown ? 1.0 : 0.6),
                                  child: Icon(
                                    isGrown ? Icons.park : Icons.nature_people_outlined,
                                    size: isGrown ? 45 : 35,
                                    color: isGrown ? Colors.green : Colors.grey.withOpacity(0.5),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Geçmiş Rezervasyonlar Glassmorphism Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Geçmiş Rezervasyonlar",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF334E68)),
                            ),
                            const SizedBox(height: 10),
                            user == null 
                                ? const Text("Geçmiş rezervasyonlarınızı görmek için lütfen giriş yapın.")
                                : FutureBuilder<List<Map<String, dynamic>>>(
                                    future: MongoDBService().getUserReservations(user['id']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      
                                      final myBookings = snapshot.data ?? [];
                                      if (myBookings.isEmpty) {
                                        return const Text("Henüz bir rezervasyon bulunmuyor.");
                                      }

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: myBookings.length,
                                        itemBuilder: (context, index) {
                                          final booking = myBookings[index];
                                          DateTime? startTime;
                                          if (booking['start_time'] != null) {
                                            startTime = DateTime.tryParse(booking['start_time']);
                                          }
                                          String timeStr = startTime != null
                                              ? "${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}"
                                              : "Bilinmiyor";

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                child: const Icon(Icons.history, color: Colors.blueAccent),
                                              ),
                                              title: Text(booking["space_name"] ?? "Bilinmeyen Mekan", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                              subtitle: Text("Zaman: $timeStr", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                                              trailing: Text(booking['status'] == 'active' ? "Aktif" : "Tamamlandı", style: TextStyle(color: booking['status'] == 'active' ? Colors.blueAccent : Colors.green)),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
