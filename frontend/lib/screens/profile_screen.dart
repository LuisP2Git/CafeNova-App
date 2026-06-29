import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/session_service.dart';
import 'package:frontend/screens/lotes_screen.dart';
import 'package:frontend/screens/reportes_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/utils/responsive.dart';
import 'package:frontend/utils/app_spacing.dart';
import 'package:frontend/utils/mensajes.dart';
import 'package:frontend/widgets/responsive_card.dart';
import 'package:frontend/services/api_service.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int get selectedIndex {
  final puedeVerReportes =
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo';

  return puedeVerReportes ? 3 : 2;
}
  bool _pressed = false;
  String nombre = '';
  String correo = '';
  String rol = '';
  String cargo = '';

  final editarNombreController = TextEditingController();
  final editarCorreoController = TextEditingController();
  final editarTelefonoController = TextEditingController();

  final actualPasswordController = TextEditingController();
  final nuevaPasswordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _mostrarConfirmar = false;

  @override
  void initState() {
  super.initState();
  _cargarDatosSesion();
}

  Future<void> _cargarDatosSesion() async {
    final datos = await SessionService.getDatosSesion();
    if (!mounted) return;
    setState(() {
      nombre = datos['nombre'] ?? '';
      correo = datos['correo'] ?? '';
      rol = datos['rol'] ?? '';
      cargo = datos['cargo'] ?? '';
    });
  }

  Future<void> logout(BuildContext context) async {
    await SessionService.cerrarSesion();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _mostrarEditarPerfil() {
  editarNombreController.text = nombre;
  editarCorreoController.text = correo;
  editarTelefonoController.text = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Editar perfil"),
        content: SizedBox(
          width: Responsive.dialogWidth(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: editarNombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: editarCorreoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo",
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: editarTelefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _guardarPerfil,
            child: const Text("Guardar"),
          ),
        ],
      );
    },
  );
}

    Future<void> _guardarPerfil() async {

  if (editarNombreController.text.trim().isEmpty) {
  Mensajes.mostrar(
    context,
    "Ingrese un nombre",
    esError: true,
  );
  return;
}

if (editarCorreoController.text.trim().isEmpty) {
  Mensajes.mostrar(
    context,
    "Ingrese un correo",
    esError: true,
  );
  return;
}

if (!editarCorreoController.text.contains('@')) {
  Mensajes.mostrar(
    context,
    "Correo inválido",
    esError: true,
  );
  return;
}


  try {
    final datos = await SessionService.getDatosSesion();

    final token = datos['token'];

    final ok = await ApiService.actualizarPerfil(
      token,
      nombre: editarNombreController.text.trim(),
      correo: editarCorreoController.text.trim(),
      telefono: editarTelefonoController.text.trim(),
    );

    if (!ok) {
      Mensajes.mostrar(
        context,
        "No fue posible actualizar el perfil",
        esError: true,
      );
      return;
    }

    await SessionService.guardarSesion(
      token: token,
      nombre: editarNombreController.text.trim(),
      correo: editarCorreoController.text.trim(),
      rol: datos['rol'],
      cargo: datos['cargo'],
      idFinca: datos['id_finca'],
      idEmpleado: datos['id_empleado'],
    );

    setState(() {
      nombre = editarNombreController.text.trim();
      correo = editarCorreoController.text.trim();
    });

    if (!mounted) return;

    Navigator.pop(context);

    Mensajes.mostrar(
      context,
      "Perfil actualizado correctamente",
    );

  } catch (e) {
    Mensajes.mostrar(
      context,
      "Error al actualizar el perfil",
      esError: true,
    );
  }
}

  Future<void> _cambiarPassword() async {
    if (actualPasswordController.text.isEmpty ||
        nuevaPasswordController.text.isEmpty ||
        confirmarPasswordController.text.isEmpty) {
      Mensajes.mostrar(
        context,
        "Completa todos los campos",
        esError: true,
      );
      return;
    }
    if (nuevaPasswordController.text !=
        confirmarPasswordController.text) {
      Mensajes.mostrar(
        context,
        "Las contraseñas no coinciden",
        esError: true,
      );
      return;
    }
    if (nuevaPasswordController.text.length < 6) {
      Mensajes.mostrar(
        context,
        "La contraseña debe tener mínimo 6 caracteres",
        esError: true,
      );
      return;
    }
    if (actualPasswordController.text == nuevaPasswordController.text) {
      Mensajes.mostrar(
        context,
        "La nueva contraseña debe ser diferente a la actual",
        esError: true,
      );
      return;
    }
    try {
      final datos = await SessionService.getDatosSesion();
      final ok = await ApiService.cambiarPassword(
        datos['token'],
        passwordActual: actualPasswordController.text,
        passwordNueva: nuevaPasswordController.text,
      );
      if (!ok) {
        Mensajes.mostrar(
          context,
          "No fue posible cambiar la contraseña",
          esError: true,
        );
        return;
      }
      actualPasswordController.clear();
      nuevaPasswordController.clear();
      confirmarPasswordController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      Mensajes.mostrar(
        context,
        "Contraseña actualizada correctamente",
      );
    } catch (e) {
      Mensajes.mostrar(
        context,
        "Error al cambiar la contraseña",
        esError: true,
      );
    }
  }

  void _mostrarDialogoCambiarPassword() {
  actualPasswordController.clear();
  nuevaPasswordController.clear();
  confirmarPasswordController.clear();
  _mostrarActual = false;
  _mostrarNueva = false;
  _mostrarConfirmar = false;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: SizedBox(
          width: Responsive.dialogWidth(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: actualPasswordController,
                obscureText: !_mostrarActual,
                decoration: InputDecoration(
                  labelText: "Contraseña actual",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarActual
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarActual = !_mostrarActual;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nuevaPasswordController,
                obscureText: !_mostrarNueva,
                decoration: InputDecoration(
                  labelText: "Nueva contraseña",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarNueva
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarNueva = !_mostrarNueva;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmarPasswordController,
                obscureText: !_mostrarConfirmar,
                decoration: InputDecoration(
                  labelText: "Confirmar contraseña",
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarConfirmar
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmar = !_mostrarConfirmar;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _cambiarPassword,
            child: const Text("Guardar"),
          ),
        ],
      );
    },
  );
}

  void _onItemTapped(int index) async {

  final bool puedeVerReportes =
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo';

  if (index == 0) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeScreen(),
    ),
    (route) => false,
  );
  return;
}

  if (!mounted) return;

  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LotesScreen(),
      ),
    );
    return;
  }

  if (puedeVerReportes) {

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ReportesScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }

  } else {

    // Para usuarios sin acceso a reportes,
    // el índice 2 es Perfil.
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {

    
    final inicial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: Responsive.screenPadding(context),
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
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: AppSpacing.md),
                  Text('Perfil',
                      style: TextStyle(color: Colors.white, fontSize: Responsive.subtitleSize(context),)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          CircleAvatar(
            radius: Responsive.isMobile(context) ? 45 : 60,
            backgroundColor: const Color(0xFF6B7F66),
            child: Text(
              inicial,
              style: TextStyle(
                  fontSize: Responsive.titleSize(context) + 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          Text(nombre, style: TextStyle
          (fontSize: Responsive.subtitleSize(context) + 4, fontWeight: FontWeight.bold,),
          ),
          Text(
            correo.isNotEmpty ? correo : 'Sin correo registrado',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          if (rol.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: rol == 'admin'
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rol.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rol == 'admin'
                        ? Colors.green.shade800
                        : Colors.blue.shade800),
              ),
            ),

          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.screenPadding(context),
              child: Column(
                children: [
                  _cardItem(Icons.email_outlined, 'Correo', correo),
                  const SizedBox(height: AppSpacing.md),
                  _cardItem(Icons.badge_outlined, 'Rol', rol.isNotEmpty ? rol : '-'),
                  const SizedBox(height: AppSpacing.md),
                  _cardItem(Icons.work_outline, 'Cargo', cargo.isNotEmpty ? cargo : '-',),
                  const SizedBox(height: AppSpacing.md),
                  _cardItem(Icons.edit_outlined, 'Editar perfil', null, onTap: _mostrarEditarPerfil,),
                  const SizedBox(height: AppSpacing.md),
                  _cardItem(Icons.lock_outline, 'Cambiar contraseña', null, onTap: _mostrarDialogoCambiarPassword,),
                  const SizedBox(height: AppSpacing.md),
                  _cardItem(Icons.sync, 'Sincronizar datos', null,
                      onTap: () {}),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: () => logout(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _pressed
                            ? Colors.red.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              offset: const Offset(2, 2))
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Cerrar sesión',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: AppBottomNav(
  currentIndex: selectedIndex,
  onTabSelected: _onItemTapped,
  puedeVerReportes:
      rol == 'admin' ||
      cargo == 'Auxiliar Administrativo',
),
    );
  }

  Widget _cardItem(IconData icon, String label, String? value,
      {VoidCallback? onTap}) {
    return ResponsiveCard(
      onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7F66)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (value != null && value.isNotEmpty)
                    Text(value,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey),
          ],
        ),
    );
  }

  @override
  void dispose() {
    editarNombreController.dispose();
    editarCorreoController.dispose();
    editarTelefonoController.dispose();
    actualPasswordController.dispose();
    nuevaPasswordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }
}
