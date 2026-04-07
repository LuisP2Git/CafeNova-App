import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:frontend/services/session_service.dart';

class IAScreen extends StatefulWidget {
  const IAScreen({Key? key}) : super(key: key);

  @override
  State<IAScreen> createState() => _IAScreenState();
}

class _IAScreenState extends State<IAScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> mensajes = [];
  bool cargando = false;
  String? token;

  @override
  void initState() {
    super.initState();
    initIA();
  }

  Future<void> initIA() async {
    token = await SessionService.getToken();
    await cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.3.145.98:3000/ia/historial'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      final data = jsonDecode(response.body);

      setState(() {
        mensajes = [];

        for (var item in data) {
          mensajes.add({"tipo": "user", "texto": item['mensaje']});
          mensajes.add({"tipo": "ia", "texto": item['respuesta']});
        }
      });

      scrollAbajo();
    } catch (e) {
      print("Error historial: $e");
    }
  }

  Future<void> preguntarIA() async {
    if (_controller.text.isEmpty) return;

    String pregunta = _controller.text;

    setState(() {
      mensajes.add({"tipo": "user", "texto": pregunta});
      cargando = true;
      _controller.clear();
    });

    scrollAbajo();

    try {
      final response = await http.post(
        Uri.parse('http://10.3.145.98:3000/ia'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'pregunta': pregunta}),
      );

      final data = jsonDecode(response.body);

      setState(() {
        mensajes.add({"tipo": "ia", "texto": data['respuesta']});
      });

    } catch (e) {
      setState(() {
        mensajes.add({"tipo": "ia", "texto": "Error conectando con IA"});
      });
    }

    setState(() {
      cargando = false;
    });

    scrollAbajo();
  }

  void scrollAbajo() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Widget mensajeBubble(Map<String, String> msg) {
    bool esUsuario = msg["tipo"] == "user";

    return Row(
      mainAxisAlignment:
          esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!esUsuario)
          const CircleAvatar(
            backgroundColor: Color(0xFF6B7F66),
            child: Icon(Icons.smart_toy, color: Colors.white),
          ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 5),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: esUsuario
                ? const Color(0xFFB7D7B0)
                : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: MarkdownBody(
            data: msg["texto"] ?? '',
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(width: 8),

        if (esUsuario)
          const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6B7F66),
        title: const Text("Asistente IA"),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              children: [
                ...mensajes.map(mensajeBubble),

                if (mensajes.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    child: Column(
                      children: const [
                        Icon(Icons.smart_toy, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("¿En qué puedo ayudarte?",
                            style: TextStyle(fontSize: 16))
                      ],
                    ),
                  )
              ],
            ),
          ),

          if (cargando)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe tu pregunta...",
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: preguntarIA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7F66),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Enviar"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}