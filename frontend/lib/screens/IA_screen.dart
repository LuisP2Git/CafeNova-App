import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:frontend/services/session_service.dart';

class IAScreen extends StatefulWidget {
  const IAScreen({super.key});

  @override
  State<IAScreen> createState() => _IAScreenState();
}

class _IAScreenState extends State<IAScreen>
    with SingleTickerProviderStateMixin {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> mensajes = [];
  bool cargando = false;
  String? token;

  late TabController _tabController;

  // ─── Estado de análisis de imágenes ────────────────────────────────────────
  Uint8List? _imagenSeleccionada;
  String? _imagenBase64;
  String? _imagenMimeType;
  String? _resultadoImagen;
  bool _analizandoImagen = false;
  String _modoImagen = 'suelo'; // 'suelo' o 'planta'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initIA();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initIA() async {
    token = await SessionService.getToken();
    await _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    try {
      final res = await http.get(
        Uri.parse('https://cafenova-app-production.up.railway.app/ia/historial'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);

setState(() {
  mensajes = [];

  final historial = data['historial'] ?? [];

  for (var item in historial) {

  if (item['tipo'] == 'imagen') {

    mensajes.add({
      'tipo': 'user',
      'esImagen': true,
      'imagen': item['imagen'],
    });

  } else {

    mensajes.add({
      'tipo': 'user',
      'texto': item['mensaje'],
    });
  }

  mensajes.add({
    'tipo': 'ia',
    'texto': item['respuesta'],
  });
}
});
      _scrollAbajo();
    } catch (e) {
      debugPrint('Error historial: $e');
    }
  }

  Future<void> _preguntarIA() async {
    if (_chatController.text.isEmpty) return;
    final pregunta = _chatController.text;
    setState(() {
      mensajes.add({'tipo': 'user', 'texto': pregunta});
      cargando = true;
      _chatController.clear();
    });
    _scrollAbajo();
    try {
      final res = await http.post(
        Uri.parse('https://cafenova-app-production.up.railway.app/ia'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'pregunta': pregunta}),
      );
      final data = jsonDecode(res.body);
      setState(() {
        mensajes.add({'tipo': 'ia', 'texto': data['respuesta']});
      });
    } catch (e) {
      setState(() {
        mensajes.add({'tipo': 'ia', 'texto': 'Error conectando con IA'});
      });
    }
    setState(() => cargando = false);
    _scrollAbajo();
  }

  void _scrollAbajo() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
      }
    });
  }

  // ─── Selección y análisis de imagen ────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (imagen == null) return;
    final bytes = await File(imagen.path).readAsBytes();
    final base64 = base64Encode(bytes);
    setState(() {
      _imagenSeleccionada = bytes;
      _imagenBase64 = base64;
      _imagenMimeType = 'image/jpeg';
      _resultadoImagen = null;
    });
}

  Future<void> _analizarImagen() async {
    if (_imagenBase64 == null) return;

    setState(() {
      _analizandoImagen = true;
      _resultadoImagen = null;
    });

    final prompt = _modoImagen == 'suelo'
        ? '''Eres un agrónomo experto en análisis de suelos para cultivo de café.
Analiza esta imagen de suelo y proporciona:
1. **Tipo de suelo identificado** (con características visuales observadas)
2. **Aptitud para cultivo de café** (Alta / Media / Baja — con justificación)
3. **Mejores tipos de suelo y terrenos recomendados** para maximizar la producción
4. **Acciones de mejora** si el suelo necesita correcciones
5. **Recomendaciones de preparación** antes de sembrar
Responde en español, de forma estructurada y práctica.'''
        : '''Eres un agrónomo experto en cultivo de café.
Analiza esta imagen de una planta de café y proporciona:
1. **Estado general de la planta** (saludable / con problemas — descripción)
2. **Enfermedades o plagas detectadas** (si las hay, con nombre y descripción)
3. **Estimación de próxima cosecha** (basada en el estado visual de los frutos)
4. **Recomendaciones de mejora** (fertilización, riego, poda, tratamientos)
5. **Consejos de mantenimiento preventivo**
Responde en español, de forma estructurada, clara y práctica.''';

    try {

      final res = await http.post(
        Uri.parse('https://cafenova-app-production.up.railway.app/ia/imagen'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'imagen_base64': _imagenBase64,
          'mime_type': _imagenMimeType ?? 'image/jpeg',
          'prompt': prompt,
          'temperature': 0.3,
          'maxTokens': 4096,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {

        setState(() {
          _resultadoImagen =
              data['respuesta'] ??
              'Análisis completado';
        });

      } else {

        setState(() {
          _resultadoImagen =
              data['error'] ??
              'Error analizando imagen';
        });
      }

    } catch (e) {

      setState(() {
        _resultadoImagen =
            'Error conectando con el servidor';
      });
    }    
    setState(() => _analizandoImagen = false);
  }

  // ─── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B7F66),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 22),
            SizedBox(width: 8),
            Text('Asistente IA', style: TextStyle(fontSize: 17)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
            Tab(icon: Icon(Icons.image_search), text: 'Análisis Visual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _tabChat(),
          _tabImagenIA(),
        ],
      ),
    );
  }

  // ─── TAB CHAT ──────────────────────────────────────────────────────────────
  Widget _tabChat() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              if (mensajes.isEmpty) _chatEmpty(),
              ...mensajes.map(_burbuja),
              if (cargando) _typingIndicator(),
            ],
          ),
        ),
        _inputChat(),
      ],
    );
  }

  Widget _chatEmpty() {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      child: Column(
        children: const [
          Icon(Icons.smart_toy, size: 60, color: Color(0xFF6B7F66)),
          SizedBox(height: 12),
          Text('¿En qué puedo ayudarte hoy?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text('Pregúntame sobre cultivo de café,\ntratamiento de plagas, cosechas y más.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF6B7F66),
            radius: 16,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                  color: Color(0xFF6B7F66),
                  backgroundColor: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _burbuja(Map<String, dynamic> msg) {
    final esUsuario = msg['tipo'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esUsuario) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF6B7F66),
              radius: 16,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: esUsuario
                  ? const Color(0xFF6B7F66)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: esUsuario
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: esUsuario
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1))
              ],
            ),
            child: msg['esImagen'] == true
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(msg['imagen']),
          fit: BoxFit.cover,
        ),
      )
    : MarkdownBody(
        data: msg['texto'] ?? '',
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: 14,
            color: esUsuario
                ? Colors.white
                : Colors.black87,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.bold,
            color: esUsuario
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
          ),
          if (esUsuario) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputChat() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _preguntarIA(),
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _preguntarIA,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cargando ? Colors.grey : const Color(0xFF6B7F66),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB IMAGEN ────────────────────────────────────────────────────────────
  Widget _tabImagenIA() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector modo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _modoBtn('suelo', Icons.terrain, 'Análisis de Suelo'),
                _modoBtn(
                    'planta', Icons.local_florist, 'Planta de Café'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Descripción del modo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7F66).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6B7F66).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  _modoImagen == 'suelo'
                      ? Icons.terrain
                      : Icons.local_florist,
                  color: const Color(0xFF6B7F66),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _modoImagen == 'suelo'
                        ? 'Sube una foto del suelo para evaluar su tipo, aptitud para café y recomendaciones.'
                        : 'Sube una foto de una planta de café para detectar su estado, enfermedades y estimar cosecha.',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Zona de carga de imagen
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _imagenSeleccionada != null
                      ? const Color(0xFF6B7F66)
                      : Colors.grey.shade300,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _imagenSeleccionada != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _imagenSeleccionada!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('Toca para seleccionar imagen',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          _modoImagen == 'suelo'
                              ? 'Foto de suelo o terreno'
                              : 'Foto de planta de café',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),

          if (_imagenSeleccionada != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _analizandoImagen ? null : _analizarImagen,
                    icon: _analizandoImagen
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: Text(_analizandoImagen
                        ? 'Analizando...'
                        : 'Analizar con IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7F66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _imagenSeleccionada = null;
                      _imagenBase64 = null;
                      _resultadoImagen = null;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ],

          // Resultado
          if (_resultadoImagen != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7F66).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _modoImagen == 'suelo'
                              ? Icons.terrain
                              : Icons.eco,
                          color: const Color(0xFF6B7F66),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ✅ FIX overflow: Expanded evita que el Text desborde el Row
                      Expanded(
                        child: Text(
                          _modoImagen == 'suelo'
                              ? 'Análisis del Suelo'
                              : 'Análisis de la Planta',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  MarkdownBody(
                    data: _resultadoImagen!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.5),
                      h2: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7F66)),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _modoBtn(String modo, IconData icon, String label) {
    final activo = _modoImagen == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _modoImagen = modo;
          _resultadoImagen = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: activo
                ? [
                    const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: activo
                      ? const Color(0xFF6B7F66)
                      : Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: activo
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: activo
                        ? const Color(0xFF6B7F66)
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
