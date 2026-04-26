import 'package:flutter/material.dart';
import 'presentation/screens/login_selection_screen.dart';
import 'core/global_state.dart';
import 'data/services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mongoService = MongoDBService();
  await mongoService.connect();
  await mongoService.seedData(); // Tabloları test verileriyle doldurur
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
      home: const LoginSelectionScreen(),
    );
  }
}