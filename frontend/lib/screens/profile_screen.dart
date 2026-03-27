import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String nombre;
  final String correo;
  final String token;

  const ProfileScreen({
    super.key,
    required this.nombre,
    required this.correo,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;

  Future<void> logout(BuildContext context) async {
    final url = Uri.parse('http://localhost:3000/logout');

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      );
    } catch (e) {}

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context);
    }
  }

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                  const Text(
                    "Perfil",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          CircleAvatar(
            radius: 50,
            child: Text(
              widget.nombre.isNotEmpty ? widget.nombre[0] : '',
              style: const TextStyle(fontSize: 40),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.nombre,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          Text(widget.correo.isNotEmpty ? widget.correo : 'Sin correo'),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  cardItem(Icons.email, widget.correo, null),

                  const SizedBox(height: 10),

                  cardItem(Icons.home, "Ubicación:", null),

                  const SizedBox(height: 10),

                  cardItem(Icons.edit, "Editar perfil", null),

                  const SizedBox(height: 10),

                  cardItem(Icons.sync, "Sincronizar datos", null),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: () => logout(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _pressed ? Colors.red.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text(
                            "Cerrar sesión",
                            style: TextStyle(color: Colors.red),
                          ),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF6B7F66),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: "Lotes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Reportes",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget cardItem(IconData icon, String text, VoidCallback? onTap) {
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
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7F66)),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}
