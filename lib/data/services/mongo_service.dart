import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  // Singleton pattern for accessing the service
  static final MongoService _instance = MongoService._internal();
  
  factory MongoService() {
    return _instance;
  }
  
  MongoService._internal();

  Db? _db;

  Future<void> connect() async {
    try {
      // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/desktop
      String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      
      // Connection string using the credentials from docker-compose.yml
      String url = 'mongodb://root:example@$host:27017/studyspace?authSource=admin';
      
      _db = await Db.create(url);
      await _db?.open();
      print('Connected to MongoDB successfully at $url');
    } catch (e) {
      print('Error connecting to MongoDB: $e');
    }
  }

  Db? get db => _db;

  DbCollection? getCollection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      print('Warning: Database is not connected.');
      return null;
    }
    return _db?.collection(collectionName);
  }
  
  Future<void> close() async {
    await _db?.close();
    print('MongoDB connection closed.');
  }
}
