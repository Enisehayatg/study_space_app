import 'package:flutter/material.dart';
import 'space_list_screen.dart';
import 'profile_screen.dart';

class MainStudentScreen extends StatefulWidget {
  const MainStudentScreen({super.key});

  @override
  State<MainStudentScreen> createState() => _MainStudentScreenState();
}

class _MainStudentScreenState extends State<MainStudentScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SpaceListScreen(),
    Container(
      color: Colors.blue.shade50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, size: 80, color: Colors.blue.shade300),
                const SizedBox(height: 20),
                const Text(
                  "Elit Eğitim Kurumları",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF334E68)),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Harita entegrasyonu çok yakında aktif olacak.\nŞimdilik konum: Elazığ Merkez",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Keşfet"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Harita"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profilim"),
        ],
      ),
    );
  }
}
