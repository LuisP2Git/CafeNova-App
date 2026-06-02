import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/session_service.dart';
import '../utils/mensajes.dart';
import 'package:flutter/services.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() =>
      _InventarioScreenState();
}

class _InventarioScreenState
    extends State<InventarioScreen> {

  List inventario = [];

  String? token;

  final nombreController =
      TextEditingController();

  final cantidadController =
      TextEditingController();

  String? tipoSeleccionado;
  String? unidadSeleccionada;

  int? idEditando;

  final tipos = [
    'Fertilizante',
    'Herbicida',
    'Insecticida',
    'Fungicida',
    'Abono',
    'Herramienta',
    'Otro',
  ];

  final unidades = [
    'Kg',
    'Gr',
    'Litros',
    'Ml',
    'Unidades',
    'Bultos',
  ];

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {

    token =
        await SessionService.getToken();

    if (token == null) return;

    await obtenerInventario();
  }

  Future<void> obtenerInventario() async {

    final response = await http.get(
      Uri.parse(
        'http://localhost:3000/inventario',
      ),
      headers: {
        'Authorization':
            'Bearer $token',
      },
    );

    if (response.statusCode == 200) {

      setState(() {
        inventario =
            jsonDecode(response.body);
      });
    }
  }

  Future<void> guardarInsumo() async {

    final cantidad = int.tryParse(
      cantidadController.text,
    );

    if (cantidad == null) {

      Mensajes.mostrar(
        context,
        'Cantidad inválida',
        esError: true,
      );

      return;
    }

    final url = idEditando == null
        ? 'http://localhost:3000/inventario'
        : 'http://localhost:3000/inventario/$idEditando';

    final response =
        idEditando == null
            ? await http.post(
                Uri.parse(url),
                headers: {
                  'Authorization':
                      'Bearer $token',
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'nombre_insumo':
                      nombreController.text,
                  'tipo':
                      tipoSeleccionado,
                  'cantidad':
                      cantidad,
                  'unidad':
                      unidadSeleccionada,
                }),
              )
            : await http.put(
                Uri.parse(url),
                headers: {
                  'Authorization':
                      'Bearer $token',
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode({
                  'nombre_insumo':
                      nombreController.text,
                  'tipo':
                      tipoSeleccionado,
                  'cantidad':
                      cantidad,
                  'unidad':
                      unidadSeleccionada,
                }),
              );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      limpiarCampos();

      Navigator.pop(context);

      obtenerInventario();
    }
  }

  Future<void> eliminarInsumo(
      int id) async {

    await http.delete(
      Uri.parse(
        'http://localhost:3000/inventario/$id',
      ),
      headers: {
        'Authorization':
            'Bearer $token',
      },
    );

    obtenerInventario();
  }

  void limpiarCampos() {

    nombreController.clear();
    cantidadController.clear();

    tipoSeleccionado = null;
    unidadSeleccionada = null;

    idEditando = null;
  }

  void mostrarFormulario({
    Map? insumo,
  }) {

    if (insumo != null) {

      idEditando =
          insumo['id_insumo'];

      nombreController.text =
          insumo['nombre_insumo'];

      cantidadController.text =
          insumo['cantidad']
              .toString();

      tipoSeleccionado =
          insumo['tipo'];

      unidadSeleccionada =
          insumo['unidad'];
    }

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(

          title: Text(
            insumo == null
                ? 'Nuevo Insumo'
                : 'Editar Insumo',
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                TextField(
                  controller:
                      nombreController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nombre',
                  ),
                ),

                DropdownButtonFormField<
                    String>(
                  initialValue:
                      tipoSeleccionado,
                  items: tipos
                      .map(
                        (e) =>
                            DropdownMenuItem(
                          value: e,
                          child:
                              Text(e),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (value) {
                    tipoSeleccionado =
                        value;
                  },
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Tipo',
                  ),
                ),

                TextField(
  controller: cantidadController,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
  decoration: const InputDecoration(
    labelText: 'Cantidad',
  ),
),

                DropdownButtonFormField<
                    String>(
                  initialValue:
                      unidadSeleccionada,
                  items: unidades
                      .map(
                        (e) =>
                            DropdownMenuItem(
                          value: e,
                          child:
                              Text(e),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (value) {
                    unidadSeleccionada =
                        value;
                  },
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Unidad',
                  ),
                ),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(
                      context),
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton(
              onPressed:
                  guardarInsumo,
              child:
                  const Text(
                'Guardar',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {

  return Scaffold(

    backgroundColor:
        const Color(0xFFF5F1ED),

    floatingActionButton:
        FloatingActionButton(

      backgroundColor:
          const Color(0xFF6B7F66),

      onPressed: () =>
          mostrarFormulario(),

      child: const Icon(Icons.add),
    ),

    body: Column(

      children: [

        Container(

          width: double.infinity,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 25,
          ),

          decoration:
              const BoxDecoration(

            color: Color(0xFF6B7F66),

            borderRadius:
                BorderRadius.only(

              bottomLeft:
                  Radius.circular(25),

              bottomRight:
                  Radius.circular(25),
            ),
          ),

          child: SafeArea(

            child: Row(

              children: [

                IconButton(

                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),

                  onPressed: () =>
                      Navigator.pop(
                    context,
                  ),
                ),

                const Icon(
                  Icons.inventory,
                  color: Colors.white,
                ),

                const SizedBox(width: 10),

                const Text(

                  'Inventario',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(

          child: inventario.isEmpty

              ? const Center(
                  child: Text(
                    'No hay insumos registrados',
                  ),
                )

              : ListView.builder(

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  itemCount:
                      inventario.length,

                  itemBuilder:
                      (context, index) {

                    final item =
                        inventario[index];

                    return GestureDetector(

                      onTap: () =>
                          mostrarFormulario(
                        insumo: item,
                      ),

                      child: Container(

                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),

                        padding:
                            const EdgeInsets.all(
                          14,
                        ),

                        decoration:
                            BoxDecoration(

                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),

                          boxShadow: const [

                            BoxShadow(
                              color:
                                  Colors.black12,
                              blurRadius: 4,
                              offset:
                                  Offset(0, 2),
                            ),
                          ],
                        ),

                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  padding:
                                      const EdgeInsets
                                          .all(
                                    10,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color:
                                        const Color(
                                      0xFF6B7F66,
                                    ).withValues(
                                      alpha: 0.15,
                                    ),

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),

                                  child:
                                      const Icon(

                                    Icons
                                        .inventory_2,

                                    color: Color(
                                      0xFF6B7F66,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Text(

                                        item[
                                            'nombre_insumo'],

                                        style:
                                            const TextStyle(

                                          fontWeight:
                                              FontWeight
                                                  .bold,

                                          fontSize:
                                              16,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Text(

                                        item[
                                                'tipo'] ??
                                            '',

                                        style:
                                            const TextStyle(

                                          color: Colors
                                              .black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(

                                  icon:
                                      const Icon(

                                    Icons
                                        .delete_outline,

                                    color:
                                        Colors.red,
                                  ),

                                  onPressed:
                                      () {

                                    eliminarInsumo(
                                      item[
                                          'id_insumo'],
                                    );
                                  },
                                ),
                              ],
                            ),

                            const Divider(),

                            Row(

                              children: [

                                const Icon(

                                  Icons.scale,

                                  size: 16,

                                  color: Color(
                                    0xFF6B7F66,
                                  ),
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                Text(

                                  '${item['cantidad']} ${item['unidad']}',

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}}