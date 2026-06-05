import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/lotes_screen.dart';
import 'package:frontend/screens/reportes_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/screens/home_screen.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int get selectedIndex {
  final puedeVerReportes =
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo';

  return puedeVerReportes ? 3 : 2;
}
  bool _pressed = false;
  String nombre = '';
  String correo = '';
  String rol = '';
  String cargo = '';

  @override
  void initState() {
  super.initState();
  _cargarDatosSesion();
}

  Future<void> _cargarDatosSesion() async {
    final datos = await SessionService.getDatosSesion();
    if (!mounted) return;
    setState(() {
      nombre = datos['nombre'] ?? '';
      correo = datos['correo'] ?? '';
      rol = datos['rol'] ?? '';
      cargo = datos['cargo'] ?? '';
    });
  }

  Future<void> logout(BuildContext context) async {
    await SessionService.cerrarSesion();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) async {

  final bool puedeVerReportes =
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo';

  if (index == 0) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ),
    (route) => false,
  );
  return;
}

  if (!mounted) return;

  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LotesScreen(),
      ),
    );
    return;
  }

  if (puedeVerReportes) {

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ReportesScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }

  } else {

    // Para usuarios sin acceso a reportes,
    // el índice 2 es Perfil.
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {

    final ancho = MediaQuery.of(context).size.width;
    
    final inicial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: const BoxDecoration(
              color: Color(0xFF6B7F66),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('Perfil',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          CircleAvatar(
            radius: ancho < 600 ? 45 : 60,
            backgroundColor: const Color(0xFF6B7F66),
            child: Text(
              inicial,
              style: const TextStyle(
                  fontSize: 38,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          Text(nombre, style: TextStyle
          (fontSize: ancho < 600 ? 20 : 24, fontWeight: FontWeight.bold,),
          ),
          Text(
            correo.isNotEmpty ? correo : 'Sin correo registrado',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          if (rol.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: rol == 'admin'
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rol.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rol == 'admin'
                        ? Colors.green.shade800
                        : Colors.blue.shade800),
              ),
            ),

          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _cardItem(Icons.email_outlined, 'Correo', correo),
                  const SizedBox(height: 10),
                  _cardItem(Icons.badge_outlined, 'Rol', rol.isNotEmpty ? rol : '-'),
                  const SizedBox(height: 10),
                  _cardItem(Icons.work_outline, 'Cargo', cargo.isNotEmpty ? cargo : '-',),
                  const SizedBox(height: 10),
                  _cardItem(Icons.edit_outlined, 'Editar perfil', null,
                      onTap: () {}),
                  const SizedBox(height: 10),
                  _cardItem(Icons.sync, 'Sincronizar datos', null,
                      onTap: () {}),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: () => logout(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _pressed
                            ? Colors.red.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              offset: const Offset(2, 2))
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Cerrar sesión',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: AppBottomNav(
  currentIndex: selectedIndex,
  onTabSelected: _onItemTapped,
  puedeVerReportes:
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo',
),
    );
  }

  Widget _cardItem(IconData icon, String label, String? value,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 5,
                offset: const Offset(2, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7F66)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (value != null && value.isNotEmpty)
                    Text(value,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
