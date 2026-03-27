import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screens/finca_screen.dart';
import 'package:frontend/screens/lotes_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/utils/mensajes.dart';

class HomeScreen extends StatefulWidget {
  final String nombre;
  final String correo;
  final String token;

  const HomeScreen({
    super.key,
    required this.nombre,
    required this.correo,
    required this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List lotes = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    obtenerLotes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Mensajes.mostrar(context, 'Bienvenido ${widget.nombre}');
    });
  }

  Future<void> obtenerLotes() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/lotes'));

      if (response.statusCode == 200) {
        setState(() {
          lotes = jsonDecode(response.body);
        });
      } else {
        Mensajes.mostrar(context, 'Error al cargar lotes', esError: true);
      }
    } catch (e) {
      Mensajes.mostrar(context, 'Error de conexión', esError: true);
    }
  }

  Future<void> irALotes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LotesScreen()),
    );

    setState(() {
      _selectedIndex = 0;
    });
  }

  Future<void> irAFincas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FincasScreen()),
    );

    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            nombre: widget.nombre,
            correo: widget.correo,
            token: widget.token,
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      irALotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF6B7F66),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: "Lotes"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reportes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.eco, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Cafe Nova",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.nombre,
                          style: const TextStyle(color: Colors.white)),
                      const Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: Colors.greenAccent),
                          SizedBox(width: 5),
                          Text("Conectado",
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      dashboardCard("Fincas", Icons.park, irAFincas),
                      dashboardCard("Lotes", Icons.eco, irALotes),
                      dashboardCard("Empleados", Icons.people, () {}),
                      dashboardCard("Inventario", Icons.inventory, () {}),
                      dashboardCard("Reportes", Icons.bar_chart, () {}),
                      dashboardCard("IA", Icons.smart_toy, () {}),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.grid_view, size: 18),
                                SizedBox(width: 8),
                                Text("Mis Lotes",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            GestureDetector(
                              onTap: irALotes,
                              child: const Icon(Icons.arrow_forward_ios, size: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        lotes.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text("No hay lotes disponibles"),
                              )
                            : Column(
                                children: lotes.map((lote) {
                                  return loteItem(
                                    lote['nombre_lote'] ?? '',
                                    lote['nombre_finca'] ?? '',
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget dashboardCard(String titulo, IconData icono, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 35, color: const Color(0xFF6B7F66)),
            const SizedBox(height: 8),
            Text(titulo, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget loteItem(String nombre, String finca) {
    return GestureDetector(
      onTap: irALotes,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1ED),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF6B7F66), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text("$nombre - $finca")),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}