import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations.dart';
import '../../data/services/mongodb_service.dart';
import '../../core/global_state.dart';
import 'admin_dashboard_screen.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> with SingleTickerProviderStateMixin {
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
  final TextEditingController _regSpaceNameCtrl = TextEditingController();
  final TextEditingController _regCapacityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('admin_email');
    final savedPass = prefs.getString('admin_password');
    if (savedEmail != null && savedPass != null) {
      if (mounted) {
        setState(() {
          _loginEmailCtrl.text = savedEmail;
          _loginPassCtrl.text = savedPass;
          _rememberMe = true;
        });
      }
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
    _regSpaceNameCtrl.dispose();
    _regCapacityCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.teal.shade700,
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
        _showSnackBar("Veritabanı bağlantısı kurulamadı.", isError: true);
        return;
      }

      final collection = db.collection('users');
      final user = await collection.findOne({
        'email': email,
        'password': pass,
        'role': 'admin',
      });

      if (user != null) {
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('admin_email', email);
          await prefs.setString('admin_password', pass);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('admin_email');
          await prefs.remove('admin_password');
        }

        GlobalState().loginUser(user);
        _showSnackBar("Giriş Başarılı! Hoş geldin Yönetici: ${user['name']}");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            BouncePageRoute(page: const AdminDashboardScreen()),
          );
        }
      } else {
        _showSnackBar("E-posta veya şifre hatalı ya da yetkiniz yok.", isError: true);
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
    final spaceName = _regSpaceNameCtrl.text.trim();
    final capacityText = _regCapacityCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || spaceName.isEmpty || capacityText.isEmpty) {
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
        role: 'admin',
        password: pass,
      );
      
      int capacity = int.tryParse(capacityText) ?? 40;
      
      // Yöneticinin firması adıyla otomatik olarak bir Etüt Merkezi (Space) oluştur ve listele:
      await MongoDBService().insertSpace(
        name: spaceName, 
        location: "Kayıt sırasında adres girilmedi", 
        capacity: capacity, 
        currentOccupancy: 0, 
        amenities: ["wifi", "plug", "silent_zone"], 
        imageUrl: "https://images.unsplash.com/photo-1572005470295-88ff6b553644?q=80&w=600", // Modern ofis fotosu
        occupiedSeats: [],
      );

      _showSnackBar("$name isimli tesisiniz başarıyla oluşturuldu! Lütfen giriş yapın.");
      
      _regNameCtrl.clear();
      _regEmailCtrl.clear();
      _regPassCtrl.clear();
      _regSpaceNameCtrl.clear();
      _regCapacityCtrl.clear();
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
      backgroundColor: const Color(0xFFEAF4F4), // Teal bazlı soft arka plan
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2B4D4B)),
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
                const Center(
                  child: Icon(Icons.business_center, size: 80, color: Colors.teal),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Yönetici Portalı",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B4D4B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Mekanını dijitalleştir ve tüm rezervasyonları kontrol et.",
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
                      color: Colors.teal.shade500,
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
                  height: 480,
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
              activeColor: Colors.teal,
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
              child: const Text("Şifremi Unuttum?", style: TextStyle(color: Colors.teal)),
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
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
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
            label: "Mekan/Tesis Adı", 
            icon: Icons.business,
            controller: _regSpaceNameCtrl,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Toplam Kapasite (Masa Sayısı)", 
            icon: Icons.event_seat,
            controller: _regCapacityCtrl,
            isNumber: true,
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
                backgroundColor: const Color(0xFF2B4D4B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Kayıt Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
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
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
