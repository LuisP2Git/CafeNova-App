import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FincasScreen extends StatefulWidget {
  final String nombreUsuario;
  final String token;

  const FincasScreen({
    super.key,
    required this.nombreUsuario,
    required this.token,
  });

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
  final tamanoController = TextEditingController();
  final propietarioController = TextEditingController();

  int? idEditando;

  @override
  void initState() {
    super.initState();
    nombreUsuario = widget.nombreUsuario;
    obtenerFincas();
    obtenerDepartamentos();
  }

  Future<void> obtenerDepartamentos() async {
    final response = await http.get(
      Uri.parse('https://api-colombia.com/api/v1/Department'),
    );

    if (response.statusCode == 200) {
      setState(() {
        departamentos = jsonDecode(response.body);
      });
    }
  }

  Future<void> obtenerMunicipios(String idDepartamento) async {
    if (cacheMunicipios.containsKey(idDepartamento)) {
      municipios = cacheMunicipios[idDepartamento]!;
      return;
    }

    final response = await http.get(
      Uri.parse(
          'https://api-colombia.com/api/v1/Department/$idDepartamento/cities'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      cacheMunicipios[idDepartamento] = data;
      municipios = data;
    }
  }

  Future<void> obtenerFincas() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/fincas'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        fincas = jsonDecode(response.body);
      });
    }
  }

  Future<void> guardarFinca() async {
    if (nombreController.text.trim().isEmpty) {
      mostrarError("El nombre es obligatorio");
      return;
    }

    if (departamentoSeleccionado == null || municipioSeleccionado == null) {
      mostrarError("Debes seleccionar ubicación");
      return;
    }

    final tamano = double.tryParse(tamanoController.text);

    if (tamano == null || tamano <= 0) {
      mostrarError("El tamaño debe ser un numero valido");
      return;
    }

    if (propietarioController.text.trim().isEmpty) {
      mostrarError("El propietario es obligatorio");
      return;
    }

    final depNombre = departamentos.firstWhere(
      (d) => d['id'].toString() == departamentoSeleccionado,
    )['name'];

    final url = idEditando == null
        ? 'http://localhost:3000/fincas'
        : 'http://localhost:3000/fincas/$idEditando';

    final method = idEditando == null ? http.post : http.put;

    final response = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'nombre_finca': nombreController.text.trim(),
        'ubicacion': "$depNombre - $municipioSeleccionado",
        'tamano_hectareas': tamano,
        'propietario': propietarioController.text.trim(),
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      limpiarCampos();
      Navigator.pop(context);
      obtenerFincas();
    }
  }

  Future<void> eliminarFinca(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/fincas/$id'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
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

  void mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void mostrarFormulario({Map? finca}) async {
    if (finca != null) {
      idEditando = finca['id_finca'];
      nombreController.text = finca['nombre_finca'];
      tamanoController.text = finca['tamano_hectareas'].toString();
      propietarioController.text = finca['propietario'];

      final ubicacion = finca['ubicacion'] ?? "";

      if (ubicacion.contains(" - ")) {
        final partes = ubicacion.split(" - ");
        final nombreDep = partes[0];
        final nombreMun = partes[1];

        final dep = departamentos.firstWhere(
          (d) => d['name'] == nombreDep,
          orElse: () => {},
        );

        if (dep.isNotEmpty) {
          departamentoSeleccionado = dep['id'].toString();
          await obtenerMunicipios(departamentoSeleccionado!);
          municipioSeleccionado = nombreMun;
        }
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(finca == null ? "Nueva Finca" : "Editar Finca"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: "Nombre"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      hint: const Text("Departamento"),
                      initialValue: departamentoSeleccionado,
                      items: departamentos.map<DropdownMenuItem<String>>((dep) {
                        return DropdownMenuItem(
                          value: dep['id'].toString(),
                          child: Text(dep['name']),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setStateDialog(() {
                          departamentoSeleccionado = value;
                          municipioSeleccionado = null;
                          municipios = [];
                        });

                        await obtenerMunicipios(value!);
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      hint: const Text("Municipio"),
                      initialValue: municipioSeleccionado,
                      items: municipios.map<DropdownMenuItem<String>>((mun) {
                        return DropdownMenuItem(
                          value: mun['name'],
                          child: Text(mun['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          municipioSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tamanoController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Tamaño (ha)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: propietarioController,
                      decoration:
                          const InputDecoration(labelText: "Propietario"),
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
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: guardarFinca,
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Seguro que deseas eliminar esta finca?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              eliminarFinca(id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B7F66),
        onPressed: () => mostrarFormulario(),
        child: const Icon(Icons.add),
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(Icons.eco, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text("Cafe Nova",
                      style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text(nombreUsuario,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          Expanded(
            child: fincas.isEmpty
                ? const Center(child: Text("No hay fincas"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: fincas.length,
                    itemBuilder: (context, i) {
                      final finca = fincas[i];

                      return GestureDetector(
                        onTap: () => mostrarFormulario(finca: finca),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.park,
                                      color: Color(0xFF6B7F66)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      finca['nombre_finca'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => confirmarEliminacion(
                                        finca['id_finca']),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text("Ubicación: ${finca['ubicacion'] ?? '-'}"),
                              Text(
                                  "Tamaño: ${finca['tamano_hectareas'] ?? '-'} ha"),
                              const SizedBox(height: 10),
                              Text("Propietario: ${finca['propietario'] ?? '-'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}