import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/screens/login_selection_screen.dart';
import 'presentation/screens/main_student_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'core/global_state.dart';
import 'data/services/mongodb_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudySpaceApp());
}

class StudySpaceApp extends StatefulWidget {
  const StudySpaceApp({super.key});

  @override
  State<StudySpaceApp> createState() => _StudySpaceAppState();
}

class _StudySpaceAppState extends State<StudySpaceApp> {
  final GlobalState globalState = GlobalState();

  @override
  void initState() {
    super.initState();
    globalState.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySpace Marketplace',
      debugShowCheckedModeBanner: false,
      themeMode: globalState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Pastel Blue/Grey
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E2630), // Pastel Dark
        cardColor: const Color(0xFF2A3644),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A3644),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent.shade100,
          surface: const Color(0xFF2A3644),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String _statusMessage = "Sunucuya bağlanıyor...";

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final mongoService = MongoDBService();
      await mongoService.connect().timeout(const Duration(seconds: 15));
      await mongoService.seedData();

      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('auth_role');
      final userId = prefs.getString('auth_user_id');

      if (role != null && userId != null) {
        final db = MongoDBService().db;
        if (db != null && db.isConnected) {
          final user = await db.collection('users').findOne({'id': userId});
          if (user != null) {
            GlobalState().loginUser(user);
            if (mounted) {
              if (role == 'admin') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainStudentScreen()));
              }
              return;
            }
          }
        }
      }
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginSelectionScreen()));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Veritabanı Bağlantı Hatası!\nLütfen MongoDB IP izinlerinizi (Network Access) kontrol edin veya internet bağlantınızı doğrulayın.\n\nHata: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_statusMessage.contains('Hata')) const CircularProgressIndicator(),
              if (_statusMessage.contains('Hata')) const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                _statusMessage, 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: 16, 
                  color: _statusMessage.contains('Hata') ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}