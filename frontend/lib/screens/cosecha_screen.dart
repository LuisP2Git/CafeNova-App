import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/session_service.dart';

const estadosCalidad = [
  "Premium",
  "Alta",
  "Media",
  "Baja"
];

class CosechaScreen extends StatefulWidget {
  const CosechaScreen({super.key});

  @override
  State<CosechaScreen> createState() => _CosechaScreenState();
}

class _CosechaScreenState extends State<CosechaScreen> {

  List cosechas = [];
  List cultivos = []; // ✅ NUEVO

  final cantidadController = TextEditingController();
  final calidadController = TextEditingController();
  final fechaController = TextEditingController();

  DateTime? fechaSeleccionada;
  int? idCultivo;
  int? idEditando;

  String? token;
  String? calidadSeleccionada;
  String obtenerNombreCultivo(int id) {
  final cultivo = cultivos.firstWhere(
    (c) => c['id_cultivo'] == id,
    orElse: () => null,
  );

  if (cultivo == null) return "Cultivo $id";

  return "${cultivo['tipo_cultivo']} - ${cultivo['variedad']}";
}

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    token = await SessionService.getToken();
    if (token == null) return;

    await obtenerCultivos(); // ✅ NUEVO
    await obtenerCosechas();
  }

  // ================= GET CULTIVOS =================
  Future<void> obtenerCultivos() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/cultivo'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        cultivos = jsonDecode(response.body);
      });
    }
  }

  // ================= GET COSECHAS =================
  Future<void> obtenerCosechas() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/cosecha'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        cosechas = jsonDecode(response.body);
      });
    }
  }

  // ================= GUARDAR =================
  Future<void> guardarCosecha() async {

    if (idCultivo == null ||
        cantidadController.text.isEmpty ||
        calidadSeleccionada == null ||
        fechaController.text.isEmpty) {
      return;
    }

    final url = idEditando == null
        ? 'http://localhost:3000/cosecha'
        : 'http://localhost:3000/cosecha/$idEditando';

    final method = idEditando == null ? http.post : http.put;

    final response = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_cultivo': idCultivo,
        'fecha_cosecha': fechaController.text,
        'cantidad_kg': double.parse(cantidadController.text),
        'calidad': calidadSeleccionada,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      limpiarCampos();
      Navigator.pop(context);
      obtenerCosechas();
    }
  }

  // ================= DELETE =================
  Future<void> eliminarCosecha(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/cosecha/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    obtenerCosechas();
  }

  // ================= FORM =================
  void mostrarFormulario({Map? cosecha}) {

    if (cosecha == null) {
      limpiarCampos();
    } else {
      idEditando = cosecha['id_cosecha'];
      cantidadController.text = cosecha['cantidad_kg'].toString();
      calidadSeleccionada = cosecha['calidad'];
      fechaController.text = cosecha['fecha_cosecha'];
      idCultivo = cosecha['id_cultivo'];
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(cosecha == null ? "Nueva Cosecha" : "Editar Cosecha"),
          content: SingleChildScrollView(
            child: Column(
              children: [

                // ✅ DROPDOWN CORREGIDO
                DropdownButtonFormField<int>(
                  hint: const Text("Cultivo"),
                  value: idCultivo,
                  isExpanded: true,
                  items: cultivos.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem(
                      value: c['id_cultivo'],
                      child: Text(
                        "${c['tipo_cultivo']} - ${c['variedad']}",
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      idCultivo = value;
                    });
                  },
                ),

                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Cantidad (kg)"),
                ),

                const SizedBox(height: 10),

DropdownButtonFormField<String>(
  hint: const Text("Calidad"),
  value: estadosCalidad.contains(calidadSeleccionada)
      ? calidadSeleccionada
      : null,
  isExpanded: true,
  items: estadosCalidad.map((c) {
    return DropdownMenuItem(
      value: c,
      child: Text(c),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      calidadSeleccionada = value;
    });
  },
),

                TextField(
                  controller: fechaController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Fecha"),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      fechaSeleccionada = picked;
                      fechaController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: guardarCosecha,
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void limpiarCampos() {
    cantidadController.clear();
    calidadController.clear();
    fechaController.clear();
    idCultivo = null;
    fechaSeleccionada = null;
    calidadSeleccionada = null;
    idEditando = null;
  }

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Eliminar esta cosecha?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              eliminarCosecha(id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
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
            child: SafeArea(
  child: Row(
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      const Icon(Icons.agriculture, color: Colors.white),
      const SizedBox(width: 10),
      const Text("Cosechas",
          style: TextStyle(color: Colors.white)),
    ],
  ),
),
          ),

          Expanded(
            child: cosechas.isEmpty
                ? const Center(child: Text("No hay cosechas"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cosechas.length,
                    itemBuilder: (context, i) {
                      final c = cosechas[i];

                      return GestureDetector(
                        onTap: () => mostrarFormulario(cosecha: c),
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
                                  const Icon(Icons.agriculture,
                                      color: Color(0xFF6B7F66)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(obtenerNombreCultivo(c['id_cultivo']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        confirmarEliminacion(c['id_cosecha']),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text("Cantidad: ${c['cantidad_kg']} kg"),
                              Text("Calidad: ${c['calidad']}"),
                              Text("Fecha: ${c['fecha_cosecha']}"),
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