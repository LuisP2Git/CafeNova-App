import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LotesScreen extends StatefulWidget {
  const LotesScreen({super.key});

  @override
  State<LotesScreen> createState() => _LotesScreenState();
}

class _LotesScreenState extends State<LotesScreen> {

  List lotes = [];
  List fincas = [];

  final nombreController = TextEditingController();
  final areaController = TextEditingController();
  final tipoController = TextEditingController();

  int? fincaSeleccionada;
  int? idEditando;

  final int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    obtenerLotes();
    obtenerFincas();
  }

  Future<void> obtenerLotes() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/lotes'),
    );

    if (response.statusCode == 200) {
      setState(() {
        lotes = jsonDecode(response.body);
      });
    }
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

  Future<void> guardarLote() async {
    final url = idEditando == null
        ? 'http://localhost:3000/lotes'
        : 'http://localhost:3000/lotes/$idEditando';

    final method = idEditando == null ? http.post : http.put;

    final response = await method(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_finca': fincaSeleccionada,
        'nombre_lote': nombreController.text,
        'area': areaController.text,
        'tipo_suelo': tipoController.text,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      limpiarCampos();
      Navigator.pop(context);
      obtenerLotes();
    }
  }

  Future<void> eliminarLote(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/lotes/$id'),
    );
    obtenerLotes();
  }

  void limpiarCampos() {
    nombreController.clear();
    areaController.clear();
    tipoController.clear();
    fincaSeleccionada = null;
    idEditando = null;
  }

  void mostrarFormulario({Map? lote}) {
    if (lote != null) {
      idEditando = lote['id_lote'];
      nombreController.text = lote['nombre_lote'];
      areaController.text = lote['area'].toString();
      tipoController.text = lote['tipo_suelo'];
      fincaSeleccionada = lote['id_finca'];
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(lote == null ? "Nuevo Lote" : "Editar Lote"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: fincaSeleccionada,
                  hint: const Text("Seleccionar Finca"),
                  items: fincas.map<DropdownMenuItem<int>>((finca) {
                    return DropdownMenuItem<int>(
                      value: finca['id_finca'],
                      child: Text(finca['nombre_finca']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    fincaSeleccionada = value;
                  },
                ),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: "Nombre Lote"),
                ),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: "Área"),
                ),
                TextField(
                  controller: tipoController,
                  decoration: const InputDecoration(labelText: "Tipo de suelo"),
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
              onPressed: guardarLote,
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
        content: const Text("¿Seguro que deseas eliminar este lote?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              eliminarLote(id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context); 
    }
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
                    "Mis Lotes",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
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
    );
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
                const Icon(Icons.eco, color: Color(0xFF6B7F66)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${lote['nombre_lote']} - ${lote['nombre_finca']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      confirmarEliminacion(lote['id_lote']),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text("Área: ${lote['area'] ?? '-'} hectáreas"),
            Text("Ubicación: ${lote['tipo_suelo'] ?? '-'}"),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture,
                      size: 16, color: Color(0xFF6B7F66)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Variedad: ${lote['tipo_suelo'] ?? 'No definida'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}