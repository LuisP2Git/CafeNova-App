import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/reportes_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/home_screen.dart';

class LotesScreen extends StatefulWidget {

  const LotesScreen({super.key});

  @override
  State<LotesScreen> createState() => _LotesScreenState();
}

class _LotesScreenState extends State<LotesScreen> {
  String nombreUsuario = '';
  String rol = '';
String cargo = '';

Future<void> cargarSesion() async {
  final datos = await SessionService.getDatosSesion();

  if (!mounted) return;

  setState(() {
    rol = datos['rol'] ?? '';
    cargo = datos['cargo'] ?? '';
  });
}

  List lotes = [];
  List fincas = [];

  final nombreController = TextEditingController();
  final areaController = TextEditingController();

  // ✅ Tipo de suelo como dropdown
  static const List<String> tiposSuelo = [
    'Franco',
    'Arcilloso',
    'Arenoso',
    'Limoso',
    'Franco-arcilloso',
    'Franco-arenoso',
    'Franco-limoso',
    'Arcillo-arenoso',
    'Arcillo-limoso',
    'Orgánico',
  ];
  String? tipoSueloSeleccionado;

  int? fincaSeleccionada;
  int? idEditando;

  String? token;
  String correo = '';
  final int _selectedIndex = 1;

  @override
  void initState() {
  super.initState();
  cargarSesion();
  init();
}

  Future<void> init() async {
    token = await SessionService.getToken();
    final datos = await SessionService.getDatosSesion();
    if (!mounted) return;
    setState(() {
      nombreUsuario = datos['nombre'] ?? '';
      correo = datos['correo'] ?? '';
      rol = datos['rol'] ?? '';
    });

  await obtenerLotes();
  await obtenerFincas();
}

  Future<void> obtenerLotes() async {
    final response = await http.get(
      Uri.parse('https://cafenova-app-production.up.railway.app/lotes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() => lotes = jsonDecode(response.body));
    }
  }

  Future<void> obtenerFincas() async {
    final response = await http.get(
      Uri.parse('https://cafenova-app-production.up.railway.app/fincas'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() => fincas = jsonDecode(response.body));
    }
  }

  Future<void> guardarLote() async {
    if (fincaSeleccionada == null) {
      _mostrarError('Selecciona una finca');
      return;
    }
    if (tipoSueloSeleccionado == null) {
      _mostrarError('Selecciona el tipo de suelo');
      return;
    }
    // ✅ Validación: hectáreas solo números
    final areaText = areaController.text.trim();
    if (areaText.isEmpty || double.tryParse(areaText) == null) {
      _mostrarError('El área debe ser un número válido (ej: 5.5)');
      return;
    }

    final url = idEditando == null
        ? 'https://cafenova-app-production.up.railway.app/lotes'
        : 'https://cafenova-app-production.up.railway.app/lotes/$idEditando';
    final method = idEditando == null ? http.post : http.put;

    final response = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_finca': fincaSeleccionada,
        'nombre_lote': nombreController.text,
        'area': double.parse(areaText),
        'tipo_suelo': tipoSueloSeleccionado,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      limpiarCampos();
      if (mounted) Navigator.pop(context);
      obtenerLotes();
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> eliminarLote(int id) async {
    await http.delete(
      Uri.parse('https://cafenova-app-production.up.railway.app/lotes/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    obtenerLotes();
  }

  void limpiarCampos() {
    nombreController.clear();
    areaController.clear();
    tipoSueloSeleccionado = null;
    fincaSeleccionada = null;
    idEditando = null;
  }

  void mostrarFormulario({Map? lote}) async {
    if (fincas.isEmpty) await obtenerFincas();

    if (lote == null) {
      limpiarCampos();
    } else {
      idEditando = lote['id_lote'];
      nombreController.text = lote['nombre_lote'];
      areaController.text = lote['area'].toString();
      final tipoActual = lote['tipo_suelo']?.toString() ?? '';
      tipoSueloSeleccionado =
          tiposSuelo.contains(tipoActual) ? tipoActual : null;
      fincaSeleccionada = int.parse(lote['id_finca'].toString());
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            lote == null ? 'Nuevo Lote' : 'Editar Lote',
            style: const TextStyle(
                color: Color(0xFF6B7F66), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Finca
                DropdownButtonFormField<int>(
                  initialValue: fincaSeleccionada,
                  hint: const Text('Seleccionar Finca'),
                  isExpanded: true,
                  decoration: _inputDeco('Finca'),
                  items: fincas.map<DropdownMenuItem<int>>((finca) {
                    return DropdownMenuItem<int>(
                      value: int.parse(finca['id_finca'].toString()),
                      child: Text(finca['nombre_finca']),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setStateDialog(() => fincaSeleccionada = v),
                ),
                const SizedBox(height: 12),
                // Nombre
                TextField(
                  controller: nombreController,
                  decoration: _inputDeco('Nombre del Lote'),
                ),
                const SizedBox(height: 12),
                // ✅ Área: solo números decimales
                TextField(
                  controller: areaController,
                  decoration: _inputDeco('Área (hectáreas)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 12),
                // ✅ Tipo de suelo: dropdown
                DropdownButtonFormField<String>(
                  initialValue: tipoSueloSeleccionado,
                  hint: const Text('Tipo de Suelo'),
                  isExpanded: true,
                  decoration: _inputDeco('Tipo de Suelo'),
                  items: tiposSuelo
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => tipoSueloSeleccionado = v),
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
              onPressed: guardarLote,
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
        title: const Text('Eliminar Lote'),
        content: const Text('¿Seguro que deseas eliminar este lote?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              eliminarLote(id);
              Navigator.pop(context);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

  Widget loteCard(Map lote) {
    return GestureDetector(
      onTap: () => mostrarFormulario(lote: lote),
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
            Row(
              children: [
                const Icon(Icons.eco, color: Color(0xFF6B7F66)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${lote['nombre_lote']} — ${lote['nombre_finca']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => confirmarEliminacion(lote['id_lote']),
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              children: [
                _infoChip(Icons.straighten,
                    '${lote['area'] ?? '-'} ha'),
                const SizedBox(width: 12),
                _infoChip(
                    Icons.terrain, lote['tipo_suelo'] ?? '-'),
              ],
            ),
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
            style:
                const TextStyle(fontSize: 13, color: Colors.black87)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Icon(Icons.eco, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text('Cafe Nova',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ]),
                  Text(nombreUsuario,
                      style: const TextStyle(color: Colors.white)),
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
                  const Text('Lotes de la Finca',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (lotes.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No hay lotes registrados'),
                    ))
                  else
                    ...lotes.map((lote) => loteCard(lote)),
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
      bottomNavigationBar: AppBottomNav(
  currentIndex: _selectedIndex,
  onTabSelected: _onItemTapped,
  puedeVerReportes:
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo',
),
    );
  }
}