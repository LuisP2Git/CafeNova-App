import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FincasScreen extends StatefulWidget {
  const FincasScreen({super.key});

  @override
  State<FincasScreen> createState() => _FincasScreenState();
}

class _FincasScreenState extends State<FincasScreen> {

  List fincas = [];

  final nombreController = TextEditingController();
  final ubicacionController = TextEditingController();
  final tamanoController = TextEditingController();
  final propietarioController = TextEditingController();

  int? idEditando;

  @override
  void initState() {
    super.initState();
    obtenerFincas();
  }

  Future<void> obtenerFincas() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/fincas'),
    );

    if (response.statusCode == 200) {
      setState(() {
        fincas = jsonDecode(response.body);
      });
    }
  }

  Future<void> guardarFinca() async {
    final url = idEditando == null
        ? 'http://localhost:3000/fincas'
        : 'http://localhost:3000/fincas/$idEditando';

    final method = idEditando == null ? http.post : http.put;

    final response = await method(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_finca': nombreController.text,
        'ubicacion': ubicacionController.text,
        'tamano_hectareas': tamanoController.text,
        'propietario': propietarioController.text,
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
    );
    obtenerFincas();
  }

  void limpiarCampos() {
    nombreController.clear();
    ubicacionController.clear();
    tamanoController.clear();
    propietarioController.clear();
    idEditando = null;
  }

  void mostrarFormulario({Map? finca}) {

    if (finca != null) {
      idEditando = finca['id_finca'];
      nombreController.text = finca['nombre_finca'];
      ubicacionController.text = finca['ubicacion'];
      tamanoController.text = finca['tamano_hectareas'].toString();
      propietarioController.text = finca['propietario'];
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(finca == null ? "Nueva Finca" : "Editar Finca"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nombreController, decoration: const InputDecoration(labelText: "Nombre")),
                TextField(controller: ubicacionController, decoration: const InputDecoration(labelText: "Ubicación")),
                TextField(controller: tamanoController, decoration: const InputDecoration(labelText: "Tamaño (ha)")),
                TextField(controller: propietarioController, decoration: const InputDecoration(labelText: "Propietario")),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.eco, color: Colors.white),
                      const SizedBox(width: 10),
                      const Text("Cafe Nova",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Usuario", style: TextStyle(color: Colors.white)),
                      Row(
                        children: [
                          Icon(Icons.circle,
                              size: 10, color: Colors.greenAccent),
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
                    "Fincas",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...fincas.map((finca) => fincaCard(finca)),
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
    );
  }

  Widget fincaCard(Map finca) {
    return GestureDetector(
      onTap: () => mostrarFormulario(finca: finca),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                const Icon(Icons.park, color: Color(0xFF6B7F66)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    finca['nombre_finca'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      confirmarEliminacion(finca['id_finca']),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text("Ubicación: ${finca['ubicacion'] ?? '-'}"),
            Text("Tamaño: ${finca['tamano_hectareas'] ?? '-'} ha"),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person,
                      size: 16, color: Color(0xFF6B7F66)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Propietario: ${finca['propietario'] ?? '-'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}