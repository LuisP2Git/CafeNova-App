import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/session_service.dart';
import '../utils/mensajes.dart';

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
                  controller:
                      cantidadController,
                  keyboardType:
                      TextInputType
                          .number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Cantidad',
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
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text(
          'Inventario',
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () =>
            mostrarFormulario(),
        child:
            const Icon(
          Icons.add,
        ),
      ),

      body: ListView.builder(

        padding:
            const EdgeInsets.all(12),

        itemCount:
            inventario.length,

        itemBuilder:
            (context, index) {

          final item =
              inventario[index];

          return Card(
            child: ListTile(

              title: Text(
                item[
                    'nombre_insumo'],
              ),

              subtitle: Text(
                '${item['tipo']} - ${item['cantidad']} ${item['unidad']}',
              ),

              onTap: () =>
                  mostrarFormulario(
                insumo: item,
              ),

              trailing:
                  IconButton(
                icon:
                    const Icon(
                  Icons.delete,
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
            ),
          );
        },
      ),
    );
  }
}

