import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'https://cafenova-app-production.up.railway.app';

  // =========================================================
  // HEADERS
  // =========================================================

  static Map<String, String> headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // =========================================================
  // REPORTES - RESUMEN
  // =========================================================

  static Future<List> getMensual(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/cosecha-mensual'),
      headers: headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Error mensual');
    }

    return jsonDecode(res.body);
  }

  static Future<List> getCalidad(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/por-calidad'),
      headers: headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Error calidad');
    }

    return jsonDecode(res.body);
  }

  static Future<Map> getTotal(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/total-cosecha'),
      headers: headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Error total');
    }

    return jsonDecode(res.body);
  }

  static Future<Map> getMejor(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/mejor-cultivo'),
      headers: headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Error mejor cultivo');
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // REPORTES POR FECHA
  // =========================================================

  static Future<List> getPorFecha(
    String token,
    String desde,
    String hasta,
  ) async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/reportes/por-fecha?desde=$desde&hasta=$hasta',
      ),
      headers: headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Error por fecha');
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // REPORTES POR FINCA
  // =========================================================

  /// FIX #2 #3
  /// Obtiene:
  /// finca -> lotes -> cosechas
  static Future<List> getCosechasPorFinca(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/reportes/por-finca'),
        headers: headers(token),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return await _agruparPorFinca(token);
    } catch (e) {
      return await _agruparPorFinca(token);
    }
  }

  // =========================================================
  // FALLBACK CLIENTE-SIDE
  // =========================================================

  static Future<List> _agruparPorFinca(String token) async {
    try {
      final fincasRes = await http.get(
        Uri.parse('$baseUrl/fincas'),
        headers: headers(token),
      );

      final cosechasRes = await http.get(
        Uri.parse('$baseUrl/cosechas'),
        headers: headers(token),
      );

      if (fincasRes.statusCode != 200 ||
          cosechasRes.statusCode != 200) {
        return [];
      }

      final fincas = jsonDecode(fincasRes.body) as List;
      final cosechas = jsonDecode(cosechasRes.body) as List;

      return fincas.map((f) {
        final idFinca = f['id_finca'];

        final cosechasFinca = cosechas.where((c) {
          return c['id_finca']?.toString() ==
              idFinca?.toString();
        }).toList();

        return {
          'id_finca': idFinca,
          'nombre_finca': f['nombre_finca'],
          'cosechas': cosechasFinca,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // =========================================================
  // PDF REPORTES
  // =========================================================

  static Future<bool> descargarPDF(
    String token, {
    int? fincaId,
    int? loteId,
  }) async {
    try {
      final params = <String, String>{};

      if (fincaId != null) {
        params['finca_id'] = fincaId.toString();
      }

      if (loteId != null) {
        params['lote_id'] = loteId.toString();
      }

      final uri = Uri.parse('$baseUrl/reportes/pdf').replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final res = await http.get(
        uri,
        headers: headers(token),
      );

      if (res.statusCode == 200) {
        final blob = html.Blob([res.bodyBytes]);

        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'reporte_cafenova.pdf',
          )
          ..click();

        html.Url.revokeObjectUrl(url);

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // =========================================================
  // GUARDAR REPORTE
  // =========================================================

  static Future<bool> guardarReporte(
    String token, {
    required String titulo,
    required String descripcion,
    required String tipoReporte,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reportes'),
        headers: headers(token),
        body: jsonEncode({
          'titulo': titulo,
          'descripcion': descripcion,
          'tipo_reporte': tipoReporte,
        }),
      );

      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
  // =========================================================
  // PERFIL
  // =========================================================

  static Future<Map<String, dynamic>> obtenerPerfil(
    String token,
    ) async {
      final res = await http.get(
        Uri.parse('$baseUrl/usuarios/perfil'),
        headers: headers(token),
        );
      if (res.statusCode != 200) {
    throw Exception('Error al obtener perfil');
    }
    return jsonDecode(res.body);
  }

  static Future<bool> actualizarPerfil(
    String token, {
    required String nombre,
    required String correo,
    required String telefono,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: headers(token),
      body: jsonEncode({
        'nombre_usuario': nombre,
        'correo': correo,
        'telefono': telefono,
      }),
    );
    return res.statusCode == 200;
  }

  static Future<bool> cambiarPassword(
    String token, {
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/usuarios/password'),
      headers: headers(token),
      body: jsonEncode({
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
      }),
    );
    return res.statusCode == 200;
  }
}