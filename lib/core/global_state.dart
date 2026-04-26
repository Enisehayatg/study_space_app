import 'package:flutter/material.dart';
import 'dart:async';

class GlobalState extends ChangeNotifier {
  static final GlobalState _instance = GlobalState._internal();
  factory GlobalState() => _instance;
  GlobalState._internal();

  List<RoomModel> adminRooms = [
    RoomModel(id: "r1", name: "Sessiz Salon A", capacity: 12, occupiedSeats: [0, 2, 4, 7, 9]),
    RoomModel(id: "r2", name: "VIP Grup Odası", capacity: 8, occupiedSeats: [1, 3, 5]),
    RoomModel(id: "r3", name: "Açık Çalışma Alanı", capacity: 16, occupiedSeats: [0, 1, 2, 8, 12, 14]),
  ];
  
  // ============================
  // USER AUTHENTICATION STATE
  // ============================
  Map<String, dynamic>? currentUser;

  void loginUser(Map<String, dynamic> user) {
    currentUser = user;
    notifyListeners();
  }

  void logoutUser() {
    currentUser = null;
    notifyListeners();
  }

  String selectedAdminRoomId = "r1";

  RoomModel get currentRoom => adminRooms.firstWhere((r) => r.id == selectedAdminRoomId, orElse: () => adminRooms.first);

  void selectAdminRoom(String id) {
    selectedAdminRoomId = id;
    notifyListeners();
  }

  // Backward compatibility getters
  List<int> get occupiedSeats => currentRoom.occupiedSeats;
  bool get isRoomCleaning => currentRoom.isCleaning;
  int get currentRoomCapacity => currentRoom.capacity;
  
  // Sosyal Arkadaş Masaları
  Map<int, String> friendSeats = {
    2: 'Ayşe', 
    7: 'Ahmet'
  };

  List<Map<String, String>> pastBookings = [
    {"name": "Zeynep Ece", "detail": "Masa 5", "time": "15:30 (1 Saat)", "status": "login"},
    {"name": "Burak Can", "detail": "Masa 1", "time": "14:15 (2 Saat)", "status": "login"},
    {"name": "Ayşe Demir", "detail": "Masa 8", "time": "13:00 (1 Saat)", "status": "logout"},
    {"name": "Elif Su", "detail": "Masa 3", "time": "12:45 (3 Saat)", "status": "login"},
  ];
  int currentPoints = 150;
  int newBookingsCount = 0;
  
  // Odak Bahçesi ve Çalışma Süresi (Gamification)
  int totalBookedHours = 12; // Başlangıçta 12 saat = 3 Ağaç
  int get focusTrees => (totalBookedHours ~/ 4).clamp(0, 5); // Her 4 Saatte 1 Ağaç (Maksimum 5)

  // Theme Toggle
  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  // Active Timer Tracker
  DateTime? activeBookingStartTime;
  DateTime? activeBookingEndTime;
  List<int> activeSeats = [];
  Timer? _bookingTimer;

  void bookSeats(List<int> seatIndices, TimeOfDay startTime, int durationHours) {
    if (isRoomCleaning) return;
    
    final validSeats = seatIndices.where((idx) => !occupiedSeats.contains(idx)).toList();
    if (validSeats.isEmpty) return;

    occupiedSeats.addAll(validSeats);
    
    int startHour = startTime.hour;
    int startMin = startTime.minute;
    int endHour = (startHour + durationHours) % 24;
    
    String formatTime(int h, int m) => "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
    String timeStr = "${formatTime(startHour, startMin)} - ${formatTime(endHour, startMin)}";
    String durationStr = " ($durationHours Saat)";
    
    String detailStr = validSeats.length == 1 
      ? "Masa ${validSeats.first + 1}"
      : "Masalar: ${validSeats.map((i) => i + 1).join(', ')}";

    pastBookings.insert(0, {
      "name": "Zeynep Ece",
      "detail": detailStr,
      "time": timeStr + durationStr,
      "status": "login"
    });
    
    currentPoints += validSeats.length * durationHours * 50;
    newBookingsCount += validSeats.length;
    
    // Otomatik ağaç büyümesi için toplam saate ekleme yapıyoruz
    totalBookedHours += durationHours;

    // Gerçek zamanlı saat bazlı kurgu.
    DateTime now = DateTime.now();
    DateTime calcStart = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    
    if (calcStart.isBefore(now.subtract(const Duration(minutes: 5)))) {
      calcStart = calcStart.add(const Duration(days: 1));
    }
    
    activeSeats.addAll(validSeats);
    activeBookingStartTime = calcStart;
    activeBookingEndTime = calcStart.add(Duration(hours: durationHours));
    
    _startBookingTimer();

    notifyListeners();
  }

  void _startBookingTimer() {
    _bookingTimer?.cancel();
    _bookingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (activeBookingEndTime != null) {
        if (DateTime.now().isAfter(activeBookingEndTime!)) {
          occupiedSeats.removeWhere((seat) => activeSeats.contains(seat));
          activeSeats.clear();
          activeBookingStartTime = null;
          activeBookingEndTime = null;
          timer.cancel();
          notifyListeners();
        } else {
          notifyListeners();
        }
      } else {
        timer.cancel();
      }
    });
  }

  String get bookingStatusTitle {
    if (activeBookingStartTime == null) return "";
    if (DateTime.now().isBefore(activeBookingStartTime!)) {
      return "Başlamasına Kalan Süre";
    }
    return "Kiralanan Kalan Süre";
  }

  String get remainingTimeStr {
    if (activeBookingStartTime == null || activeBookingEndTime == null) return "";
    
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    if (now.isBefore(activeBookingStartTime!)) {
      final diff = activeBookingStartTime!.difference(now);
      return "${twoDigits(diff.inHours)}:${twoDigits(diff.inMinutes.remainder(60))}:${twoDigits(diff.inSeconds.remainder(60))}";
    }
    
    final diff = activeBookingEndTime!.difference(now);
    if (diff.isNegative) return "00:00:00";
    return "${twoDigits(diff.inHours)}:${twoDigits(diff.inMinutes.remainder(60))}:${twoDigits(diff.inSeconds.remainder(60))}";
  }

  void clearNotifications() {
    newBookingsCount = 0;
    notifyListeners();
  }

  // Dinamik MongoDB Odaları İçin Temizlik Durumları
  Map<String, bool> spaceCleaningStates = {};

  bool isSpaceCleaning(String spaceId) {
    return spaceCleaningStates[spaceId] ?? false;
  }

  void toggleSpaceCleaning(String spaceId, bool val) {
    spaceCleaningStates[spaceId] = val;
    notifyListeners();
  }
}

class RoomModel {
  final String id;
  final String name;
  final int capacity;
  List<int> occupiedSeats;
  bool isCleaning;

  RoomModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.occupiedSeats,
    this.isCleaning = false,
  });
}
