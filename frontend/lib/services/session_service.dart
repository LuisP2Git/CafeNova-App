import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = 'token';
  static const String _nombreKey = 'nombre';
  static const String _correoKey = 'correo';
  static const String _rolKey = 'rol';
  static const String _cargoKey = 'cargo';
  static const String _idFincaKey = 'id_finca';
  static const String _idEmpleadoKey = 'id_empleado';

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

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nombreKey, nombre);
    await prefs.setString(_correoKey, correo);
    await prefs.setString(_rolKey, rol);
    await prefs.setString(_cargoKey, cargo);

    await prefs.setInt(_idFincaKey, idFinca);
    await prefs.setInt(_idEmpleadoKey, idEmpleado);
  }

  static Future<bool> haySesion() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nombreKey);
  }

  static Future<String?> getCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_correoKey);
  }

  static Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rolKey);
  }

  static Future<String?> getCargo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cargoKey);
  }

  static Future<int> getIdFinca() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_idFincaKey) ?? 0;
  }

  static Future<int> getIdEmpleado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_idEmpleadoKey) ?? 0;
  }

  static Future<Map<String, dynamic>> getDatosSesion() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'token': prefs.getString(_tokenKey) ?? '',
      'nombre': prefs.getString(_nombreKey) ?? '',
      'correo': prefs.getString(_correoKey) ?? '',
      'rol': prefs.getString(_rolKey) ?? '',
      'cargo': prefs.getString(_cargoKey) ?? '',
      'id_finca': prefs.getInt(_idFincaKey) ?? 0,
      'id_empleado': prefs.getInt(_idEmpleadoKey) ?? 0,
    };
  }

  static Future<void> actualizarCargo(String cargo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cargoKey, cargo);
  }

  static Future<void> actualizarFinca(int idFinca) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idFincaKey, idFinca);
  }

  static Future<void> actualizarEmpleado(int idEmpleado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idEmpleadoKey, idEmpleado);
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_nombreKey);
    await prefs.remove(_correoKey);
    await prefs.remove(_rolKey);
    await prefs.remove(_cargoKey);
    await prefs.remove(_idFincaKey);
    await prefs.remove(_idEmpleadoKey);
  }
}