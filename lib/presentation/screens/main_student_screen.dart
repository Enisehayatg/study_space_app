import 'package:flutter/material.dart';
import 'space_list_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class MainStudentScreen extends StatefulWidget {
  const MainStudentScreen({super.key});

  @override
  State<MainStudentScreen> createState() => _MainStudentScreenState();
}

class _MainStudentScreenState extends State<MainStudentScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SpaceListScreen(),
    const MapScreen(),
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
