import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/session_service.dart';

class UsuariosPendientesScreen extends StatefulWidget {
  const UsuariosPendientesScreen({super.key});

  @override
  State<UsuariosPendientesScreen> createState() =>
      _UsuariosPendientesScreenState();
}

class _UsuariosPendientesScreenState
    extends State<UsuariosPendientesScreen> {

  List usuarios = [];
  bool cargando = true;

  String? token;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  // ================= INIT =================
  Future<void> initApp() async {
    token = await SessionService.getToken();

    if (token == null) return;

    await obtenerPendientes();
  }

  // ================= API =================
  Future<void> obtenerPendientes() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/usuarios/pendientes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          usuarios = jsonDecode(response.body);
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> aprobarUsuario(int id) async {
    await http.put(
      Uri.parse('http://localhost:3000/usuarios/aprobar/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({"rol": "empleado"}),
    );

    obtenerPendientes();
  }

  Future<void> rechazarUsuario(int id) async {
    await http.delete(
      Uri.parse('http://localhost:3000/usuarios/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    obtenerPendientes();
  }

  // ================= UI =================
  void confirmarAccion(int id, bool aprobar) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(aprobar ? "Aprobar usuario" : "Rechazar usuario"),
        content: Text(
          aprobar
              ? "¿Deseas aprobar este usuario?"
              : "¿Deseas rechazar este usuario?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              aprobar
                  ? aprobarUsuario(id)
                  : rechazarUsuario(id);
            },
            child: Text(aprobar ? "Aprobar" : "Rechazar"),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text("Pendientes",
                      style: TextStyle(color: Colors.white))
                ],
              ),
            ),
          ),

          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : usuarios.isEmpty
                    ? const Center(
                        child: Text("No hay usuarios pendientes"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final user = usuarios[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['nombre_usuario'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text("Correo: ${user['correo'] ?? '-'}"),

                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          confirmarAccion(
                                              user['id_usuario'],
                                              false),
                                      child: const Text("Rechazar"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          confirmarAccion(user['id_usuario'] ?? user['id'], true),
                                      child: const Text("Aprobar"),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}