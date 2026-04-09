import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/session_service.dart';

const estadosCultivo = [
  "Activo",
  "En crecimiento",
  "En floración",
  "Cosechado",
  "Inactivo"
];
const tiposCafe = [
  "Arabica",
  "Robusta",
];

const Map<String, List<String>> variedadesCafeColombia = {
  "Arabica": [
    "Castillo",
    "Colombia",
    "Cenicafé 1",
    "Tabi",
    "Caturra",
    "Typica",
    "Bourbon",
    "Bourbon Rosado",
    "Bourbon Amarillo",
    "Geisha",
    "Maragogipe",
    "Pacamara",
    "Laurina"
  ],
  "Robusta": [
    "Conilon",
    "Robusta mejorado"
  ]
};
class CultivoScreen extends StatefulWidget {
  const CultivoScreen({super.key});
  

  @override
  State<CultivoScreen> createState() => _CultivoScreenState();
}

class _CultivoScreenState extends State<CultivoScreen> {

  String formatearFecha(String fecha) {
  final f = DateTime.parse(fecha);
  return "${f.day}/${f.month}/${f.year}";
}

  List lotes = [];
  List cultivos = [];
  List<String> variedadesDisponibles = [];
  


  final tipoController = TextEditingController();
  final variedadController = TextEditingController();
  final fechaController = TextEditingController();

  int? idLote;
  int? idEditando;

  String? token;
  String? estadoSeleccionado;
  String? tipoSeleccionado;
  

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    token = await SessionService.getToken();
    if (token == null) return;
    await obtenerLotes();   
    await obtenerCultivos();
  }

  // ================= GET =================

  Future<void> obtenerLotes() async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/lotes'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    setState(() {
      lotes = jsonDecode(response.body);
    });
  }
}

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

  // ================= GUARDAR =================
  Future<void> guardarCultivo() async {

    if (idLote == null ||
        tipoController.text.isEmpty ||
        variedadController.text.isEmpty ||
        fechaController.text.isEmpty ||
         estadoSeleccionado == null) {
      return;
    }

    final url = idEditando == null
        ? 'http://localhost:3000/cultivo'
        : 'http://localhost:3000/cultivo/$idEditando';

    final method = idEditando == null ? http.post : http.put;

    final response = await method(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_lote': idLote,
        'tipo_cultivo': tipoController.text,
        'variedad': variedadController.text,
        'fecha_siembra': fechaController.text,
        'estado': estadoSeleccionado,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      limpiarCampos();
      Navigator.pop(context);
      obtenerCultivos();
    }
  }

  // ================= DELETE =================
  Future<void> eliminarCultivo(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/cultivo/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    obtenerCultivos();
  }

  // ================= FORM =================
  void mostrarFormulario({Map? cultivo}) {

  if (cultivo == null) {
    limpiarCampos();
  } else {
    idEditando = cultivo['id_cultivo'];

    tipoSeleccionado = cultivo['tipo_cultivo'];
    tipoController.text = cultivo['tipo_cultivo'];

    variedadesDisponibles =
        variedadesCafeColombia[tipoSeleccionado] ?? [];

    variedadController.text = cultivo['variedad'];
    fechaController.text = cultivo['fecha_siembra'];
    estadoSeleccionado = cultivo['estado'];
    idLote = cultivo['id_lote'];
  }

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {

          return AlertDialog(
            title: Text(cultivo == null ? "Nuevo Cultivo" : "Editar Cultivo"),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ================= LOTE =================
                  DropdownButtonFormField<int>(
                    hint: const Text("Lote"),
                    initialValue: idLote,
                    isExpanded: true,
                    items: lotes.map<DropdownMenuItem<int>>((l) {
                      return DropdownMenuItem(
                        value: l['id_lote'],
                        child: Text(
                          "${l['nombre_lote']} (${l['nombre_finca']})",
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        idLote = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // ================= TIPO =================
                  DropdownButtonFormField<String>(
                    hint: const Text("Tipo de café"),
                    initialValue: tipoSeleccionado,
                    isExpanded: true,
                    items: tiposCafe.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tipoSeleccionado = value;
                        tipoController.text = value!;

                        variedadesDisponibles =
                            variedadesCafeColombia[value] ?? [];

                        variedadController.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // ================= VARIEDAD =================
                  DropdownButtonFormField<String>(
                    key: ValueKey(tipoSeleccionado),
                    hint: const Text("Variedad"),
                    initialValue: variedadesDisponibles.contains(variedadController.text)
                        ? variedadController.text
                        : null,
                    isExpanded: true,
                    items: tipoSeleccionado == null
                        ? []
                        : variedadesDisponibles.map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text(v),
                            );
                          }).toList(),
                    onChanged: tipoSeleccionado == null
                        ? null
                        : (value) {
                            setModalState(() {
                              variedadController.text = value!;
                            });
                          },
                  ),

                  const SizedBox(height: 10),

                  // ================= FECHA =================
                  TextField(
                    controller: fechaController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Fecha siembra"),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setModalState(() {
                          fechaController.text =
                              "${picked.year}-${picked.month}-${picked.day}";
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // ================= ESTADO =================
                  DropdownButtonFormField<String>(
                    hint: const Text("Estado"),
                    initialValue: estadoSeleccionado,
                    isExpanded: true,
                    items: estadosCultivo.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(estado),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        estadoSeleccionado = value;
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
                onPressed: guardarCultivo,
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );
    },
  );
}

  void limpiarCampos() {
    tipoController.clear();
    variedadController.clear();
    fechaController.clear();
    estadoSeleccionado = null;
    tipoSeleccionado = null;
    variedadesDisponibles = [];
    idLote = null;
    idEditando = null;
  }

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Eliminar este cultivo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              eliminarCultivo(id);
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

        // ================= HEADER =================
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
                const Icon(Icons.spa, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  "Cultivos",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // ================= LISTA =================
        Expanded(
          child: cultivos.isEmpty
              ? const Center(child: Text("No hay cultivos"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cultivos.length,
                  itemBuilder: (context, i) {
                    final c = cultivos[i];

                    return GestureDetector(
                      onTap: () => mostrarFormulario(cultivo: c),
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
                                const Icon(Icons.spa,
                                    color: Color(0xFF6B7F66)),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    c['tipo_cultivo'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => confirmarEliminacion(
                                      c['id_cultivo']),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text("Variedad: ${c['variedad'] ?? '-'}"),
                            Text("Lote: ${c['nombre_lote'] ?? '-'}"),
                            Text("Finca: ${c['nombre_finca'] ?? '-'}"),
                            Text("Estado: ${c['estado'] ?? '-'}"),
                            Text("Siembra: ${c['fecha_siembra'] != null ? formatearFecha(c['fecha_siembra']) : '-'}"),
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