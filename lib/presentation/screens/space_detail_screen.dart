import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/global_state.dart';
import '../../data/services/mongodb_service.dart';
import '../../core/animations.dart';
import 'success_screen.dart';

class SpaceDetailScreen extends StatefulWidget {
  final String name;
  final String? spaceId;
  final int capacity;
  final List<int> occupiedSeats;
  final List<dynamic>? roomData;

  const SpaceDetailScreen({super.key, required this.name, this.spaceId, this.capacity = 12, this.occupiedSeats = const [], this.roomData});

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  final GlobalState globalState = GlobalState();
  List<int> selectedSeats = [];
  List<int> _currentOccupiedSeats = [];
  TimeOfDay selectedTime = TimeOfDay.now();
  int selectedDuration = 1;
  bool _isReviewsExpanded = false;
  bool _isSubmitting = false;
  int _selectedRoomIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateOccupiedSeatsFromRoom();
    globalState.addListener(_onStateChanged);
  }

  void _updateOccupiedSeatsFromRoom() {
    if (widget.roomData != null && widget.roomData!.isNotEmpty) {
      if (_selectedRoomIndex < widget.roomData!.length) {
        final r = widget.roomData![_selectedRoomIndex];
        _currentOccupiedSeats = (r['occupied_seats'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [];
      }
    } else {
      _currentOccupiedSeats = List.from(widget.occupiedSeats);
    }
  }

  @override
  void dispose() {
    globalState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {
      selectedSeats.removeWhere((idx) => _currentOccupiedSeats.contains(idx));
      
      if (globalState.isRoomCleaning) {
        selectedSeats.clear();
      }
    });
  }

  void _onSeatSelected(int index) {
    if (globalState.isRoomCleaning) return;
    setState(() {
      if (selectedSeats.contains(index)) {
        selectedSeats.remove(index);
      } else {
        selectedSeats.add(index);
      }
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Widget _buildRoomSelector(bool isDark, Color textColor) {
    if (widget.roomData == null || widget.roomData!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Oda Seçimi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(widget.roomData!.length, (index) {
              final roomName = widget.roomData![index]['name'] ?? "Oda";
              final bool isSelected = _selectedRoomIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRoomIndex = index;
                    selectedSeats.clear();
                    _updateOccupiedSeatsFromRoom();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent : (isDark ? Colors.white12 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roomName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueAccent.withOpacity(0.1) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.blueAccent.withOpacity(0.3) : Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.blueAccent.shade100 : Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.blueAccent.shade100 : Colors.blue.shade800)),
        ],
      ),
    );
  }

  Widget _buildRatingCriteria(String label, double rating, bool isDark) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rating / 5.0,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white24 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.amberAccent : Colors.amber.shade600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 24,
          child: Text(rating.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
        ),
      ],
    );
  }

  void _showReviewModal(BuildContext context, bool isDark) {
    if (widget.spaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata: Mekan ID'si bulunamadı.")));
      return;
    }

    int selectedRating = 0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3644) : Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     width: 40, height: 5,
                     decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                   ),
                   const SizedBox(height: 20),
                   Text("Deneyimini Puanla", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(5, (index) {
                       return IconButton(
                         iconSize: 40,
                         icon: Icon(
                           index < selectedRating ? Icons.star : Icons.star_border,
                           color: Colors.amber,
                         ),
                         onPressed: () {
                           setModalState(() {
                             selectedRating = index + 1;
                           });
                         },
                       );
                     }),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: commentController,
                     maxLines: 4,
                     decoration: InputDecoration(
                       hintText: "Mekan hakkında ne düşünüyorsun?",
                       hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                       filled: true,
                       fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                     ),
                     style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                   ),
                   const SizedBox(height: 20),
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                       onPressed: isSubmitting ? null : () async {
                         if (selectedRating == 0) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir yıldız puanı verin.")));
                           return;
                         }
                         setModalState(() => isSubmitting = true);
                         
                         try {
                           await MongoDBService().insertReview(
                             userId: "Giriş Yapan Öğrenci", 
                             spaceId: widget.spaceId!, 
                             rating: selectedRating, 
                             comment: commentController.text.trim()
                           );
                           if (context.mounted) {
                             Navigator.pop(context); // Yetkisiz BottomSheet'i kapat
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorumunuz başarıyla eklendi!"), backgroundColor: Colors.teal));
                             // Yeniden yüklenmesi (FutureBuilder'ın baştan render theilmesi) için state'i set ediyoruz:
                             setState(() {});
                           }
                         } catch (e) {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.redAccent));
                             setModalState(() => isSubmitting = false);
                           }
                         }
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blueAccent,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                       child: isSubmitting 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Gönder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = globalState.isDarkMode;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white70 : Colors.grey;
    Color cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6);

    String formatTime(int h, int m) => "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
    int startHour = selectedTime.hour;
    int startMin = selectedTime.minute;
    int endHour = (startHour + selectedDuration) % 24;
    String timeStr = "${formatTime(startHour, startMin)} - ${formatTime(endHour, startMin)}";

    return Scaffold(
      extendBody: true, // Glassmorphism arka planın uzaması için
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.name)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E2630), const Color(0xFF2A3644)]
              : [Colors.blue.shade50.withOpacity(0.3), Colors.purple.shade50.withOpacity(0.3)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120), // Bottom navbar altına sarması için boşluk
          child: Column(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: NetworkImage("https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&q=80&w=1000"), // Mükemmel Kütüphane Placeholder
                    fit: BoxFit.cover,
                  ),
                  color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade100,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Icon(Icons.school, size: 80, color: Colors.white.withOpacity(0.9)),
                  ),
                ),
              ),
              if (globalState.isRoomCleaning)
                Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    "Bu mekan şu an temizlik sebebiyle kapalıdır.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFeatureChip(Icons.wifi, "Fiber Wi-Fi", isDark),
                          const SizedBox(width: 10),
                          _buildFeatureChip(Icons.volume_off, "Tam Sessizlik", isDark),
                          const SizedBox(width: 10),
                          _buildFeatureChip(Icons.security, "7/24 Güvenlik", isDark),
                          const SizedBox(width: 10),
                          _buildFeatureChip(Icons.chair_alt, "Ergonomik Masa", isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    _buildRoomSelector(isDark, textColor),
                    
                    // Değerlendirme ve Yorumlar Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.amberAccent.withOpacity(0.05) : Colors.amber.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.amberAccent.withOpacity(0.3) : Colors.amber.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isReviewsExpanded = !_isReviewsExpanded;
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent, // Dokunma alanı için
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Değerlendirme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const Icon(Icons.star_half, color: Colors.amber, size: 16),
                                              const SizedBox(width: 8),
                                              Text("4.8 / 5.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        _isReviewsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: subTextColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isReviewsExpanded
                                    ? (widget.spaceId == null 
                                        ? const Padding(padding: EdgeInsets.all(10), child: Text("Veritabanına ulaşılamadı."))
                                        : FutureBuilder<List<Map<String,dynamic>>>(
                                            future: MongoDBService().getSpaceReviews(widget.spaceId!),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                                              }
                                              
                                              final reviews = snapshot.data ?? [];
                                              if (reviews.isEmpty) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Text("Bu mekan için henüz bir yorum yapılmamış."),
                                                );
                                              }

                                              // Calculate Average Rating
                                              double ratingSum = 0;
                                              for(var r in reviews) { ratingSum += (r['rating'] as num).toDouble(); }
                                              double avgRating = ratingSum / reviews.length;

                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 15),
                                                  // Genel değerlendirme (Sadece bir ortalama gösteririz şimdilik dinamik olarak)
                                                  _buildRatingCriteria("Genel", double.parse(avgRating.toStringAsFixed(1)), isDark),
                                                  const SizedBox(height: 15),
                                                  ...reviews.map((review) {
                                                    int rStars = (review['rating'] as num).toInt();
                                                    String comment = review['comment'] ?? '';
                                                    return Container(
                                                      margin: const EdgeInsets.only(bottom: 10),
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? Colors.black26 : Colors.white60,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 12,
                                                                backgroundColor: Colors.blueAccent.shade100,
                                                                child: const Icon(Icons.person, size: 16, color: Colors.white),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              const Text("Öğrenci", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), // İsim Join atılabilir
                                                              const Spacer(),
                                                              Row(
                                                                children: List.generate(5, (index) => Icon(
                                                                  index < rStars ? Icons.star : Icons.star_border,
                                                                  color: Colors.amber, size: 12,
                                                                )),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            '"$comment"',
                                                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: subTextColor),
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: OutlinedButton.icon(
                                                      onPressed: () {
                                                        _showReviewModal(context, isDark);
                                                      },
                                                      icon: const Icon(Icons.edit, size: 16),
                                                      label: const Text("Deneyimini Değerlendir", style: TextStyle(fontWeight: FontWeight.bold)),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: isDark ? Colors.amberAccent : Colors.orange.shade800,
                                                        side: BorderSide(color: isDark ? Colors.amberAccent.withOpacity(0.5) : Colors.orange.withOpacity(0.5)),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ))
                                    : const SizedBox(width: double.infinity),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Zaman ve Süre Seçimi (Glassmorphic)
                    Text("Rezervasyon Süresi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text("Başlangıç Saati:", style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                                  TextButton.icon(
                                    onPressed: () => _selectTime(context),
                                    icon: Icon(Icons.access_time, color: isDark ? Colors.blueAccent.shade100 : Colors.blue),
                                    label: Text(formatTime(startHour, startMin), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.blueAccent.shade100 : Colors.blue)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: Text("Kiralama Süresi:", style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                                  DropdownButton<int>(
                                    value: selectedDuration,
                                    dropdownColor: Theme.of(context).cardColor,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                    underline: const SizedBox.shrink(),
                                    items: List.generate(8, (index) => index + 1).map((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text("$value Saat", style: TextStyle(color: textColor)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedDuration = val!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Öngörülen Saatler:", style: TextStyle(color: subTextColor)),
                                  Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    InteractiveSeatingGrid(
                      selectedSeats: selectedSeats,
                      onSeatSelected: _onSeatSelected,
                      capacity: (widget.roomData != null && widget.roomData!.isNotEmpty) 
                          ? (widget.roomData![_selectedRoomIndex]['capacity'] ?? widget.capacity) 
                          : widget.capacity,
                      occupiedSeats: _currentOccupiedSeats,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: selectedSeats.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.7),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Seçilen Masalar: ${selectedSeats.map((i) => '#${i + 1}').join(', ')}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.blueAccent.shade100 : Colors.blue.shade900),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Süre: $timeStr",
                                    style: TextStyle(color: isDark ? Colors.blue.shade200 : Colors.blue.shade800, fontSize: 12),
                                  ),
                                  Text(
                                    "${(selectedSeats.length * selectedDuration * 75).toStringAsFixed(1)} TL",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.blueAccent.shade100 : Colors.blue.shade900),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        BouncingWidget(
                          onTap: () async {
                             if (selectedSeats.isNotEmpty) {
                               final user = globalState.currentUser;
                               if (user == null) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu işlem için lütfen giriş yapın.")));
                                 return;
                               }
                               if (widget.spaceId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata: Mekan ID'si bulunamadı.")));
                                  return;
                               }

                               setState(() { _isSubmitting = true; });

                               try {
                                 // Seçilen odanın ID'sini de db ye gönderiyoruz (bookSeatsInSpace)
                                 String targetRoomId = (widget.roomData != null && widget.roomData!.isNotEmpty)
                                     ? widget.roomData![_selectedRoomIndex]['id']
                                     : 'room_main';
                                     
                                 await MongoDBService().bookSeatsInSpace(widget.spaceId!, targetRoomId, List.from(selectedSeats));
                                 
                                 // Profilde görünsün diye Reservation sekmesine ekle
                                 DateTime now = DateTime.now();
                                 DateTime startDt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                                 DateTime endDt = startDt.add(Duration(hours: selectedDuration));
                                 
                                 await MongoDBService().insertReservation(
                                   userId: user['id'], 
                                   spaceId: widget.spaceId!,
                                   roomId: targetRoomId,
                                   startTime: startDt, 
                                   endTime: endDt, 
                                   status: "active"
                                 );

                                 if (context.mounted) {
                                   setState(() {
                                     _currentOccupiedSeats.addAll(selectedSeats);
                                     selectedSeats.clear();
                                     _isSubmitting = false;
                                   });
                                   Navigator.push(
                                     context,
                                     BouncePageRoute(page: const SuccessScreen()),
                                   );
                                 }
                               } catch (e) {
                                 if (context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rezervasyon hatası: $e")));
                                   setState(() { _isSubmitting = false; });
                                 }
                               }
                             }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: _isSubmitting
                               ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : const Text(
                                   "Onayla ve Öde",
                                   style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                 ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class InteractiveSeatingGrid extends StatelessWidget {
  final List<int> selectedSeats;
  final Function(int) onSeatSelected;
  final int capacity;
  final List<int> occupiedSeats;

  const InteractiveSeatingGrid({
    super.key,
    required this.selectedSeats,
    required this.onSeatSelected,
    required this.capacity,
    required this.occupiedSeats,
  });

  @override
  Widget build(BuildContext context) {
    final globalState = GlobalState();
    final bool isCleaning = globalState.isRoomCleaning;
    final bool isDark = globalState.isDarkMode;
    Color textColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Müsait Masalar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: capacity,
          itemBuilder: (context, index) {
            bool isOccupied = occupiedSeats.contains(index);
            bool isSelected = selectedSeats.contains(index);
            
            // X-Factor: Sosyal Avatarlar'ı daha veritabanı kurulmadığı için şimdilik devre dışı bırakıyoruz.
            bool isFriend = false;
            String? friendName;

            Color seatColor;
            Color shadowColor;
            IconData seatIcon;

            // Zengin, modern ve göz yormayan (Apple / Material 3) renkler
            if (isCleaning) {
              seatColor = const Color(0xFF8E8E93);
              shadowColor = Colors.transparent;
              seatIcon = Icons.cleaning_services;
            } else if (isSelected) {
              seatColor = const Color(0xFF007AFF); // iOS Blue
              shadowColor = const Color(0xFF007AFF).withOpacity(0.4);
              seatIcon = Icons.check;
            } else if (isFriend) {
              seatColor = const Color(0xFFAF52DE); // iOS Purple
              shadowColor = const Color(0xFFAF52DE).withOpacity(0.4);
              seatIcon = Icons.face_retouching_natural;
            } else if (isOccupied) {
              seatColor = const Color(0xFFFF3B30); // iOS Red
              shadowColor = const Color(0xFFFF3B30).withOpacity(0.3);
              seatIcon = Icons.person;
            } else {
              seatColor = const Color(0xFF34C759); // iOS Green
              shadowColor = const Color(0xFF34C759).withOpacity(0.3);
              seatIcon = Icons.event_seat;
            }

            return Tooltip(
              message: isFriend ? "Bir Arkadaşın Burada: $friendName" : (isOccupied ? "Dolu Masa" : "Müsait Masa"),
              child: BouncingWidget(
                onTap: (isOccupied || isCleaning)
                    ? () {
                        if (isFriend) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Can Dostun $friendName burada çalışıyor! 🙋"), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    : () {
                        onSeatSelected(index);
                      },
                child: Container(
                  margin: const EdgeInsets.all(6), // Masaların devasa olmasını engeller (Diğer tarafla 1:1 boyut)
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: seatColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: isSelected || isFriend || isOccupied ? 8 : 0,
                          spreadRadius: isSelected || isFriend || isOccupied ? 1 : 0,
                          offset: const Offset(0, 3), // Modern tasarım gölgesi
                        )
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(seatIcon, color: Colors.white, size: 18),
                          const SizedBox(height: 2),
                          Text(
                            "${index + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}