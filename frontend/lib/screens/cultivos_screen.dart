import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/reportes_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/lotes_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

// ─── Constantes de dominio ────────────────────────────────────────────────────
const _estadosCultivo = [
  'Activo',
  'En crecimiento',
  'En floración',
  'Cosechado',
  'Inactivo',
];

const _tiposCafe = ['Arabica', 'Robusta'];

const Map<String, List<String>> _variedadesCafe = {
  'Arabica': [
    'Castillo', 'Colombia', 'Cenicafé 1', 'Tabi', 'Caturra',
    'Typica', 'Bourbon', 'Bourbon Rosado', 'Bourbon Amarillo',
    'Geisha', 'Maragogipe', 'Pacamara', 'Laurina',
  ],
  'Robusta': ['Conilon', 'Robusta mejorado'],
};

class CultivoScreen extends StatefulWidget {
  const CultivoScreen({super.key});

  @override
  State<CultivoScreen> createState() => _CultivoScreenState();
}

class _CultivoScreenState extends State<CultivoScreen> {
  List lotes = [];
  List cultivos = [];
  List<String> variedadesDisponibles = [];

  final variedadController = TextEditingController();
  final fechaController = TextEditingController();

  int? idLote;
  int? idEditando;
  String? token;
  String correo = '';
  String nombre = '';
  String estadoSeleccionado = _estadosCultivo.first;
  String? tipoSeleccionado;

  final int _selectedIndex = 0; // no hay pestaña "Cultivos" — Inicio activo

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {

  final datos = await SessionService.getDatosSesion();

  token = await SessionService.getToken();

  nombre = datos['nombre'] ?? '';
  correo = datos['correo'] ?? '';

  if (token == null) return;

  setState(() {});

  await Future.wait([
    obtenerLotes(),
    obtenerCultivos(),
  ]);
}

  Future<void> obtenerLotes() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/lotes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() => lotes = jsonDecode(res.body));
    }
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

  Future<void> guardarCultivo() async {
    if (idLote == null) {
      _mostrarError('Selecciona un lote');
      return;
    }
    if (tipoSeleccionado == null) {
      _mostrarError('Selecciona el tipo de café');
      return;
    }
    if (variedadController.text.isEmpty) {
      _mostrarError('Selecciona la variedad');
      return;
    }
    if (fechaController.text.isEmpty) {
      _mostrarError('Selecciona la fecha de siembra');
      return;
    }

    final url = idEditando == null
        ? 'http://localhost:3000/cultivo'
        : 'http://localhost:3000/cultivo/$idEditando';
        print('idLote: $idLote');
print('tipoSeleccionado: $tipoSeleccionado');
print('variedad: ${variedadController.text}');
print('fecha: ${fechaController.text}');
    final method = idEditando == null ? http.post : http.put;

    final res = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_lote': idLote,
        'tipo_cultivo': tipoSeleccionado,
        'variedad': variedadController.text,
        'fecha_siembra': fechaController.text,
        'estado': estadoSeleccionado,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      limpiarCampos();
      if (mounted) Navigator.pop(context);
      obtenerCultivos();
    }
  }

  Future<void> eliminarCultivo(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/cultivo/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    obtenerCultivos();
  }

  void limpiarCampos() {
    variedadController.clear();
    fechaController.clear();
    tipoSeleccionado = null;
    variedadesDisponibles = [];
    estadoSeleccionado = _estadosCultivo.first;
    idLote = null;
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

  void mostrarFormulario({Map? cultivo}) {
    if (cultivo == null) {
      limpiarCampos();
    } else {
      idEditando = cultivo['id_cultivo'];
      tipoSeleccionado = cultivo['tipo_cultivo'];
      variedadesDisponibles = _variedadesCafe[tipoSeleccionado] ?? [];
      variedadController.text = cultivo['variedad'] ?? '';
      fechaController.text = cultivo['fecha_siembra'] ?? '';
      estadoSeleccionado = cultivo['estado'] ?? _estadosCultivo.first;
      idLote = cultivo['id_lote'];
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            cultivo == null ? 'Nuevo Cultivo' : 'Editar Cultivo',
            style: const TextStyle(
                color: Color(0xFF6B7F66), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Lote ─────────────────────────────────────────────────────
                DropdownButtonFormField<int>(
                  initialValue: idLote,
                  hint: const Text('Seleccionar Lote'),
                  isExpanded: true,
                  decoration: _inputDeco('Lote'),
                  items: lotes.map<DropdownMenuItem<int>>((l) {
                    return DropdownMenuItem(
                      value: l['id_lote'] as int,
                      child: Text('${l['nombre_lote']} (${l['nombre_finca']})'),
                    );
                  }).toList(),
                  onChanged: (v) => setD(() => idLote = v),
                ),
                const SizedBox(height: 12),

                // ── Tipo de café ──────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: tipoSeleccionado,
                  hint: const Text('Tipo de café'),
                  isExpanded: true,
                  decoration: _inputDeco('Tipo de café'),
                  items: _tiposCafe
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setD(() {
                    tipoSeleccionado = v;
                    variedadesDisponibles = _variedadesCafe[v] ?? [];
                    variedadController.clear();
                  }),
                ),
                const SizedBox(height: 12),

                // ── Variedad ──────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  key: ValueKey(tipoSeleccionado),
                  initialValue: variedadesDisponibles.contains(variedadController.text)
                      ? variedadController.text
                      : null,
                  hint: const Text('Variedad'),
                  isExpanded: true,
                  decoration: _inputDeco('Variedad'),
                  items: variedadesDisponibles
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: tipoSeleccionado == null
                      ? null
                      : (v) => setD(() => variedadController.text = v!),
                ),
                const SizedBox(height: 12),

                // ── Fecha siembra ─────────────────────────────────────────────
                TextField(
                  controller: fechaController,
                  readOnly: true,
                  decoration: _inputDeco('Fecha de siembra').copyWith(
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
                        fechaController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // ── Estado ────────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: estadoSeleccionado,
                  isExpanded: true,
                  decoration: _inputDeco('Estado'),
                  items: _estadosCultivo
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setD(() => estadoSeleccionado = v ?? _estadosCultivo.first),
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
              onPressed: guardarCultivo,
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
        title: const Text('Eliminar Cultivo'),
        content: const Text('¿Seguro que deseas eliminar este cultivo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              eliminarCultivo(id);
              Navigator.pop(context);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'Activo':
        return Colors.green;
      case 'En crecimiento':
        return Colors.teal;
      case 'En floración':
        return Colors.purple;
      case 'Cosechado':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  void _onItemTapped(int index) async {

  if (index == 0) {
    Navigator.pop(context);
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

  } else if (index == 2) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportesScreen(),
      ),
    );

  } else if (index == 3) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }
}

  Widget _cultivoCard(Map c) {
    final estado = c['estado'] ?? '-';
    final color = _estadoColor(estado);

    return GestureDetector(
      onTap: () => mostrarFormulario(cultivo: c),
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
              const Icon(Icons.spa, color: Color(0xFF6B7F66)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${c['tipo_cultivo'] ?? ''} · ${c['variedad'] ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              // Badge de estado
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(estado,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => confirmarEliminacion(c['id_cultivo']),
              ),
            ]),
            const Divider(height: 12),
            Row(children: [
              _infoChip(Icons.eco, c['nombre_lote'] ?? '-'),
              const SizedBox(width: 12),
              _infoChip(Icons.park, c['nombre_finca'] ?? '-'),
            ]),
            const SizedBox(height: 4),
            _infoChip(Icons.calendar_today,
                c['fecha_siembra'] != null
                    ? _formatearFecha(c['fecha_siembra'])
                    : '-'),
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
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
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
                const Icon(Icons.spa, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Cultivos',
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
                  const Text('Mis Cultivos',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (cultivos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No hay cultivos registrados'),
                      ),
                    )
                  else
                    ...cultivos.map((c) => _cultivoCard(c)),
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
