import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:frontend/utils/mensajes.dart';
import 'package:frontend/utils/responsive.dart';
import 'package:frontend/utils/app_spacing.dart';

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
  int? idFinca;
  
  String? cargoSeleccionado;


  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  bool _presionandoLogin = false;

  bool esPasswordSegura(String password) {
  final regex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&._#])[A-Za-z\d@$!%*?&._#]{8,}$',
  );

  return regex.hasMatch(password);
}

final List<String> cargos = [
  'Administrador',
  'Auxiliar Administrativo',
  'Operario de Campo',
  'Fumigador',
  'Recolector',
  'Pesador',
  'Operario de Procesamiento',
];

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      Mensajes.mostrar(context, 'Las contraseñas no coinciden', esError: true);
      return;
    }
    if (!esPasswordSegura(passwordController.text)) {
  Mensajes.mostrar(
    context,
    'La contraseña debe tener mínimo 8 caracteres, una mayúscula, una minúscula, un número y un símbolo.',
    esError: true,
  );
  return;
}
    if (telefonoController.text.length != 10) {
      Mensajes.mostrar(context, 'El teléfono debe tener 10 dígitos', esError: true);
      return;
    }

    if (fechaSeleccionada == null) {
      Mensajes.mostrar(context, 'Selecciona la fecha', esError: true);
      return;
    }

    final url = Uri.parse('https://cafenova-app-production.up.railway.app/registro');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': usuarioController.text.trim(),
          'correo': correoController.text.trim(),
          'password': passwordController.text,
          'cargo': cargoSeleccionado,
          'telefono': telefonoController.text.trim(),
          'fecha_contratacion':
              "${fechaSeleccionada!.year}-${fechaSeleccionada!.month.toString().padLeft(2, '0')}-${fechaSeleccionada!.day.toString().padLeft(2, '0')}",
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
    return Scaffold(
      backgroundColor: const Color(0xFFDCD6D0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: Responsive.formWidth(context),
              margin: Responsive.screenPadding(context),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
                ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1ED),
                borderRadius: BorderRadius.circular(20),
                ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Icon(Icons.eco, size: Responsive.logoSize(context), color: const Color(0xFF8BC45D),),
                    const SizedBox(height: AppSpacing.xl),
                    Text("CafeNova", style: TextStyle(
                      fontSize: Responsive.titleSize(context) + 8,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7F66),
                      ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text("Crear cuenta",
                      style: TextStyle(
                      fontSize: Responsive.subtitleSize(context),
                      color: const Color(0xFF4F584C),
                      fontWeight: FontWeight.w500,
                      ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    campo(usuarioController, "Nombre de usuario"),
                    campo(correoController, "Correo electrónico"),
                    campo(passwordController, "Contraseña", obscure: true),
                    campo(confirmPasswordController, "Confirmar contraseña", obscure: true),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.md,
                        ),
                      child: DropdownButtonFormField<String>(
                        initialValue: cargoSeleccionado,
                        decoration: InputDecoration(
                          hintText: "Seleccione un cargo",
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: cargos.map((cargo) {
                          return DropdownMenuItem<String>(
                            value: cargo,
                            child: Text(cargo),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            cargoSeleccionado = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un cargo';
                          }
                          return null;
                        },
                      ),
                    ),
                    campo(
                      telefonoController,
                      "Teléfono",
                      keyboard: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    TextFormField(
                      controller: fechaController,
                      textInputAction: TextInputAction.done,
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
                    const SizedBox(height: AppSpacing.xl,),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: registrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7F66),
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.buttonHeight(context) / 3,
                          ),
                        ),
                        child: Text(
                          "Crear cuenta",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.bodySize(context),
                            fontWeight: FontWeight.w600,
                            ),
                          ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: const Color(0xFF6B7F66).withValues(alpha: 0.15),
                        highlightColor: const Color(0xFF6B7F66).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          setState(() => _presionandoLogin = true);
                          await Future.delayed(
                            const Duration(milliseconds: 120),
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          setState(() => _presionandoLogin = false);
                        },
                        child: AnimatedScale(
                          scale: _presionandoLogin ? 0.97 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _presionandoLogin
                                  ? const Color(0xFF6B7F66).withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "¿Ya tienes cuenta? Inicia sesión",
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
        ),
      ),
    );
  }

Widget campo(
  TextEditingController controller,
  String hint, {
  bool obscure = false,
  TextInputType keyboard = TextInputType.text,
  int? maxLength,
  List<TextInputFormatter>? inputFormatters,
  }) {
    bool esPassword =
      controller == passwordController ||
      controller == confirmPasswordController;
      return Padding(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.md,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: esPassword
            ? (controller == passwordController
            ? !_mostrarPassword
            : !_mostrarConfirmPassword)
            : false,
            keyboardType: keyboard,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                  ),
                suffixIcon: esPassword
                ? IconButton(
                  icon: Icon(
                    controller == passwordController
                        ? (_mostrarPassword
                            ? Icons.visibility
                            : Icons.visibility_off)
                        : (_mostrarConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                            ),
                          onPressed: () {
                            setState(() {
                              if (controller == passwordController) {
                                _mostrarPassword = !_mostrarPassword;
                                } else {
                                  _mostrarConfirmPassword =
                                  !_mostrarConfirmPassword;
                                }
                              }
                            );
                          },
                  )
              : null,
          ),
        ),
      );
    }

  @override
  void dispose() {
    usuarioController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    cargoController.dispose();
    telefonoController.dispose();
    fechaController.dispose();
    super.dispose();
  }
}

