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

class FincasScreen extends StatefulWidget {
  final String nombreUsuario;
  const FincasScreen({super.key, required this.nombreUsuario});

  @override
  State<FincasScreen> createState() => _FincasScreenState();
}

class _FincasScreenState extends State<FincasScreen> {
  late String nombreUsuario;

  List fincas = [];
  List departamentos = [];
  List municipios = [];
  Map<String, List> cacheMunicipios = {};

  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  final nombreController = TextEditingController();
  final propietarioController = TextEditingController();
  final tamanoController = TextEditingController();

  int? idEditando;
  String? token;
  String correo = '';
  String rol = '';

  // Fincas es pantalla admin, no tiene pestaña directa — Inicio queda activo
  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    nombreUsuario = widget.nombreUsuario;
    _init();
  }

  Future<void> _init() async {
    token = await SessionService.getToken();
    correo = await SessionService.getCorreo() ?? '';
    rol = await SessionService.getRol() ?? '';
    if (token == null) return;
    await obtenerFincas();
    await obtenerDepartamentos();
  }

  Future<void> obtenerDepartamentos() async {
    try {
      final res = await http
          .get(Uri.parse('https://api-colombia.com/api/v1/Department'));
      if (res.statusCode == 200) {
        setState(() => departamentos = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  Future<void> obtenerMunicipios(String idDep) async {
    if (cacheMunicipios.containsKey(idDep)) {
      municipios = cacheMunicipios[idDep]!;
      return;
    }
    try {
      final res = await http.get(
          Uri.parse('https://api-colombia.com/api/v1/Department/$idDep/cities'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        cacheMunicipios[idDep] = data;
        municipios = data;
      }
    } catch (_) {}
  }

  Future<void> obtenerFincas() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/fincas'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      setState(() => fincas = jsonDecode(res.body));
    }
  }

  Future<void> guardarFinca() async {
    if (nombreController.text.trim().isEmpty) {
      _mostrarError('El nombre es obligatorio');
      return;
    }
    if (departamentoSeleccionado == null || municipioSeleccionado == null) {
      _mostrarError('Debes seleccionar departamento y municipio');
      return;
    }
    // ✅ Validación numérica de tamaño
    final tamanoText = tamanoController.text.trim();
    if (tamanoText.isEmpty || double.tryParse(tamanoText) == null) {
      _mostrarError('El tamaño debe ser un número válido (ej: 12.5)');
      return;
    }
    if (propietarioController.text.trim().isEmpty) {
      _mostrarError('El propietario es obligatorio');
      return;
    }

    final depNombre = departamentos
        .firstWhere((d) => d['id'].toString() == departamentoSeleccionado)['name'];

    final url = idEditando == null
        ? 'http://localhost:3000/fincas'
        : 'http://localhost:3000/fincas/$idEditando';
    final method = idEditando == null ? http.post : http.put;

    final res = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nombre_finca': nombreController.text.trim(),
        'ubicacion': '$depNombre - $municipioSeleccionado',
        'tamano_hectareas': double.parse(tamanoText),
        'propietario': propietarioController.text.trim(),
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      limpiarCampos();
      if (mounted) Navigator.pop(context);
      obtenerFincas();
    }
  }

  Future<void> eliminarFinca(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/fincas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    obtenerFincas();
  }

  void limpiarCampos() {
    nombreController.clear();
    tamanoController.clear();
    propietarioController.clear();
    departamentoSeleccionado = null;
    municipioSeleccionado = null;
    municipios = [];
    idEditando = null;
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void mostrarFormulario({Map? finca}) async {
    if (finca == null) {
      limpiarCampos();
    } else {
      idEditando = finca['id_finca'];
      nombreController.text = finca['nombre_finca'];
      tamanoController.text = finca['tamano_hectareas'].toString();
      propietarioController.text = finca['propietario'];

      final ubicacion = finca['ubicacion'] ?? '';
      if (ubicacion.contains(' - ')) {
        final partes = ubicacion.split(' - ');
        final dep = departamentos.firstWhere(
          (d) => d['name'] == partes[0],
          orElse: () => {},
        );
        if ((dep as Map).isNotEmpty) {
          departamentoSeleccionado = dep['id'].toString();
          await obtenerMunicipios(departamentoSeleccionado!);
          municipioSeleccionado = partes[1];
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            finca == null ? 'Nueva Finca' : 'Editar Finca',
            style: const TextStyle(
                color: Color(0xFF6B7F66), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                TextField(
                  controller: nombreController,
                  decoration: _inputDeco('Nombre de la Finca'),
                ),
                const SizedBox(height: 12),

                // Departamento
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: departamentoSeleccionado,
                  hint: const Text('Departamento'),
                  decoration: _inputDeco('Departamento'),
                  items: departamentos.map<DropdownMenuItem<String>>((dep) {
                    return DropdownMenuItem(
                      value: dep['id'].toString(),
                      child: Text(dep['name']),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setD(() {
                      departamentoSeleccionado = value;
                      municipioSeleccionado = null;
                      municipios = [];
                    });
                    await obtenerMunicipios(value!);
                    setD(() {});
                  },
                ),
                const SizedBox(height: 12),

                // Municipio
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: municipioSeleccionado,
                  hint: const Text('Municipio'),
                  decoration: _inputDeco('Municipio'),
                  items: municipios.map<DropdownMenuItem<String>>((mun) {
                    return DropdownMenuItem(
                      value: mun['name'],
                      child: Text(mun['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setD(() => municipioSeleccionado = v),
                ),
                const SizedBox(height: 12),

                // Tamaño ✅ solo números
                TextField(
                  controller: tamanoController,
                  decoration: _inputDeco('Tamaño (hectáreas)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 12),

                // Propietario
                TextField(
                  controller: propietarioController,
                  decoration: _inputDeco('Propietario'),
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
              onPressed: guardarFinca,
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
        title: const Text('Eliminar Finca'),
        content: const Text('¿Seguro que deseas eliminar esta finca?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              eliminarFinca(id);
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
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('nombre') ?? nombreUsuario;
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

  Widget _fincaCard(Map finca) {
    return GestureDetector(
      onTap: () => mostrarFormulario(finca: finca),
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
              const Icon(Icons.park, color: Color(0xFF6B7F66)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  finca['nombre_finca'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => confirmarEliminacion(finca['id_finca']),
              ),
            ]),
            const Divider(height: 12),
            _infoChip(Icons.location_on, finca['ubicacion'] ?? '-'),
            const SizedBox(height: 6),
            Row(children: [
              _infoChip(Icons.straighten,
                  '${finca['tamano_hectareas'] ?? '-'} ha'),
              const SizedBox(width: 16),
              Expanded(
                  child: _infoChip(
                      Icons.person, finca['propietario'] ?? '-')),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Icon(Icons.park, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text('Fincas',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
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
                  const Text('Mis Fincas',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  if (fincas.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No hay fincas registradas'),
                      ),
                    )
                  else
                    ...fincas.map((f) => _fincaCard(f)),
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
