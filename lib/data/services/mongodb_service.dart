import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();

  factory MongoDBService() {
    return _instance;
  }

  MongoDBService._internal();

  Db? _db;

  Future<void> connect() async {
    try {
      String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      String url = 'mongodb://root:example@$host:27017/study_space?authSource=admin';
      
      _db = await Db.create(url);
      await _db?.open();
      print('✅ MongoDB bağlantısı başarılı: study_space');

      // Koleksiyonların (Tabloların) var olduğundan emin ol
      await _ensureCollectionsExist();

    } catch (e) {
      print('❌ MongoDB bağlantı hatası: $e');
    }
  }

  Future<void> _ensureCollectionsExist() async {
    if (_db == null) return;
    try {
      final existingCollections = await _db!.getCollectionNames();
      final requiredCollections = ['users', 'facilities', 'spaces', 'reservations', 'sessions', 'reviews', 'favorites'];

      for (var col in requiredCollections) {
        if (!existingCollections.contains(col)) {
           await _db!.createCollection(col);
           print('📌 Koleksiyon (Tablo) oluşturuldu: $col');
        }
      }
    } catch (e) {
      print('Koleksiyon kontrol hatası: $e');
    }
  }

  Db? get db => _db;

  // ==========================================
  // SEED DATA (Örnek Veri Yükleyici)
  // ==========================================
  Future<void> seedData() async {
    if (_db == null) return;

    final usersCol = _db!.collection('users');
    final spacesCol = _db!.collection('spaces');
    final facilitiesCol = _db!.collection('facilities');

    // MIGRATION PATCHES:
    await facilitiesCol.update({'id': 'fac_elit_1'}, {'\$set': {'id': 'elit_etut_merkezi'}});
    await spacesCol.update({'name': 'Sakin Kütüphane'}, {'\$set': {'name': 'Sessiz Bireysel Çalışma Alanı'}});
    await spacesCol.update({'name': 'Odak Çalışma Çatı'}, {'\$set': {'name': 'Grup Çalışma & Proje Odası'}});
    await spacesCol.update({'name': 'Gece Kuşu Etüt'}, {'\$set': {'name': '7/24 Kesintisiz Odak Salonu'}});
    await spacesCol.update({'name': 'ELITE EĞİTİM KURUMLARI'}, {'\$set': {'name': 'Birebir Mentörlük & Etüt Odası'}});

    // MIGRATION: Update old seed data so it is completely dynamic but shows Gaziantep
    await facilitiesCol.update(
      {'id': 'elit_etut_merkezi'}, 
      {'\$set': {'location': 'Gaziantep Şehitkamil / İbrahimli', 'lat': 37.07687, 'lng': 37.31682}}
    );
    await facilitiesCol.update(
      {'id': 'fac_other_2'}, 
      {'\$set': {'location': 'Gaziantep Şahinbey / Üniversite Bulvarı', 'lat': 37.0285, 'lng': 37.3242}}
    );

    // Eğer kullanıcı tablosu boşsa örnek veriler ekleyelim
    final userCount = await usersCol.count();
    if (userCount == 0) {
      print('🌱 Örnek Kullanıcılar ekleniyor...');
      await insertUser(name: "Ali Veli", email: "ali@student.com", role: "student", totalStudyTime: 120);
      await insertUser(name: "Ayşe Yılmaz", email: "ayse@student.com", role: "student", totalStudyTime: 300);
      await insertUser(name: "Mekan Sahibi", email: "admin@space.com", role: "admin", totalStudyTime: 0);
    }

    // Eğer tesisler tablosu boşsa örnek tesisler (Facilities) ekleyelim
    final facilityCount = await facilitiesCol.count();
    String defaultFacilityId = "elit_etut_merkezi";
    if (facilityCount == 0) {
      print('🌱 Örnek Tesisler ekleniyor...');
      await insertFacility(
        id: defaultFacilityId,
        name: "Elit Eğitim Kurumları",
        location: "Gaziantep Şehitkamil / İbrahimli",
        imageUrl: "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=600",
        adminId: "admin_123",
        lat: 37.07687,
        lng: 37.31682,
      );
      await insertFacility(
        id: "fac_other_2",
        name: "X Etüt Merkezi",
        location: "Gaziantep Şahinbey / Üniversite Bulvarı",
        imageUrl: "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=600",
        adminId: "admin_456",
        lat: 37.0285,
        lng: 37.3242,
      );
    }

    // Eğer mekan tablosu boşsa örnek etüt merkezleri (Odalar) ekleyelim
    final spaceCount = await spacesCol.count();
    if (spaceCount == 0) {
      print('🌱 Örnek Odalar ekleniyor...');
      await insertSpace(
        name: "Sessiz Bireysel Çalışma Alanı", 
        location: "Kadıköy, İstanbul", 
        capacity: 50, 
        currentOccupancy: 12, 
        amenities: ["wifi", "plug", "silent_zone"], 
        imageUrl: "https://images.unsplash.com/photo-1549695627-88abeb7e93da?q=80&w=600",
        occupiedSeats: [0, 2, 4, 7, 9, 15, 22],
        facilityId: defaultFacilityId,
      );
      await insertSpace(
        name: "Grup Çalışma & Proje Odası", 
        location: "Beşiktaş, İstanbul", 
        capacity: 30, 
        currentOccupancy: 28, 
        amenities: ["wifi", "plug", "coffee", "meeting_room"], 
        imageUrl: "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=600",
        occupiedSeats: [1, 3, 5, 10, 11, 20],
        facilityId: defaultFacilityId,
      );
      await insertSpace(
        name: "7/24 Kesintisiz Odak Salonu", 
        location: "Çankaya, Ankara", 
        capacity: 100, 
        currentOccupancy: 5, 
        amenities: ["wifi", "plug", "24/7"], 
        imageUrl: "https://images.unsplash.com/photo-1521587760476-6c12a4b040da?q=80&w=600",
        occupiedSeats: [0, 1, 2, 8, 12, 14, 55, 60, 99],
        facilityId: "fac_other_2",
      );
      await insertSpace(
        name: "Birebir Mentörlük & Etüt Odası", 
        location: "Gaziantep Şehitkamil / İbrahimli", 
        capacity: 15, 
        currentOccupancy: 2, 
        amenities: ["wifi", "plug", "whiteboard", "teacher"], 
        imageUrl: "https://images.unsplash.com/photo-1517048676732-d65bc937f952?q=80&w=600",
        occupiedSeats: [3, 7],
        facilityId: defaultFacilityId,
      );
    }

    // Eğer yorumlar tablosu boşsa örnek yorumlar ekleyelim
    final reviewsCol = _db!.collection('reviews');
    if (await reviewsCol.count() == 0) {
      print('🌱 Örnek Yorumlar ekleniyor...');
      final spacesList = await spacesCol.find().toList();
      final usersList = await usersCol.find().toList();
      if (spacesList.isNotEmpty && usersList.isNotEmpty) {
        await insertReview(userId: usersList[0]['id'], spaceId: spacesList[0]['id'], rating: 5, comment: "Harika, çok sessiz bir ortam.");
        if (spacesList.length > 1) {
          await insertReview(userId: usersList[1]['id'], spaceId: spacesList[1]['id'], rating: 4, comment: "Güzeldi fakat internet biraz yavaştı.");
        }
      }
    }

    // Eğer favoriler tablosu boşsa örnek beğeniler ekleyelim
    final favoritesCol = _db!.collection('favorites');
    if (await favoritesCol.count() == 0) {
      print('🌱 Örnek Beğeniler (Favoriler) ekleniyor...');
      final spacesList = await spacesCol.find().toList();
      final usersList = await usersCol.find().toList();
      if (spacesList.isNotEmpty && usersList.isNotEmpty) {
        await addFavorite(userId: usersList[0]['id'], spaceId: spacesList[0]['id']);
      }
    }
  }

  // ==========================================
  // USERS (Kullanıcılar)
  // Schema: id, name, email, role (student/admin), total_study_time.
  // ==========================================
  Future<void> insertUser({required String name, required String email, required String role, int totalStudyTime = 0, String? password}) async {
    final Map<String, dynamic> data = {
      'id': ObjectId().toHexString(),
      'name': name,
      'email': email,
      'password': password ?? '123456', 
      'role': role,
      'total_study_time': totalStudyTime,
      'hasFreeHourCoupon': false,
      'claimed_study_hours': 0,
    };
    await _insertGeneric('users', data);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (_db == null || !_db!.isConnected) return null;
    return await _db!.collection('users').findOne({'id': userId});
  }

  Future<void> awardCoupon(String userId, int hoursToClaim) async {
    if (_db == null || !_db!.isConnected) return;
    await _db!.collection('users').update(
      {'id': userId},
      {
        '\$set': {'hasFreeHourCoupon': true},
        '\$inc': {'claimed_study_hours': hoursToClaim}
      }
    );
  }

  Future<void> useCoupon(String userId) async {
    if (_db == null || !_db!.isConnected) return;
    await _db!.collection('users').update(
      {'id': userId},
      {'\$set': {'hasFreeHourCoupon': false}}
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() => _getGeneric('users');
  Future<void> updateUser(String email, Map<String, dynamic> modifier) => _updateGeneric('users', {'email': email}, modifier);
  Future<void> deleteUser(String email) => _deleteGeneric('users', {'email': email});

  // ==========================================
  // FACILITIES (Tesisler / Etüt Merkezleri)
  // Schema: id, name, location, image_url, admin_id
  // ==========================================
  Future<void> insertFacility({
    required String id,
    required String name,
    required String location,
    required String imageUrl,
    required String adminId,
    double? lat,
    double? lng,
  }) async {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'location': location,
      'image_url': imageUrl,
      'admin_id': adminId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    await _insertGeneric('facilities', data);
  }

  Future<List<Map<String, dynamic>>> getFacilities() => _getGeneric('facilities');

  // ==========================================
  // SPACES (Odalar)
  // Schema: id, name, location, capacity, current_occupancy, amenities, image_url, facility_id
  // ==========================================
  Future<void> insertSpace({
    required String name, 
    required String location, 
    required int capacity, 
    required int currentOccupancy, 
    required List<String> amenities, 
    required String imageUrl, 
    List<int> occupiedSeats = const [],
    List<dynamic>? rooms,
    int? hourlyPrice,
    String? facilityId,
  }) async {
    
    final spaceRooms = rooms ?? [
      {
        'id': 'room_main',
        'name': 'Ana Salon (Sessiz)',
        'capacity': capacity > 0 ? capacity : 40,
        'occupied_seats': occupiedSeats,
      },
      {
        'id': 'room_co',
        'name': 'Ortak Çalışma',
        'capacity': 10,
        'occupied_seats': <int>[],
      },
      {
        'id': 'room_vip',
        'name': 'VIP Oda',
        'capacity': 4,
        'occupied_seats': <int>[],
      }
    ];

    final Map<String, dynamic> data = {
      'id': ObjectId().toHexString(),
      'name': name,
      'location': location,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'amenities': amenities,
      'image_url': imageUrl,
      'occupied_seats': occupiedSeats,
      'rooms': spaceRooms,
      'facility_id': facilityId ?? "elit_etut_merkezi", // Admin paneli uyumluluğu için varsayılan
      if (hourlyPrice != null) 'hourly_price': hourlyPrice,
    };
    await _insertGeneric('spaces', data);
  }

  Future<List<Map<String, dynamic>>> getSpaces() => _getGeneric('spaces');
  
  Future<List<Map<String, dynamic>>> getSpacesByFacilityId(String facilityId) async {
    if (_db == null || !_db!.isConnected) return [];
    final allSpaces = await _db!.collection('spaces').find().toList();
    return allSpaces.where((space) {
      final String? fId = space['facility_id'];
      // Eski odaların facility_id'si yoksa VEYA fac_elit_1 ise, bunları elit_etut_merkezi'ne bağla
      if (facilityId == "elit_etut_merkezi" && (fId == null || fId == "fac_elit_1")) return true;
      return fId == facilityId;
    }).toList();
  }
  Future<void> updateSpace(String id, Map<String, dynamic> modifier) => _updateGeneric('spaces', {'id': id}, modifier);
  Future<void> deleteSpace(String id) => _deleteGeneric('spaces', {'id': id});

  Future<void> bookSeatsInSpace(String spaceId, String targetRoomId, List<int> newSeatIndices) async {
    if (_db == null || !_db!.isConnected) return;
    final collection = _db!.collection('spaces');
    final space = await collection.findOne({'id': spaceId});
    if (space == null) return;

    List<dynamic> rooms = space['rooms'] ?? [];
    bool roomFound = false;

    for (int i = 0; i < rooms.length; i++) {
      if (rooms[i]['id'] == targetRoomId) {
        roomFound = true;
        List<int> currentOccupied = [];
        if (rooms[i]['occupied_seats'] != null) {
          for (var seat in rooms[i]['occupied_seats']) {
            currentOccupied.add(seat as int);
          }
        }
        
        for (int seat in newSeatIndices) {
          if (!currentOccupied.contains(seat)) {
            currentOccupied.add(seat);
          }
        }
        
        rooms[i]['occupied_seats'] = currentOccupied;
        break;
      }
    }

    // Eğer eski bir space ise ve rooms yoksa veya room bulunamadıysa root occupied_seats güncelleyelim.
    if (!roomFound || rooms.isEmpty) {
      List<int> currentOccupied = [];
      if (space['occupied_seats'] != null) {
        for (var seat in space['occupied_seats']) {
          currentOccupied.add(seat as int);
        }
      }
      for (int seat in newSeatIndices) {
        if (!currentOccupied.contains(seat)) {
          currentOccupied.add(seat);
        }
      }
      await updateSpace(spaceId, {
        '\$set': {
          'occupied_seats': currentOccupied,
        }
      });
      return;
    }

    await updateSpace(spaceId, {
      '\$set': {
        'rooms': rooms,
      }
    });
  }

  // ==========================================
  // RESERVATIONS (Rezervasyonlar)
  // Schema: id, user_id, space_id, start_time, end_time, status.
  // ==========================================
  Future<void> insertReservation({required String userId, String? userName, required String spaceId, String? roomId, required DateTime startTime, required DateTime endTime, required String status, List<int>? seats}) async {
    final Map<String, dynamic> data = {
      'id': ObjectId().toHexString(),
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      'space_id': spaceId,
      if (roomId != null) 'room_id': roomId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      if (seats != null) 'seats': seats,
    };
    await _insertGeneric('reservations', data);
  }

  Future<Map<String, dynamic>?> getActiveReservationForSeat(String spaceId, int seatIndex) async {
    if (_db == null || !_db!.isConnected) return null;
    final reservations = await _db!.collection('reservations').find({'space_id': spaceId, 'status': 'active'}).toList();
    
    Map<String, dynamic>? targetRes;
    
    // Önce bu koltuğu içeren rezervasyonu arayalım
    for (var res in reservations) {
      if (res['seats'] != null && (res['seats'] as List).contains(seatIndex)) {
        targetRes = res;
        break;
      }
    }
    
    // Eğer bulamazsak, eski data (seats dizisi olmayan) olabilir. İlk bulduğumuz aktif rezervasyonu döndürelim (fallback).
    if (targetRes == null && reservations.isNotEmpty) {
      targetRes = reservations.first;
    }
    
    if (targetRes != null) {
       final user = await _db!.collection('users').findOne({'id': targetRes['user_id']});
       return {
          'reservation': targetRes,
          'user': user,
       };
    }

    return null;
  }

  Future<void> checkoutSeat(String spaceId, int seatIndex, String reservationId) async {
    if (_db == null || !_db!.isConnected) return;
    
    // 1. Remove seat from space occupied_seats
    final space = await _db!.collection('spaces').findOne({'id': spaceId});
    if (space != null) {
      List<int> currentOccupied = [];
      if (space['occupied_seats'] != null) {
        for (var seat in space['occupied_seats']) {
          currentOccupied.add(seat as int);
        }
      }
      currentOccupied.remove(seatIndex);
      await updateSpace(spaceId, {'\$set': {'occupied_seats': currentOccupied}});
    }

    // 2. Mark reservation as completed (only if we have a real reservation id)
    if (reservationId != 'mock_res_id') {
      await updateReservation(reservationId, {'\$set': {'status': 'completed'}});
    }
  }
  
  Future<List<Map<String, dynamic>>> getReservations() => _getGeneric('reservations');
  
  Future<List<Map<String, dynamic>>> getAdminRecentBookings({String? spaceId}) async {
    if (_db == null || !_db!.isConnected) return [];
    
    final query = spaceId != null ? {'space_id': spaceId} : {};
    final reservations = await _db!.collection('reservations').find(query).toList();
    
    final users = await _db!.collection('users').find().toList();
    final userMap = {for (var user in users) user['id']: user['name']};
    
    final spaces = await _db!.collection('spaces').find().toList();
    final spaceMap = {for (var space in spaces) space['id']: space['name']};

    final List<Map<String, dynamic>> result = [];
    for (var res in reservations) {
      final userName = userMap[res['user_id']] ?? "Bilinmeyen Öğrenci";
      final spaceName = spaceMap[res['space_id']] ?? "Bilinmeyen Mekan";
      
      DateTime pTime;
      try {
        pTime = DateTime.parse(res['start_time']);
      } catch (e) {
        pTime = DateTime.now();
      }
      
      final dtEnd = DateTime.tryParse(res['end_time'] ?? '') ?? DateTime.now();
      final dur = dtEnd.difference(pTime).inHours;

      result.add({
        ...res,
        "name": userName,
        "user_name": userName,
        "space_name": spaceName,
        "detail": "$spaceName ($dur Saat)",
        "time": "${pTime.day}/${pTime.month} ${pTime.hour.toString().padLeft(2, '0')}:${pTime.minute.toString().padLeft(2, '0')}",
        "raw_time": pTime,
        "status": "login", // Green icon in UI
        "space_id": res['space_id']
      });
    }

    result.sort((a, b) => (b['raw_time'] as DateTime).compareTo(a['raw_time'] as DateTime));
    return result;
  }

  Future<List<Map<String, dynamic>>> getUserReservations(String userId) async {
    if (_db == null || !_db!.isConnected) return [];
    
    // Kullanıcının rezervasyonlarını çek
    final reservations = await _db!.collection('reservations').find({'user_id': userId}).toList();
    
    // Mekan id'leri ile mekan isimlerini eşleştirmek (Join) için tüm mekanları çek
    final spaces = await _db!.collection('spaces').find().toList();
    final spaceMap = {for (var space in spaces) space['id']: space['name']};

    // Rezervasyon verisine mekan ismini string olarak entegre et
    return reservations.map((res) {
      final spaceId = res['space_id'];
      final spaceName = spaceMap[spaceId] ?? 'Bilinmeyen Mekan';
      
      // Mongo'dan dönen veriler read-only veya modifiye edilemez olabilir diye yeni map dönüyoruz
      return {
        ...res,
        'space_name': spaceName,
      };
    }).toList();
  }

  Future<void> updateReservation(String id, Map<String, dynamic> modifier) => _updateGeneric('reservations', {'id': id}, modifier);
  Future<void> deleteReservation(String id) => _deleteGeneric('reservations', {'id': id});

  // ==========================================
  // SESSIONS (Odak Modu Seansları)
  // Schema: id, user_id, duration_minutes, date.
  // ==========================================
  Future<void> insertSession({required String userId, required int durationMinutes, required DateTime date}) async {
    final Map<String, dynamic> data = {
      'id': ObjectId().toHexString(),
      'user_id': userId,
      'duration_minutes': durationMinutes,
      'date': date.toIso8601String(),
    };
    await _insertGeneric('sessions', data);
  }

  Future<List<Map<String, dynamic>>> getSessions() => _getGeneric('sessions');
  Future<void> updateSession(String id, Map<String, dynamic> modifier) => _updateGeneric('sessions', {'id': id}, modifier);
  Future<void> deleteSession(String id) => _deleteGeneric('sessions', {'id': id});

  // ==========================================
  // REVIEWS (Yorumlar ve Değerlendirmeler)
  // Schema: id, user_id, space_id, rating, comment, date.
  // ==========================================
  Future<void> insertReview({required String userId, required String spaceId, required int rating, required String comment}) async {
    final Map<String, dynamic> data = {
      'id': ObjectId().toHexString(),
      'user_id': userId,
      'space_id': spaceId,
      'rating': rating,
      'comment': comment,
      'date': DateTime.now().toIso8601String(),
    };
    await _insertGeneric('reviews', data);
  }

  Future<List<Map<String, dynamic>>> getSpaceReviews(String spaceId) async {
    if (_db == null || !_db!.isConnected) return [];
    return await _db!.collection('reviews').find({'space_id': spaceId}).toList();
  }
  
  Future<void> deleteReview(String id) => _deleteGeneric('reviews', {'id': id});

  // ==========================================
  // FAVORITES / LIKES (Beğeniler)
  // Schema: id, user_id, space_id, date.
  // ==========================================
  Future<void> addFavorite({required String userId, required String spaceId}) async {
    final Map<String, dynamic> data = {
      'id': ObjectId().toHexString(),
      'user_id': userId,
      'space_id': spaceId,
      'date': DateTime.now().toIso8601String(),
    };
    await _insertGeneric('favorites', data);
  }

  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    if (_db == null || !_db!.isConnected) return [];
    return await _db!.collection('favorites').find({'user_id': userId}).toList();
  }

  Future<void> removeFavorite(String userId, String spaceId) => _deleteGeneric('favorites', {'user_id': userId, 'space_id': spaceId});

  // ==========================================
  // DIRECT MONGODB DRIVER KULLANIMI (Eski yapıların kırılmaması için)
  // ==========================================
  Future<void> _insertGeneric(String col, Map<String, dynamic> data) async {
    if (_db == null || !_db!.isConnected) return;
    await _db!.collection(col).insert(data);
  }

  Future<List<Map<String, dynamic>>> _getGeneric(String col) async {
    if (_db == null || !_db!.isConnected) return [];
    return await _db!.collection(col).find().toList();
  }

  Future<void> _updateGeneric(String col, Map<String, dynamic> selector, Map<String, dynamic> modifier) async {
    if (_db == null || !_db!.isConnected) return;
    await _db!.collection(col).update(selector, modifier);
  }

  Future<void> _deleteGeneric(String col, Map<String, dynamic> selector) async {
    if (_db == null || !_db!.isConnected) return;
    await _db!.collection(col).remove(selector);
  }

  Future<void> insertData(String collectionName, Map<String, dynamic> data) => _insertGeneric(collectionName, data);
  Future<List<Map<String, dynamic>>> getData(String collectionName) => _getGeneric(collectionName);
  Future<void> updateData(String collectionName, Map<String, dynamic> selector, Map<String, dynamic> modifier) => _updateGeneric(collectionName, selector, modifier);
  Future<void> deleteData(String collectionName, Map<String, dynamic> selector) => _deleteGeneric(collectionName, selector);

  Future<void> close() async {
    await _db?.close();
  }
}
