import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/conversacion_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List contactos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerContactos();
  }

  Future<void> obtenerContactos() async {
    try {
      final token = await SessionService.getToken();

      final response = await http.get(
        Uri.parse('https://cafenova-app-production.up.railway.app/chat/contactos'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          contactos = jsonDecode(response.body);
          cargando = false;
        });
      } else {
        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),

      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFF6B7F66),
        foregroundColor: Colors.white,
      ),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : contactos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay contactos disponibles',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: contactos.length,
                  itemBuilder: (context, index) {
                    final contacto = contactos[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF6B7F66),
                          child: Text(
                            contacto['nombre_usuario']
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        title: Text(
                          contacto['nombre_usuario'],
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          contacto['cargo'],
                        ),

                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ConversacionScreen(
                                idEmpleado:
                                    contacto[
                                        'id_empleado'],
                                nombre:
                                    contacto[
                                        'nombre_usuario'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}