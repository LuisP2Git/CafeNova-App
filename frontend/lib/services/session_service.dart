import 'package:shared_preferences/shared_preferences.dart';

class SessionService {

  static Future<void> guardarSesion({
    required String token,
    required String nombre,
    required String correo,
    required String rol,

    String cargo = '',
    int idFinca = 0,
    int idEmpleado = 0,
  }) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('nombre', nombre);
    await prefs.setString('correo', correo);
    await prefs.setString('rol', rol);

    await prefs.setString('cargo', cargo);
    await prefs.setInt('id_finca', idFinca);
    await prefs.setInt('id_empleado', idEmpleado);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  static Future<String?> getCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('correo');
  }

  static Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }

  static Future<String?> getCargo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cargo');
  }

  static Future<int?> getIdFinca() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_finca');
  }

  static Future<int?> getIdEmpleado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_empleado');
  }

  static Future<Map<String, dynamic>> getDatosSesion() async {

    final prefs = await SharedPreferences.getInstance();

    return {
      'token': prefs.getString('token') ?? '',
      'nombre': prefs.getString('nombre') ?? '',
      'correo': prefs.getString('correo') ?? '',
      'rol': prefs.getString('rol') ?? '',
      'cargo': prefs.getString('cargo') ?? '',
      'id_finca': prefs.getInt('id_finca') ?? 0,
      'id_empleado': prefs.getInt('id_empleado') ?? 0,
    };
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}