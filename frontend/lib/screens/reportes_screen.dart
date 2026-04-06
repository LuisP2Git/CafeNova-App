import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

// 🔥 IMPORTACIONES NECESARIAS
import 'home_screen.dart';
import 'lotes_screen.dart';
import 'profile_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {

  List mensual = [];
  List calidad = [];
  List porFecha = [];

  double total = 0;
  int? mejorCultivo;

  DateTime? desde;
  DateTime? hasta;

  String? token;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  // ================= INIT =================
  Future<void> initApp() async {
    token = await SessionService.getToken();
    if (token == null) return;
    await cargarDatos();
  }

  // ================= DATOS =================
  Future<void> cargarDatos() async {
    final m = await ApiService.getMensual(token!);
    final c = await ApiService.getCalidad(token!);
    final t = await ApiService.getTotal(token!);
    final mejor = await ApiService.getMejor(token!);

    setState(() {
      mensual = m;
      calidad = c;
      total = (t['total_kg'] ?? 0).toDouble();
      mejorCultivo = mejor['id_cultivo'];
    });
  }

  Future<void> cargarPorFecha() async {
    if (desde == null || hasta == null) return;

    final data = await ApiService.getPorFecha(
      token!,
      desde.toString().split(' ')[0],
      hasta.toString().split(' ')[0],
    );

    setState(() {
      porFecha = data;
    });
  }

  // ================= FECHAS =================
  Future<void> seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (esDesde) {
          desde = picked;
        } else {
          hasta = picked;
        }
      });
    }
  }

  // ================= NAV (ARREGLADO) =================
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {

      case 0: // HOME
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              nombre: "Usuario",
              correo: "correo@email.com",
              rol: "admin",
            ),
          ),
        );
        break;

      case 1: // LOTES
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LotesScreen(nombreUsuario: "Usuario"),
          ),
        );
        break;

      case 2:
        // ya estás aquí
        break;

      case 3: // PERFIL
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(
              nombre: "Usuario",
              correo: "correo@email.com",
            ),
          ),
        );
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  // ================= UI =================
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

          // HEADER
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
            child: const SafeArea(
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Reportes",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),

          // CONTENIDO
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Resumen",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 15),

                  card("📊 Producción Total", "$total kg"),
                  card("🏆 Mejor Cultivo", "ID: $mejorCultivo"),

                  const SizedBox(height: 20),

                  const Text("📅 Producción por Mes"),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        barGroups: mensual.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['total_kg'] ?? 0).toDouble(),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text("☕ Calidad del Café"),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: calidad.map((e) {
                          return PieChartSectionData(
                            value: (e['total_kg'] ?? 0).toDouble(),
                            title: e['calidad'],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text("📈 Filtrar por Fechas"),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => seleccionarFecha(true),
                        child: const Text("Desde"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => seleccionarFecha(false),
                        child: const Text("Hasta"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: cargarPorFecha,
                        child: const Text("Filtrar"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (porFecha.isNotEmpty) ...[
                    const Text("Tendencia"),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: porFecha.asMap().entries.map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  (e.value['total_kg'] ?? 0).toDouble(),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // CARD
  Widget card(String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(valor),
      ),
    );
  }
}