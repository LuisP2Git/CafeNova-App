import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://localhost:3000';

  static Map<String, String> headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List> getMensual(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/cosecha-mensual'),
      headers: headers(token),
    );
    return jsonDecode(res.body);
  }

  static Future<List> getCalidad(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/por-calidad'),
      headers: headers(token),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> getTotal(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/total-cosecha'),
      headers: headers(token),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> getMejor(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/mejor-cultivo'),
      headers: headers(token),
    );
    return jsonDecode(res.body);
  }

  static Future<List> getPorFecha(
      String token, String desde, String hasta) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/por-fecha?desde=$desde&hasta=$hasta'),
      headers: headers(token),
    );
    return jsonDecode(res.body);
  }

  /// ✅ NUEVO: cosechas agrupadas por finca
  static Future<List> getCosechasPorFinca(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/reportes/por-finca'),
        headers: headers(token),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      // Fallback: construir agrupación desde cosechas y fincas
      return await _agruparPorFinca(token);
    } catch (e) {
      return await _agruparPorFinca(token);
    }
  }

  /// Construye agrupación cliente-side si el endpoint no existe
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

      if (fincasRes.statusCode != 200 || cosechasRes.statusCode != 200) {
        return [];
      }

      final fincas = (jsonDecode(fincasRes.body) as List);
      final cosechas = (jsonDecode(cosechasRes.body) as List);

      return fincas.map((f) {
        final idFinca = f['id_finca'];
        final cosechasFinca = cosechas.where((c) {
          // Relacionar por id_finca a través del lote
          return c['id_finca']?.toString() == idFinca?.toString();
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

  static Future<bool> descargarPDF(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/reportes/pdf'),
      headers: headers(token),
    );

    if (res.statusCode == 200) {
      final blob = html.Blob([res.bodyBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final _ = html.AnchorElement(href: url)
        ..setAttribute('download', 'reporte_cafenova.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      return true;
    }
    return false;
  }
}
