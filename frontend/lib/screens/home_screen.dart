import 'package:flutter/material.dart';
import 'package:frontend/screens/IA_screen.dart';
import 'package:frontend/screens/cosecha_screen.dart';
import 'package:frontend/screens/employees_screen.dart';
import 'package:frontend/screens/reportes_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/finca_screen.dart';
import 'package:frontend/screens/lotes_screen.dart';
import 'package:frontend/screens/inventario_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/utils/mensajes.dart';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/cultivos_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {

  final bool mostrarBienvenida;

  const HomeScreen({
    super.key,
    this.mostrarBienvenida = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List lotes = [];
  final int _selectedIndex = 0;

  String? token;

  String nombre = '';
  String correo = '';
  String rol = '';
  String cargo = '';

  int idFinca = 0;
  int idEmpleado = 0;

  String correoResuelto = '';

  Future<void> cargarSesion() async {

    final datos = await SessionService.getDatosSesion();

    if (!mounted) return;

    setState(() {
  nombre = datos['nombre'] ?? '';
  correo = datos['correo'] ?? '';
  rol = datos['rol'] ?? '';

  cargo = rol == 'admin'
      ? 'Administrador'
      : (datos['cargo'] ?? '');

  idFinca = datos['id_finca'] ?? 0;
  idEmpleado = datos['id_empleado'] ?? 0;
});
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
  await cargarSesion();
  await initApp();
});

    if (widget.mostrarBienvenida) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Mensajes.mostrar(
            context,
            'Bienvenido $nombre ($rol)',
          );
        }
      });
    }
  }


  Future<void> initApp() async {
    token = await SessionService.getToken();
    final correoGuardado = await SessionService.getCorreo();
    if (correoGuardado != null && correoGuardado.isNotEmpty) {
      setState(() => correoResuelto = correoGuardado);
    }
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }
    await obtenerLotes();
  }

  Future<void> obtenerLotes() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/lotes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() => lotes = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  Future<void> irALotes() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LotesScreen()));
    await obtenerLotes();
  }

  Future<void> irAFincas() async {
    if (rol != 'admin') {
      Mensajes.mostrar(context, 'No tienes permisos', esError: true);
      return;
    }
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FincasScreen()));
  }

  Future<void> irAEmpleados() async {
    if (rol != 'admin') {
      Mensajes.mostrar(context, 'No tienes permisos', esError: true);
      return;
    }
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EmpleadosScreen()));
  }

  Future<void> irAReportes() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ReportesScreen()));
  }

  Future<void> irACosechas() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => CosechaScreen()));
  }

  Future<void> irAIA() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const IAScreen()));
  }

  Future<void> irACultivos() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CultivoScreen()));
  }

  void _onItemTapped(int index) {
    if (index == 0) return; // ya estás en home
    if (index == 1) { irALotes(); return; }
    if (index == 2) { irAReportes(); return; }
    if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => 
          const ProfileScreen()
          )
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color rolColor = rol == 'admin' ? Colors.green : Colors.blue;
    final cargoActual = cargo;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      // ✅ Widget reutilizable
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTabSelected: _onItemTapped,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              color: rolColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [
                    Icon(Icons.eco, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Cafe Nova',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ]),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      if (correoResuelto.isNotEmpty)
                        Text(correoResuelto,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      const Row(children: [
                        Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text('Conectado',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ],
                  ),
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
                  const Text('Dashboard',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      if (rol == 'admin')
                        _dashCard('Fincas', Icons.park, irAFincas),
                      _dashCard('Lotes', Icons.eco, irALotes),
                      if (rol == 'admin')
                        _dashCard('Empleados', Icons.people, irAEmpleados),
                      if (rol == 'admin')
                        _dashCard(
                          'Inventario',
                          Icons.inventory,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InventarioScreen(),
                              ),
                            );
                          },
                        ),
                      if (rol == 'admin')
                        _dashCard('Reportes', Icons.bar_chart, irAReportes,),
                      if (cargo == 'Auxiliar Administrativo')
                        _dashCard('Inventario', Icons.inventory, () {Navigator.push(context, MaterialPageRoute(builder: (_) =>const InventarioScreen(),),);},),
                      if (rol != 'admin' && cargo == 'Operario de Campo')
                        _dashCard('Cultivos', Icons.spa, irACultivos),
                      if (rol != 'admin' && cargo == 'Operario de Campo')
                        _dashCard('Lotes', Icons.eco, irALotes),
                      if (cargoActual == 'Fumigador')
                        _dashCard('Cultivos', Icons.spa, irACultivos),
                      if (cargoActual == 'Fumigador')
                        _dashCard('Lotes', Icons.eco, irALotes),
                      if (cargoActual == 'Fumigador')
                        _dashCard('Reportes', Icons.bar_chart, irAReportes),
                      if (cargo == 'Recolector')
                        _dashCard('Cosechas', Icons.agriculture, irACosechas),
                      if (cargo == 'Recolector')
                        _dashCard('Lotes', Icons.eco, irALotes),
                      if (cargo == 'Pesador')
                        _dashCard('Reportes', Icons.bar_chart, irAReportes),
                      if (cargo == 'Operario de Procesamiento')
                        _dashCard('Cultivos', Icons.spa, irACultivos),
                      if (cargo == 'Operario de Procesamiento')
                        _dashCard('Reportes', Icons.bar_chart, irAReportes),
                      if (rol == 'admin')
                        _dashCard('Cosechas', Icons.agriculture, irACosechas),
                        _dashCard('IA', Icons.psychology, irAIA),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(children: [
                            Icon(Icons.grid_view, size: 18),
                            SizedBox(width: 8),
                            Text('Mis Lotes',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                          GestureDetector(
                              onTap: irALotes,
                              child:
                                  const Icon(Icons.arrow_forward_ios, size: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      lotes.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: Text('No hay lotes disponibles'))
                          : Column(
                              children: lotes
                                  .map((l) => _loteItem(
                                      l['nombre_lote'] ?? '',
                                      l['nombre_finca'] ?? ''))
                                  .toList()),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashCard(String titulo, IconData icono, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, size: 35, color: const Color(0xFF6B7F66)),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _loteItem(String nombre, String finca) {
    return GestureDetector(
      onTap: irALotes,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F1ED),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.location_on, color: Color(0xFF6B7F66), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('$nombre — $finca')),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ]),
      ),
    );
  }
}