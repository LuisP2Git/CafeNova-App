import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/session_service.dart';
import '../widgets/app_bottom_nav.dart';

import 'home_screen.dart';
import 'reportes_screen.dart';
import 'profile_screen.dart';

class FumigacionScreen extends StatefulWidget {
  const FumigacionScreen({super.key});

  @override
  State<FumigacionScreen> createState() =>
      _FumigacionScreenState();
}

class _FumigacionScreenState
    extends State<FumigacionScreen> {

  String? token;

  String nombreUsuario = '';
  String correo = '';
  String rol = '';

  List plagas = [];
  List cultivos = [];

  int? cultivoSeleccionado;
  int? idEditando;

  final tipoPlagaController =
      TextEditingController();

  final tratamientoController =
      TextEditingController();

  final cantidadController =
      TextEditingController();

  final hectareasController =
      TextEditingController();

  String? unidadSeleccionada;

  final unidades = [
    'Kg',
    'Gr',
    'Litros',
    'Ml',
  ];

  final int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {

    token =
        await SessionService.getToken();

    final datos =
        await SessionService
            .getDatosSesion();

    if (!mounted) return;

    setState(() {
      nombreUsuario =
          datos['nombre'] ?? '';

      correo =
          datos['correo'] ?? '';

      rol =
          datos['rol'] ?? '';
    });

    await obtenerCultivos();
    await obtenerPlagas();
  }

  Future<void> obtenerCultivos() async {

    final response = await http.get(
      Uri.parse(
        'http://localhost:3000/cultivo',
      ),
      headers: {
        'Authorization':
            'Bearer $token',
      },
    );

    if (response.statusCode == 200) {

      setState(() {
        cultivos =
            jsonDecode(response.body);
      });
    }
  }

  Future<void> obtenerPlagas() async {

    final response = await http.get(
      Uri.parse(
        'http://localhost:3000/plagas',
      ),
      headers: {
        'Authorization':
            'Bearer $token',
      },
    );

    if (response.statusCode == 200) {

      setState(() {
        plagas =
            jsonDecode(response.body);
      });
    }
  }

  Future<void> guardarPlaga() async {

    final cantidad =
        double.tryParse(
      cantidadController.text,
    );

    final hectareas =
        double.tryParse(
      hectareasController.text,
    );

    if (cantidad == null ||
        hectareas == null ||
        cultivoSeleccionado == null ||
        unidadSeleccionada == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Completa todos los campos',
          ),
        ),
      );

      return;
    }

    final url = idEditando == null
        ? 'http://localhost:3000/plagas'
        : 'http://localhost:3000/plagas/$idEditando';

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

                  'id_cultivo':
                      cultivoSeleccionado,

                  'tipo_plaga':
                      tipoPlagaController.text,

                  'tratamiento':
                      tratamientoController.text,

                  'cantidad_aplicada':
                      cantidad,

                  'unidad':
                      unidadSeleccionada,

                  'hectareas_fumigadas':
                      hectareas,
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

                  'id_cultivo':
                      cultivoSeleccionado,

                  'tipo_plaga':
                      tipoPlagaController.text,

                  'tratamiento':
                      tratamientoController.text,

                  'cantidad_aplicada':
                      cantidad,

                  'unidad':
                      unidadSeleccionada,

                  'hectareas_fumigadas':
                      hectareas,
                }),
              );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      limpiarCampos();

      if (mounted) {
        Navigator.pop(context);
      }

      obtenerPlagas();
    }
  }

  Future<void> eliminarPlaga(
      int id) async {

    await http.delete(
      Uri.parse(
        'http://localhost:3000/plagas/$id',
      ),
      headers: {
        'Authorization':
            'Bearer $token',
      },
    );

    obtenerPlagas();
  }

  void limpiarCampos() {

    tipoPlagaController.clear();

    tratamientoController.clear();

    cantidadController.clear();

    hectareasController.clear();

    cultivoSeleccionado = null;

    unidadSeleccionada = null;

    idEditando = null;
  }

  void mostrarFormulario({
    Map? plaga,
  }) {

    if (plaga != null) {

      idEditando =
          plaga['id_plaga'];

      cultivoSeleccionado =
          plaga['id_cultivo'];

      tipoPlagaController.text =
          plaga['tipo_plaga'];

      tratamientoController.text =
          plaga['tratamiento'];

      cantidadController.text =
          plaga['cantidad_aplicada']
              .toString();

      hectareasController.text =
          plaga['hectareas_fumigadas']
              .toString();

      unidadSeleccionada =
          plaga['unidad'];
    }

    showDialog(
      context: context,

      builder: (_) {

        return AlertDialog(

          title: Text(

            plaga == null
                ? 'Nueva Fumigación'
                : 'Editar Fumigación',
          ),

          content:
              SingleChildScrollView(

            child: Column(

              mainAxisSize:
                  MainAxisSize.min,

              children: [

                DropdownButtonFormField<int>(

                  initialValue:
                      cultivoSeleccionado,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Cultivo',
                  ),

                  items: cultivos
                      .map<
                          DropdownMenuItem<
                              int>>(
                    (cultivo) {

                      return DropdownMenuItem<
                          int>(

                        value:
                            cultivo[
                                'id_cultivo'],

                        child: Text(
                          '${cultivo['tipo_cultivo']} - ${cultivo['variedad']}',
                        ),
                      );
                    },
                  ).toList(),

                  onChanged: (v) {
                    cultivoSeleccionado =
                        v;
                  },
                ),

                TextField(
                  controller:
                      tipoPlagaController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Tipo de Plaga',
                  ),
                ),

                TextField(
                  controller:
                      tratamientoController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Tratamiento',
                  ),
                ),

                TextField(
                  controller:
                      cantidadController,

                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),

                  inputFormatters: [

                    FilteringTextInputFormatter
                        .allow(
                      RegExp(
                        r'^\d*\.?\d*',
                      ),
                    ),
                  ],

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Cantidad Aplicada',
                  ),
                ),

                DropdownButtonFormField<
                    String>(

                  initialValue:
                      unidadSeleccionada,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Unidad',
                  ),

                  items: unidades
                      .map(
                        (u) =>
                            DropdownMenuItem(
                          value: u,
                          child:
                              Text(u),
                        ),
                      )
                      .toList(),

                  onChanged: (v) {
                    unidadSeleccionada =
                        v;
                  },
                ),

                TextField(
                  controller:
                      hectareasController,

                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),

                  inputFormatters: [

                    FilteringTextInputFormatter
                        .allow(
                      RegExp(
                        r'^\d*\.?\d*',
                      ),
                    ),
                  ],

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Hectáreas Fumigadas',
                  ),
                ),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton(
              onPressed:
                  guardarPlaga,
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

  void _onItemTapped(int index) {

    if (index == 1) return;

    if (index == 0) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
      );

    } else if (index == 2) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ReportesScreen(),
        ),
      );

    } else if (index == 3) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileScreen(),
        ),
      );
    }
  }

  Widget plagaCard(Map item) {

    return GestureDetector(

      onTap: () =>
          mostrarFormulario(
        plaga: item,
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

                const Icon(
                  Icons.bug_report,
                  color:
                      Color(
                    0xFF6B7F66,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    item[
                        'tipo_plaga'],
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                      fontSize: 16,
                    ),
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
                    eliminarPlaga(
                      item[
                          'id_plaga'],
                    );
                  },
                ),
              ],
            ),

            const Divider(),

            Text('${item['tipo_cultivo']} - ${item['variedad']}',
            style: const TextStyle(color: Colors.black54,fontWeight: FontWeight.w500,),
            ),

            const SizedBox(height: 8),

            Row(
              children: [

                const Icon(
                  Icons.medication_outlined,
                  size: 16,
                  color: Color(0xFF6B7F66),
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    item['tratamiento'],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [

                const Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: Color(0xFF6B7F66),
                ),

                const SizedBox(width: 6),

                Text(
                  '${item['cantidad_aplicada']} ${item['unidad']}',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [

                const Icon(
                  Icons.crop_square,
                  size: 16,
                  color: Color(0xFF6B7F66),
                ),

                const SizedBox(width: 6),

                Text(
                  '${item['hectareas_fumigadas']} ha',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF5F1ED,
      ),

      body: Column(

        children: [

          Container(

            width:
                double.infinity,

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 20,
              vertical: 25,
            ),

            decoration:
                const BoxDecoration(

              color: Color(
                0xFF6B7F66,
              ),

              borderRadius:
                  BorderRadius.only(

                bottomLeft:
                    Radius.circular(
                  25,
                ),

                bottomRight:
                    Radius.circular(
                  25,
                ),
              ),
            ),

            child: SafeArea(

              child: Row(

                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  Row(
                    children: [

                      IconButton(
                        icon:
                            const Icon(
                          Icons
                              .arrow_back,
                          color:
                              Colors
                                  .white,
                        ),
                        onPressed:
                            () =>
                                Navigator.pop(
                          context,
                        ),
                      ),

                      const Icon(
                        Icons
                            .bug_report,
                        color:
                            Colors
                                .white,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Text(
                        'Cafe Nova',
                        style:
                            TextStyle(
                          color:
                              Colors
                                  .white,
                          fontSize:
                              16,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    nombreUsuario,
                    style:
                        const TextStyle(
                      color:
                          Colors
                              .white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(

            child:
                SingleChildScrollView(

              padding:
                  const EdgeInsets
                      .all(
                16,
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  const Text(
                    'Control de Plagas',
                    style:
                        TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  if (plagas.isEmpty)

                    const Center(
                      child:
                          Padding(
                        padding:
                            EdgeInsets
                                .all(
                          40,
                        ),
                        child: Text(
                          'No hay registros de fumigación',
                        ),
                      ),
                    )

                  else

                    ...plagas.map(
                      (item) =>
                          plagaCard(
                        item,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton(

        backgroundColor:
            const Color(
          0xFF6B7F66,
        ),

        onPressed: () =>
            mostrarFormulario(),

        child:
            const Icon(
          Icons.add,
        ),
      ),

      bottomNavigationBar:
          AppBottomNav(
        currentIndex:
            _selectedIndex,
        onTabSelected:
            _onItemTapped,
      ),
    );
  }
}