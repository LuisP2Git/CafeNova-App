import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/mensajes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final usuarioController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final cargoController = TextEditingController();
  final telefonoController = TextEditingController();
  final fechaController = TextEditingController();

  DateTime? fechaSeleccionada;
  int idFinca = 1;

  bool esCorreoValido(String correo) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(correo);
  }

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      Mensajes.mostrar(context, 'Las contraseñas no coinciden', esError: true);
      return;
    }

    final url = Uri.parse('http://localhost:3000/registro');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': usuarioController.text.trim(),
          'correo': correoController.text.trim(),
          'password': passwordController.text,
          'cargo': cargoController.text.trim(),
          'telefono': telefonoController.text.trim(),
          'fecha_contratacion': fechaController.text,
          'id_finca': idFinca,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Mensajes.mostrar(context, 'Registro exitoso');
        Navigator.pop(context);
      } else {
        Mensajes.mostrar(context, data['error'], esError: true);
      }
    } catch (e) {
      Mensajes.mostrar(context, 'Error de conexión', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {

    final height = MediaQuery.of(context).size.height;

    final iconSize = height < 700 ? 80.0 : 120.0;
    final titleSize = height < 700 ? 35.0 : 50.0;
    final spacing = height < 700 ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    width: constraints.maxWidth > 600 ? 500 : double.infinity,
                    margin: const EdgeInsets.all(15),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1ED),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Icon(Icons.eco,
                              size: iconSize,
                              color: const Color.fromARGB(255, 139, 196, 93)),

                          SizedBox(height: spacing),

                          Text(
                            "Cafenova",
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B7F66),
                            ),
                          ),

                          SizedBox(height: spacing),

                          const Text(
                            "Crear cuenta",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 79, 88, 76),
                            ),
                          ),

                          SizedBox(height: spacing * 2),

                          campo(usuarioController, "Nombre de usuario"),
                          campo(correoController, "Correo electrónico"),

                          campo(passwordController, "Contraseña", obscure: true),
                          campo(confirmPasswordController, "Confirmar contraseña", obscure: true),

                          campo(cargoController, "Cargo"),

                          campo(telefonoController, "Teléfono",
                              keyboard: TextInputType.number, maxLength: 10),

                          TextFormField(
                            controller: fechaController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Fecha de contratación",
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  fechaSeleccionada = picked;
                                  fechaController.text =
                                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                          ),

                          SizedBox(height: spacing * 2),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: registrar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B7F66),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Crear cuenta",
                                style: TextStyle(
                                  color: Color(0xFFF5F1ED),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: spacing),

                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Ya tienes cuenta? Inicia sesión",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget campo(TextEditingController controller, String hint,
      {bool obscure = false,
      TextInputType keyboard = TextInputType.text,
      int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}