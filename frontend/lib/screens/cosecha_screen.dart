import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/reportes_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/lotes_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _calidadesCosecha = ['Premium', 'Alta', 'Media', 'Baja'];

class CosechaScreen extends StatefulWidget {
  const CosechaScreen({super.key});

  @override
  State<CosechaScreen> createState() => _CosechaScreenState();
}

class _CosechaScreenState extends State<CosechaScreen> {
  List cosechas = [];
  List cultivos = [];

  final cantidadController = TextEditingController();
  final fechaController = TextEditingController();

  DateTime? fechaSeleccionada;
  int? idCultivo;
  int? idEditando;
  String? token;
  String correo = '';
  String nombre = '';
  String? calidadSeleccionada;

  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    token = await SessionService.getToken();
    correo = await SessionService.getCorreo() ?? '';
    nombre = await SessionService.getNombre() ?? '';
    if (token == null) return;
    await Future.wait([obtenerCultivos(), obtenerCosechas()]);
  }

  Future<void> obtenerCultivos() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/cultivo'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() => cultivos = jsonDecode(res.body));
    }
  }

  Future<void> obtenerCosechas() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/cosecha'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() => cosechas = jsonDecode(res.body));
    }
  }

  Future<void> guardarCosecha() async {
    if (idCultivo == null) {
      _mostrarError('Selecciona un cultivo');
      return;
    }
    // ✅ Validación numérica de cantidad
    final cantText = cantidadController.text.trim();
    if (cantText.isEmpty || double.tryParse(cantText) == null) {
      _mostrarError('La cantidad debe ser un número válido (ej: 25.5)');
      return;
    }
    if (calidadSeleccionada == null) {
      _mostrarError('Selecciona la calidad');
      return;
    }
    if (fechaController.text.isEmpty) {
      _mostrarError('Selecciona la fecha de cosecha');
      return;
    }

    final url = idEditando == null
        ? 'http://localhost:3000/cosecha'
        : 'http://localhost:3000/cosecha/$idEditando';
    final method = idEditando == null ? http.post : http.put;

    final res = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_cultivo': idCultivo,
        'fecha_cosecha': fechaController.text,
        'cantidad_kg': double.parse(cantText),
        'calidad': calidadSeleccionada,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      limpiarCampos();
      if (mounted) Navigator.pop(context);
      obtenerCosechas();
    }
  }

  Future<void> eliminarCosecha(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/cosecha/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    obtenerCosechas();
  }

  void limpiarCampos() {
    cantidadController.clear();
    fechaController.clear();
    idCultivo = null;
    fechaSeleccionada = null;
    calidadSeleccionada = null;
    idEditando = null;
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatearFecha(String fecha) {
    try {
      final f = DateTime.parse(fecha);
      return '${f.day}/${f.month}/${f.year}';
    } catch (_) {
      return fecha;
    }
  }

  String _nombreCultivo(int id) {
    try {
      final c = cultivos.firstWhere((c) => c['id_cultivo'] == id);
      return '${c['tipo_cultivo']} · ${c['variedad']}';
    } catch (_) {
      return 'Cultivo $id';
    }
  }

  void mostrarFormulario({Map? cosecha}) {
    if (cosecha == null) {
      limpiarCampos();
    } else {
      idEditando = cosecha['id_cosecha'];
      cantidadController.text = cosecha['cantidad_kg'].toString();
      calidadSeleccionada = _calidadesCosecha.contains(cosecha['calidad'])
          ? cosecha['calidad']
          : null;
      fechaController.text = cosecha['fecha_cosecha'] ?? '';
      idCultivo = cosecha['id_cultivo'];
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            cosecha == null ? 'Nueva Cosecha' : 'Editar Cosecha',
            style: const TextStyle(
                color: Color(0xFF6B7F66), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Cultivo ───────────────────────────────────────────────────
                DropdownButtonFormField<int>(
                  initialValue: idCultivo,
                  hint: const Text('Seleccionar Cultivo'),
                  isExpanded: true,
                  decoration: _inputDeco('Cultivo'),
                  items: cultivos.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem(
                      value: c['id_cultivo'] as int,
                      child: Text(
                          '${c['tipo_cultivo']} · ${c['variedad']}'),
                    );
                  }).toList(),
                  onChanged: (v) => setD(() => idCultivo = v),
                ),
                const SizedBox(height: 12),

                // ── Cantidad ✅ solo números ───────────────────────────────────
                TextField(
                  controller: cantidadController,
                  decoration: _inputDeco('Cantidad (kg)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Calidad ───────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: calidadSeleccionada,
                  hint: const Text('Calidad'),
                  isExpanded: true,
                  decoration: _inputDeco('Calidad'),
                  items: _calidadesCosecha
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setD(() => calidadSeleccionada = v),
                ),
                const SizedBox(height: 12),

                // ── Fecha ─────────────────────────────────────────────────────
                TextField(
                  controller: fechaController,
                  readOnly: true,
                  decoration: _inputDeco('Fecha de cosecha').copyWith(
                    suffixIcon: const Icon(Icons.calendar_month,
                        color: Color(0xFF6B7F66)),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF6B7F66)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setD(() {
                        fechaSeleccionada = picked;
                        fechaController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                limpiarCampos();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardarCosecha,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7F66)),
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Cosecha'),
        content: const Text('¿Seguro que deseas eliminar esta cosecha?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              eliminarCosecha(id);
              Navigator.pop(context);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _calidadColor(String? cal) {
    switch (cal) {
      case 'Premium':
        return Colors.purple;
      case 'Alta':
        return Colors.green;
      case 'Media':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _onItemTapped(int index) async {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('nombre') ?? nombre;
    final c = prefs.getString('correo') ?? correo;
    if (!mounted) return;
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => LotesScreen(nombreUsuario: n)));
    } else if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ReportesScreen()));
    } else if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => ProfileScreen(nombre: n, correo: c)));
    }
  }

  Widget _cosechaCard(Map c) {
    final calidad = c['calidad'];
    final color = _calidadColor(calidad);

    return GestureDetector(
      onTap: () => mostrarFormulario(cosecha: c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.agriculture, color: Color(0xFF6B7F66)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _nombreCultivo(c['id_cultivo']),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              // Badge de calidad
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(calidad ?? '-',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => confirmarEliminacion(c['id_cosecha']),
              ),
            ]),
            const Divider(height: 12),
            Row(children: [
              _infoChip(Icons.scale, '${c['cantidad_kg'] ?? '-'} kg'),
              const SizedBox(width: 16),
              _infoChip(
                Icons.calendar_today,
                c['fecha_cosecha'] != null
                    ? _formatearFecha(c['fecha_cosecha'])
                    : '-',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7F66)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

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
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.agriculture, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Cosechas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis Cosechas',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (cosechas.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No hay cosechas registradas'),
                      ),
                    )
                  else
                    ...cosechas.map((c) => _cosechaCard(c)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B7F66),
        onPressed: () => mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
      // ✅ Barra de navegación global reutilizable
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTabSelected: _onItemTapped,
      ),
    );
  }
}
