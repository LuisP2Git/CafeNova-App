import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> guardarSesion({
    required String token,
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('nombre', nombre);
    await prefs.setString('correo', correo);
    await prefs.setString('rol', rol);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}