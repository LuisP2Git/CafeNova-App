import 'package:flutter/material.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/mensajes.dart';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/utils/responsive.dart';
import 'package:frontend/utils/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final usuarioController = TextEditingController();
  final passwordController = TextEditingController();
  bool _mostrarPassword = false;
  bool _presionandoRegistro = false;

  Future<void> login() async {
    final url = Uri.parse('https://cafenova-app-production.up.railway.app/login');

    try {
      if (usuarioController.text.isEmpty || passwordController.text.isEmpty) {
        Mensajes.mostrar(context, 'Completa todos los campos', esError: true);
        return;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identificador': usuarioController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SessionService.guardarSesion(
          token: data['token'],
          nombre: data['usuario']['nombre_usuario'],
          correo: data['usuario']['correo'],
          rol: data['usuario']['rol'],

          cargo: data['usuario']['cargo'] ?? '',
          idFinca: data['usuario']['id_finca'] ?? 0,
          idEmpleado: data['usuario']['id_empleado'] ?? 0,
          
        );

        // ignore: unused_local_variable
        final cargo = data['usuario']['cargo'] ?? '';

        Mensajes.mostrar(context, 'Login exitoso');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(
            mostrarBienvenida: true,
          ),
        ),
      );

      } else if (response.statusCode == 403) {
        Mensajes.mostrar(
          context,
          'Tu cuenta está pendiente de aprobación',
          esError: true,
        );
      } else {
        Mensajes.mostrar(context, data['error'] ?? 'Error', esError: true);
      }

    } catch (e) {
      Mensajes.mostrar(context, 'Error de conexión', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    width: Responsive.formWidth(context),
                    margin: Responsive.screenPadding(context),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl,),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1ED),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Icon(
                          Icons.eco,
                          size: Responsive.logoSize(context),
                          color: const Color.fromARGB(255, 139, 196, 93),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Text(
                          "CafeNova",
                          style: TextStyle(
                            fontSize: Responsive.titleSize(context) + 8,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B7F66),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Text(
                          "Te damos la bienvenida a cafenova",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.subtitleSize(context),
                            color: const Color.fromARGB(255, 79, 88, 76),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Text(
                          "Para comenzar, inicia sesión.",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 108, 133, 100),
                            fontSize: Responsive.bodySize(context),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        TextField(
                          controller: usuarioController,
                          decoration: InputDecoration(
                            hintText: "Nombre de usuario",
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                      TextField(
                        controller: passwordController,
                          obscureText: !_mostrarPassword,
                          decoration: InputDecoration(
                            hintText: "Contraseña",
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrarPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrarPassword = !_mostrarPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B7F66),
                              padding: EdgeInsets.symmetric(vertical: Responsive.buttonHeight(context) / 3,),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Iniciar sesión",
                              style: TextStyle(
                                color: Color(0xFFF5F1ED),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: const Color(0xFF6B7F66).withValues(alpha: 0.15),
                            highlightColor: const Color(0xFF6B7F66).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              setState(() => _presionandoRegistro = true);
                              await Future.delayed(
                                const Duration(milliseconds: 120),
                              );
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                              if (mounted) {
                                setState(() => _presionandoRegistro = false);
                              }
                            },
                            child: AnimatedScale(
                              scale: _presionandoRegistro ? 0.97 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeInOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: _presionandoRegistro
                                      ? const Color(0xFF6B7F66).withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "¿No tienes cuenta? Regístrate",
                                    style: TextStyle(
                                      color: const Color(0xFF6B7F66),
                                      fontSize: Responsive.bodySize(context),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}