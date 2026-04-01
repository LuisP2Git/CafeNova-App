import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'usuarios_pendientes_screen.dart';

class EmpleadosScreen extends StatefulWidget {
  final String token;

  const EmpleadosScreen({super.key, required this.token});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  List empleados = [];
  List empleadosFiltrados = [];
  List fincas = [];

  bool cargando = true;

  final buscarController = TextEditingController();
  final cargoController = TextEditingController();
  final telefonoController = TextEditingController();
  final fechaController = TextEditingController();

  int? fincaSeleccionada;
  int? idEditando;

  @override
  void initState() {
    super.initState();
    obtenerEmpleados();
    obtenerFincas();
  }

  Future<void> obtenerEmpleados() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/empleados'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        empleados = data;
        empleadosFiltrados = data;
        cargando = false;
      });
    }
  }

  Future<void> obtenerFincas() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/fincas'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        fincas = jsonDecode(res.body);
      });
    }
  }

  void filtrar(String texto) {
    final query = texto.toLowerCase();

    setState(() {
      empleadosFiltrados = empleados.where((emp) {
        final nombre = (emp['nombre'] ?? '').toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  Future<void> irAPendientes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuariosPendientesScreen(token: widget.token),
      ),
    );
    obtenerEmpleados();
  }

  Future<void> eliminarEmpleado(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/empleados/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    obtenerEmpleados();
  }

  Future<void> editarEmpleado() async {
    await http.put(
      Uri.parse('http://localhost:3000/empleados/$idEditando'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        "cargo": cargoController.text,
        "telefono": telefonoController.text,
        "fecha_contratacion": fechaController.text,
        "id_finca": fincaSeleccionada
      }),
    );

    limpiarCampos();
    Navigator.pop(context);
    obtenerEmpleados();
  }

  void limpiarCampos() {
    cargoController.clear();
    telefonoController.clear();
    fechaController.clear();
    fincaSeleccionada = null;
    idEditando = null;
  }

  void mostrarFormulario({Map? emp}) {
    if (emp != null) {
      idEditando = emp['id_empleado'];
      cargoController.text = emp['cargo'] ?? '';
      telefonoController.text = emp['telefono'] ?? '';
      fechaController.text =
          emp['fecha_contratacion']?.toString().split(' ')[0] ?? '';
      fincaSeleccionada = emp['id_finca'];
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Editar empleado"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: cargoController,
                  decoration: const InputDecoration(labelText: "Cargo"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: "Teléfono"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fechaController,
                  decoration:
                      const InputDecoration(labelText: "Fecha contratación"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: fincaSeleccionada,
                  hint: const Text("Seleccionar finca"),
                  items: fincas.map<DropdownMenuItem<int>>((finca) {
                    return DropdownMenuItem(
                      value: finca['id_finca'],
                      child: Text(finca['nombre_finca']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      fincaSeleccionada = value;
                    });
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
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: editarEmpleado,
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Seguro que deseas eliminar este empleado?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              eliminarEmpleado(id);
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
        onPressed: irAPendientes,
        child: const Icon(Icons.person_add),
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
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  const Spacer(),
                  const Text("Empleados",
                      style: TextStyle(color: Colors.white))
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: buscarController,
              onChanged: filtrar,
              decoration: InputDecoration(
                hintText: "Buscar empleados...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : empleadosFiltrados.isEmpty
                    ? const Center(child: Text("No hay empleados"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: empleadosFiltrados.length,
                        itemBuilder: (context, i) {
                          final emp = empleadosFiltrados[i];
                          return GestureDetector(
                            onTap: () => mostrarFormulario(emp: emp),
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
                                      const Icon(Icons.person,
                                          color: Color(0xFF6B7F66)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          emp['nombre'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            confirmarEliminacion(
                                                emp['id_empleado']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text("Cargo: ${emp['cargo'] ?? '-'}"),
                                  Text("Teléfono: ${emp['telefono'] ?? '-'}"),
                                  Text(
                                      "Fecha: ${emp['fecha_contratacion'] ?? '-'}"),
                                  Text(
                                    emp['nombre_finca'] != null
                                        ? "Finca: ${emp['nombre_finca']}"
                                        : "⚠ Sin finca asignada",
                                    style: TextStyle(
                                      color: emp['nombre_finca'] == null
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
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