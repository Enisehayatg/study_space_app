import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations.dart';
import '../../data/services/mongodb_service.dart';
import '../../core/global_state.dart';
import 'main_student_screen.dart';

class StudentAuthScreen extends StatefulWidget {
  const StudentAuthScreen({super.key});

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Controllers for Login
  final TextEditingController _loginEmailCtrl = TextEditingController();
  final TextEditingController _loginPassCtrl = TextEditingController();

  // Controllers for Register
  final TextEditingController _regNameCtrl = TextEditingController();
  final TextEditingController _regEmailCtrl = TextEditingController();
  final TextEditingController _regPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('student_email');
    final savedPass = prefs.getString('student_password');
    if (savedEmail != null && savedPass != null) {
      setState(() {
        _loginEmailCtrl.text = savedEmail;
        _loginPassCtrl.text = savedPass;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showSnackBar("Lütfen e-posta ve şifrenizi girin.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = MongoDBService().db;
      if (db == null || !db.isConnected) {
        _showSnackBar("Veritabanı bağlantısı kurulamadı. (Docker çalışıyor mu?)", isError: true);
        return;
      }

      final collection = db.collection('users');
      final user = await collection.findOne({
        'email': email,
        'password': pass,
      });

      if (user != null) {
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_email', email);
          await prefs.setString('student_password', pass);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('student_email');
          await prefs.remove('student_password');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_role', 'student');
        await prefs.setString('auth_user_id', user['id']);

        GlobalState().loginUser(user);
        _showSnackBar("Giriş Başarılı! Hoş geldin, ${user['name']}");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            BouncePageRoute(page: const MainStudentScreen()),
          );
        }
      } else {
        _showSnackBar("E-posta veya şifre hatalı.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Giriş sırasında hata oluştu: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = MongoDBService().db;
      if (db == null || !db.isConnected) {
        _showSnackBar("Veritabanı bağlantısı yok.", isError: true);
        return;
      }

      final collection = db.collection('users');
      
      final existingUser = await collection.findOne({'email': email});
      if (existingUser != null) {
         _showSnackBar("Bu e-posta adresi zaten kayıtlı.", isError: true);
         return;
      }

      await MongoDBService().insertUser(
        name: name,
        email: email,
        role: 'student',
        password: pass,
      );

      _showSnackBar("Kayıt başarılı! Lütfen giriş yapın.");
      
      // Temizle ve Login sekmesine geç
      _regNameCtrl.clear();
      _regEmailCtrl.clear();
      _regPassCtrl.clear();
      _tabController.animateTo(0);
      _loginEmailCtrl.text = email;
      
    } catch (e) {
      _showSnackBar("Kayıt sırasında hata: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF334E68)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Icon(Icons.school, size: 64, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  "Öğrenci Portalı",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334E68),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sana en uygun çalışma alanlarını keşfetmek için hesabına giriş yap.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                
                // TabBar Alanı
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ]
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.blueAccent.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      Tab(text: "Giriş Yap"),
                      Tab(text: "Kayıt Ol"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form Alanı
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildRegisterForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          label: "E-posta", 
          icon: Icons.email_outlined,
          controller: _loginEmailCtrl,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: "Şifre", 
          icon: Icons.lock_outline, 
          controller: _loginPassCtrl,
          isPassword: true,
        ),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                setState(() {
                  _rememberMe = val ?? false;
                });
              },
            ),
            const Text("Beni Hatırla", style: TextStyle(color: Colors.black87)),
            const Spacer(),
            TextButton(
              onPressed: () { _showSnackBar("Bu özellik yakında eklenecektir."); },
              child: const Text("Şifremi Unuttum?", style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        _buildTextField(
          label: "Ad Soyad", 
          icon: Icons.person_outline,
          controller: _regNameCtrl,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: "E-posta", 
          icon: Icons.email_outlined,
          controller: _regEmailCtrl,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: "Şifre", 
          icon: Icons.lock_outline, 
          controller: _regPassCtrl,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildTextField({
    required String label, 
    required IconData icon, 
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ) 
            : null,
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
