import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/services/session_service.dart';

class ConversacionScreen extends StatefulWidget {
  final int idEmpleado;
  final String nombre;

  const ConversacionScreen({
    super.key,
    required this.idEmpleado,
    required this.nombre,
  });

  @override
  State<ConversacionScreen> createState() =>
      _ConversacionScreenState();
}

class _ConversacionScreenState
    extends State<ConversacionScreen> {

  final TextEditingController mensajeController =
      TextEditingController();

  List mensajes = [];

  int miIdEmpleado = 0;

  bool cargando = true;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    iniciarChat();
  }

  Future<void> iniciarChat() async {

    final datos =
        await SessionService.getDatosSesion();

    miIdEmpleado =
        datos['id_empleado'] ?? 0;

    await obtenerMensajes();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => obtenerMensajes(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    mensajeController.dispose();
    super.dispose();
  }

  Future<void> obtenerMensajes() async {

    try {

      final token =
          await SessionService.getToken();

      final response = await http.get(
        Uri.parse(
          'http://localhost:3000/chat/${widget.idEmpleado}',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      if (response.statusCode == 200) {

        if (!mounted) return;

        setState(() {

          mensajes =
              jsonDecode(response.body);

          cargando = false;
        });
      }

    } catch (_) {}
  }

  Future<void> enviarMensaje() async {

    final texto =
        mensajeController.text.trim();

    if (texto.isEmpty) return;

    try {

      final token =
          await SessionService.getToken();

      final response = await http.post(
        Uri.parse(
          'http://localhost:3000/chat',
        ),
        headers: {
          'Authorization':
              'Bearer $token',

          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'id_destinatario':
              widget.idEmpleado,

          'mensaje': texto,
        }),
      );

      if (response.statusCode == 200) {

        mensajeController.clear();

        await obtenerMensajes();
      }

    } catch (_) {}
  }

  Widget burbujaMensaje(
      Map<String, dynamic> mensaje) {

    final bool esMio =
        mensaje['id_remitente'] ==
        miIdEmpleado;

    return Align(
      alignment: esMio
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 10,
        ),

        padding: const EdgeInsets.all(12),

        constraints: const BoxConstraints(
          maxWidth: 280,
        ),

        decoration: BoxDecoration(
          color: esMio
              ? const Color(0xFF6B7F66)
              : Colors.grey.shade300,

          borderRadius:
              BorderRadius.circular(15),
        ),

        child: Text(
          mensaje['mensaje'] ?? '',
          style: TextStyle(
            color: esMio
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F1ED),

      appBar: AppBar(
        title: Text(widget.nombre),
        backgroundColor:
            const Color(0xFF6B7F66),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [

          Expanded(
            child: cargando
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount:
                        mensajes.length,

                    itemBuilder:
                        (context, index) {

                      return burbujaMensaje(
                        mensajes[index],
                      );
                    },
                  ),
          ),

          Container(
            padding:
                const EdgeInsets.all(10),

            color: Colors.white,

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller:
                        mensajeController,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Escribe un mensaje...',

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                15),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  onPressed:
                      enviarMensaje,

                  icon: const Icon(
                    Icons.send,
                    color:
                        Color(0xFF6B7F66),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}