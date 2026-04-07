import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://localhost:3000';

  static Map<String, String> headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

  static Future<bool> descargarPDF(String token) async {
  final res = await http.get(
    Uri.parse('$baseUrl/reportes/pdf'),
    headers: headers(token),
  );

  if (res.statusCode == 200) {
    final blob = html.Blob([res.bodyBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final _ = html.AnchorElement(href: url)
      ..setAttribute("download", "reporte.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);
    return true;
  } else {
    return false;
  }
 }
}