import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/utils/mensajes.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'lotes_screen.dart';
import 'profile_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String formatearMes(String mes) {
    const meses = {
      "01": "Ene",
      "02": "Feb",
      "03": "Mar",
      "04": "Abr",
      "05": "May",
      "06": "Jun",
      "07": "Jul",
      "08": "Ago",
      "09": "Sep",
      "10": "Oct",
      "11": "Nov",
      "12": "Dic",
    };

    final m = mes.substring(5);
    return meses[m] ?? m;
  }

  String formatearFechaCorta(String fecha) {
  final f = DateTime.parse(fecha);
  return "${f.day}/${f.month}";
}

  List mensual = [];
  List calidad = [];
  List porFecha = [];

  double total = 0;
  String? mejorCultivo;

  DateTime? desde;
  DateTime? hasta;

  String? token;
  final int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    initApp();
  }

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
      total = double.tryParse(t['total_kg']?.toString() ?? '0') ?? 0;

      mejorCultivo =
          "${mejor['tipo_cultivo'] ?? ''} - ${mejor['variedad'] ?? ''}";
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

  // ================= NAV =================
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context);
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LotesScreen(nombreUsuario: "Usuario"),
        ),
      );
    }

    if (index == 2) return;

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(nombre: "Usuario", correo: ""),
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),

      body: Column(
        children: [
          // HEADER (igual a lotes)
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final nombre = prefs.getString('nombre') ?? '';
                          final correo = prefs.getString('correo') ?? '';
                          final rol = prefs.getString('rol') ?? '';

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(
                                nombre: nombre,
                                correo: correo,
                                rol: rol,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                      const Icon(Icons.bar_chart, color: Colors.white),
                      const SizedBox(width: 10),
                      const Text("Cafe Nova",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const Text("Usuario",
                      style: TextStyle(color: Colors.white)),
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
                    "Resumen",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  card("📊 Producción Total", "$total kg"),
                  card("🏆 Mejor Cultivo", mejorCultivo ?? "N/A"),

                  const SizedBox(height: 15),

                  // PDF
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await ApiService.descargarPDF(token!);
                  
                      if (ok) {
                        Mensajes.mostrar(context, "PDF descargado correctamente");
                      } else {
                        Mensajes.mostrar(context, "Error al descargar PDF", esError: true);
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Descargar PDF"),
                  ),

                  const SizedBox(height: 25),

                  const Text("📅 Producción por Mes"),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < mensual.length) {
                                    return Text(
                                      formatearMes(mensual[index]['mes']),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          barGroups: mensual.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (e.value['total_kg'] ?? 0).toDouble(),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text("☕ Calidad del Café"),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: calidad.map((e) {
                            return PieChartSectionData(
                              color: e['calidad'] == 'Alta'
                                  ? Colors.green
                                  : e['calidad'] == 'Media'
                                  ? Colors.orange
                                  : Colors.red,
                              value: (e['total_kg'] ?? 0).toDouble(),
                              title: "${e['calidad']}\n${e['total_kg']}kg",
                              radius: 60,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

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

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < porFecha.length) {
                                      String fecha = porFecha[index]['fecha'];
                                      return Text(
                                        formatearFechaCorta(fecha),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                dotData: FlDotData(show: true),
                                barWidth: 3,
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
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // 🔻 NAV IGUAL A LOTES
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6B7F66),
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
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

  // ================= CARD =================
  Widget card(String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(valor),
        ],
      ),
    );
  }
}
