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
    await prefs.setString('correo', correo); // siempre persiste correo
    await prefs.setString('rol', rol);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  /// Recupera el email guardado independientemente del método de login
  static Future<String?> getCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('correo');
  }

  static Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }

  /// Retorna todos los datos de sesión de una vez
  static Future<Map<String, String>> getDatosSesion() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('token') ?? '',
      'nombre': prefs.getString('nombre') ?? '',
      'correo': prefs.getString('correo') ?? '',
      'rol': prefs.getString('rol') ?? '',
    };
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
