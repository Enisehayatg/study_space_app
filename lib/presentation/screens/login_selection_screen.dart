import 'package:flutter/material.dart';
import 'package:study_space_app/presentation/screens/student_auth_screen.dart';
import 'package:study_space_app/presentation/screens/admin_auth_screen.dart';
import '../../core/animations.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft pastel arka plan
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  "StudySpace'e Hoş Geldin!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:  Color(0xFF334E68)),
                ),
                const SizedBox(height: 8),
                const Text("Sana nasıl yardımcı olabiliriz?", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 48),
                
                // Öğrenci Butonu
                _buildSelectionCard(
                  context,
                  title: "Öğrenciyim",
                  subtitle: "Sessiz çalışma alanı arıyorum",
                  icon: Icons.school_outlined,
                  color: Colors.lightBlue.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      BouncePageRoute(page: const StudentAuthScreen()),
                    );
                  }
                ),
                
                const SizedBox(height: 20),
                
                // Mekan Sahibi Butonu
                _buildSelectionCard(
                  context,
                  title: "Mekan Sahibiyim",
                  subtitle: "Boş kontenjanımı değerlendirmek istiyorum",
                  icon: Icons.business_outlined,
                  color: Colors.teal.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      BouncePageRoute(page: const AdminAuthScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(BuildContext context, 
      {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black54),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}