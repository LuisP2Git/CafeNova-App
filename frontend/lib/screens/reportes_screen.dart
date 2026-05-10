import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/utils/mensajes.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'lotes_screen.dart';
import 'profile_screen.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  // ─── helpers ───────────────────────────────────────────────────────────────
  static const _meses = {
    '01': 'Ene', '02': 'Feb', '03': 'Mar', '04': 'Abr',
    '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Ago',
    '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dic',
  };
  String _mes(String m) => _meses[m.substring(5)] ?? m.substring(5);
  String _fechaCorta(String f) {
    final d = DateTime.parse(f);
    return '${d.day}/${d.month}';
  }

  String _fechaLarga(String fecha) {
    try {
      final f = DateTime.parse(fecha);
      return '${f.day}/${f.month}/${f.year}';
    } catch (_) {
      return fecha;
    }
  }

  // ─── datos ─────────────────────────────────────────────────────────────────
  List mensual = [];
  List calidad = [];
  List porFecha = [];
  List fincasReporte = [];

  double total = 0;
  String? mejorCultivo;

  // Filtros Tendencia
  DateTime? desde;
  DateTime? hasta;
  final _palabraClaveCtrl = TextEditingController();
  String? _cosechaFiltro; // nombre de cultivo/cosecha para filtrar

  // ✅ NUEVO: estado del selector "Por Finca"
  _ModoFinca _modoFinca = _ModoFinca.todas;
  final Set<int> _fincasSeleccionadas = {};
  String? _tipoReporteFinca; // 'resumen' | 'comparativa' | 'detalle'

  String? token;
  String nombre = '';
  String correo = '';
  String rol = '';
  bool cargando = true;

  late TabController _tabController;
  final int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    initApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _palabraClaveCtrl.dispose();
    super.dispose();
  }

  Future<void> initApp() async {
    token = await SessionService.getToken();
    final datos = await SessionService.getDatosSesion();
    nombre = datos['nombre'] ?? '';
    correo = datos['correo'] ?? '';
    rol = datos['rol'] ?? '';
    if (token == null) return;
    await cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final m = await ApiService.getMensual(token!);
      final c = await ApiService.getCalidad(token!);
      final t = await ApiService.getTotal(token!);
      final mejor = await ApiService.getMejor(token!);
      final fincas = await ApiService.getCosechasPorFinca(token!);

      setState(() {
        mensual = m;
        calidad = c;
        total = double.tryParse(t['total_kg']?.toString() ?? '0') ?? 0;
        mejorCultivo =
            '${mejor['tipo_cultivo'] ?? ''} — ${mejor['variedad'] ?? ''}';
        fincasReporte = fincas;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> cargarPorFecha() async {
    if (desde == null || hasta == null) return;
    setState(() => cargando = true);
    try {
      final data = await ApiService.getPorFecha(
        token!,
        desde.toString().split(' ')[0],
        hasta.toString().split(' ')[0],
      );
      setState(() {
        porFecha = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6B7F66)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (esDesde) desde = picked;
        else hasta = picked;
      });
    }
  }

  // ─── Filtrado de tendencia ──────────────────────────────────────────────────
  List get _porFechaFiltrado {
    var data = porFecha;
    final kw = _palabraClaveCtrl.text.trim().toLowerCase();
    if (kw.isNotEmpty) {
      data = data.where((r) {
        final desc = '${r['tipo_cultivo'] ?? ''} ${r['variedad'] ?? ''} ${r['lote'] ?? ''}'
            .toLowerCase();
        return desc.contains(kw);
      }).toList();
    }
    if (_cosechaFiltro != null && _cosechaFiltro!.isNotEmpty) {
      data = data
          .where((r) =>
              '${r['tipo_cultivo'] ?? ''}'.toLowerCase() ==
              _cosechaFiltro!.toLowerCase())
          .toList();
    }
    return data;
  }

  List<String> get _tiposCosecha {
    final set = <String>{};
    for (final r in porFecha) {
      if (r['tipo_cultivo'] != null) set.add(r['tipo_cultivo'].toString());
    }
    return set.toList();
  }

  // ─── Fincas disponibles (para selector) ────────────────────────────────────
  List get _fincasVisibles {
    if (_modoFinca == _ModoFinca.todas) return fincasReporte;
    if (_modoFinca == _ModoFinca.unica || _modoFinca == _ModoFinca.multiple) {
      if (_fincasSeleccionadas.isEmpty) return fincasReporte;
      return fincasReporte
          .where((f) => _fincasSeleccionadas
              .contains(f['id_finca'] as int? ?? 0))
          .toList();
    }
    return fincasReporte;
  }

  void _onItemTapped(int index) async {
    if (index == 2) return;
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('nombre') ?? nombre;
    final c = prefs.getString('correo') ?? correo;
    final r = prefs.getString('rol') ?? rol;
    if (!mounted) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => HomeScreen(nombre: n, correo: c, rol: r)),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => LotesScreen(nombreUsuario: n)));
    } else if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => ProfileScreen(nombre: n, correo: c)));
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      body: Column(
        children: [
          _header(),
          Container(
            color: const Color(0xFF6B7F66),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Resumen'),
                Tab(text: 'Por Finca'),
                Tab(text: 'Tendencia'),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _tabResumen(),
                      _tabPorFinca(),
                      _tabTendencia(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTabSelected: _onItemTapped,
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(color: Color(0xFF6B7F66)),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        nombre: prefs.getString('nombre') ?? nombre,
                        correo: prefs.getString('correo') ?? correo,
                        rol: prefs.getString('rol') ?? rol,
                      ),
                    ),
                    (route) => false,
                  );
                },
              ),
              const Icon(Icons.bar_chart, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Reportes',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                if (correo.isNotEmpty)
                  Text(correo,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: RESUMEN ────────────────────────────────────────────────────────
  Widget _tabResumen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📊 Indicadores'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _kpiCard('Producción Total',
                    '${total.toStringAsFixed(1)} kg', Icons.scale,
                    Colors.green.shade700)),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard('Mejor Cultivo', mejorCultivo ?? 'N/A',
                    Icons.emoji_events, Colors.amber.shade700)),
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('📅 Producción Mensual'),
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await ApiService.descargarPDF(token!);
                  if (mounted) {
                    Mensajes.mostrar(
                        context,
                        ok ? 'PDF descargado' : 'Error al descargar PDF',
                        esError: !ok);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7F66),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (mensual.isEmpty)
            _emptyState('Sin datos de producción mensual')
          else
            _chartCard(SizedBox(
              height: 220,
              child: BarChart(BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < mensual.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_mes(mensual[i]['mes']),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54)),
                    ),
                  ),
                ),
                barGroups: mensual.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['total_kg'] ?? 0).toDouble(),
                        color: const Color(0xFF6B7F66),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              )),
            )),
          const SizedBox(height: 24),
          _sectionTitle('☕ Calidad del Café'),
          const SizedBox(height: 10),
          if (calidad.isEmpty)
            _emptyState('Sin datos de calidad')
          else
            _chartCard(Row(children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: calidad.map((e) {
                      final color = e['calidad'] == 'Alta'
                          ? const Color(0xFF4CAF50)
                          : e['calidad'] == 'Media'
                              ? const Color(0xFFFFA726)
                              : const Color(0xFFEF5350);
                      return PieChartSectionData(
                        color: color,
                        value: (e['total_kg'] ?? 0).toDouble(),
                        title:
                            '${(e['total_kg'] ?? 0).toStringAsFixed(0)}kg',
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                        radius: 55,
                      );
                    }).toList(),
                  )),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: calidad.map((e) {
                  final color = e['calidad'] == 'Alta'
                      ? const Color(0xFF4CAF50)
                      : e['calidad'] == 'Media'
                          ? const Color(0xFFFFA726)
                          : const Color(0xFFEF5350);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text('${e['calidad']}: ${e['total_kg']}kg',
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  );
                }).toList(),
              ),
            ])),
        ],
      ),
    );
  }

  // ─── TAB 2: POR FINCA ──────────────────────────────────────────────────────
  Widget _tabPorFinca() {
    return Column(
      children: [
        // ✅ NUEVO: panel de selección de modo
        _panelSelectorFinca(),
        if (_tipoReporteFinca != null) _panelTipoReporte(),
        Expanded(
          child: fincasReporte.isEmpty
              ? Center(child: _emptyState('No hay datos por finca'))
              : _listaFincas(),
        ),
      ],
    );
  }

  Widget _panelSelectorFinca() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modo de visualización',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          // Chips de selección de modo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _modoChip('Todas', Icons.select_all, _ModoFinca.todas),
              const SizedBox(width: 8),
              _modoChip(
                  'Múltiples', Icons.checklist, _ModoFinca.multiple),
              const SizedBox(width: 8),
              _modoChip('Una Finca', Icons.filter_1, _ModoFinca.unica),
            ]),
          ),
          // Si es modo múltiple o único → mostrar checkboxes de fincas
          if (_modoFinca != _ModoFinca.todas &&
              fincasReporte.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            const Text('Selecciona finca(s):',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: fincasReporte.map((f) {
                final id = f['id_finca'] as int? ?? 0;
                final nombre = f['nombre_finca'] ?? 'Finca';
                final sel = _fincasSeleccionadas.contains(id);
                return FilterChip(
                  label: Text(nombre,
                      style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (_modoFinca == _ModoFinca.unica) {
                        _fincasSeleccionadas.clear();
                      }
                      if (v) {
                        _fincasSeleccionadas.add(id);
                      } else {
                        _fincasSeleccionadas.remove(id);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF6B7F66).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6B7F66),
                  labelStyle: TextStyle(
                      color: sel
                          ? const Color(0xFF6B7F66)
                          : Colors.black87),
                );
              }).toList(),
            ),
          ],
          // Botón para seleccionar tipo de reporte
          if (_modoFinca == _ModoFinca.todas ||
              _fincasSeleccionadas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            const Text('Tipo de reporte:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _tipoReporteChip('Resumen', Icons.summarize, 'resumen'),
                const SizedBox(width: 8),
                _tipoReporteChip(
                    'Comparativa', Icons.compare, 'comparativa'),
                const SizedBox(width: 8),
                _tipoReporteChip('Detalle', Icons.list_alt, 'detalle'),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modoChip(String label, IconData icon, _ModoFinca modo) {
    final activo = _modoFinca == modo;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16,
          color: activo ? Colors.white : const Color(0xFF6B7F66)),
      label: Text(label),
      selected: activo,
      onSelected: (_) => setState(() {
        _modoFinca = modo;
        _fincasSeleccionadas.clear();
        _tipoReporteFinca = null;
      }),
      selectedColor: const Color(0xFF6B7F66),
      backgroundColor: Colors.grey.shade100,
      labelStyle:
          TextStyle(color: activo ? Colors.white : Colors.black87,
          fontSize: 12),
    );
  }

  Widget _tipoReporteChip(String label, IconData icon, String tipo) {
    final activo = _tipoReporteFinca == tipo;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16,
          color: activo ? Colors.white : const Color(0xFF6B7F66)),
      label: Text(label),
      selected: activo,
      onSelected: (_) => setState(() => _tipoReporteFinca = tipo),
      selectedColor: const Color(0xFF6B7F66),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
          color: activo ? Colors.white : Colors.black87, fontSize: 12),
    );
  }

  Widget _panelTipoReporte() {
    // Muestra una pequeña nota del tipo seleccionado
    final desc = {
      'resumen': 'Vista consolidada de totales por finca',
      'comparativa': 'Gráfica comparativa entre fincas seleccionadas',
      'detalle': 'Listado completo de cosechas por finca',
    }[_tipoReporteFinca] ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7F66).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF6B7F66).withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline,
            size: 16, color: Color(0xFF6B7F66)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7F66))),
        ),
      ]),
    );
  }

  Widget _listaFincas() {
    final data = _fincasVisibles;
    final tipo = _tipoReporteFinca ?? 'detalle';

    if (tipo == 'comparativa' && data.length > 1) {
      return _vistaComparativa(data);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final finca = data[i];
        final cosechas = (finca['cosechas'] as List?) ?? [];
        final totalFinca = cosechas.fold<double>(0,
            (s, c) =>
                s +
                (double.tryParse(c['cantidad_kg']?.toString() ?? '0') ?? 0));

        if (tipo == 'resumen') return _fincaResumenCard(finca, cosechas, totalFinca);
        return _fincaDetalleCard(finca, cosechas, totalFinca);
      },
    );
  }

  Widget _fincaResumenCard(Map finca, List cosechas, double totalFinca) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6B7F66).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.park, color: Color(0xFF6B7F66), size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(finca['nombre_finca'] ?? 'Finca',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${cosechas.length} cosecha(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B7F66),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${totalFinca.toStringAsFixed(1)} kg',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _fincaDetalleCard(Map finca, List cosechas, double totalFinca) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7F66).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.park, color: Color(0xFF6B7F66), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(finca['nombre_finca'] ?? 'Finca',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                      '${cosechas.length} cosecha(s) · ${totalFinca.toStringAsFixed(1)} kg',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ]),
          children: [
            const Divider(height: 1),
            if (cosechas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin cosechas registradas',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...cosechas.map(_cosechaRow),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _vistaComparativa(List data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📊 Comparativa entre Fincas'),
          const SizedBox(height: 12),
          _chartCard(SizedBox(
            height: 250,
            child: BarChart(BarChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < data.length) {
                        final nm = (data[i]['nombre_finca'] ?? 'F${i + 1}')
                            .toString();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            nm.length > 8
                                ? '${nm.substring(0, 8)}…'
                                : nm,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, m) => Text('${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54)),
                  ),
                ),
              ),
              barGroups: data.asMap().entries.map((e) {
                final cosechas = (e.value['cosechas'] as List?) ?? [];
                final tot = cosechas.fold<double>(
                    0,
                    (s, c) =>
                        s +
                        (double.tryParse(
                                c['cantidad_kg']?.toString() ?? '0') ??
                            0));
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: tot,
                      color: const Color(0xFF6B7F66),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            )),
          )),
          const SizedBox(height: 16),
          // Tabla comparativa
          ...data.map((f) {
            final cosechas = (f['cosechas'] as List?) ?? [];
            final tot = cosechas.fold<double>(0,
                (s, c) =>
                    s +
                    (double.tryParse(c['cantidad_kg']?.toString() ?? '0') ?? 0));
            return _fincaResumenCard(f, cosechas, tot);
          }),
        ],
      ),
    );
  }

  Widget _cosechaRow(dynamic cosecha) {
    final c = cosecha as Map;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.agriculture, size: 18, color: Color(0xFF6B7F66)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c['tipo_cultivo'] != null
                    ? '${c['tipo_cultivo']} — ${c['variedad'] ?? ''}'
                    : 'Cosecha',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (c['fecha_cosecha'] != null)
                Text(_fechaLarga(c['fecha_cosecha']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6B7F66).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${c['cantidad_kg'] ?? 0} kg',
              style: const TextStyle(
                  color: Color(0xFF6B7F66),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 8),
        _calidadBadge(c['calidad']),
      ]),
    );
  }

  Widget _calidadBadge(dynamic calidad) {
    final color = calidad == 'Alta'
        ? Colors.green
        : calidad == 'Media'
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(calidad?.toString() ?? '-',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ─── TAB 3: TENDENCIA ──────────────────────────────────────────────────────
  Widget _tabTendencia() {
    final filtered = _porFechaFiltrado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📈 Filtrar Tendencia de Producción'),
          const SizedBox(height: 12),

          // ── Rango de fechas ─────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: _dateButton(
                'Desde',
                desde != null
                    ? '${desde!.day}/${desde!.month}/${desde!.year}'
                    : null,
                () => seleccionarFecha(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateButton(
                'Hasta',
                hasta != null
                    ? '${hasta!.day}/${hasta!.month}/${hasta!.year}'
                    : null,
                () => seleccionarFecha(false),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: cargarPorFecha,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7F66),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              child: const Text('Filtrar',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),

          const SizedBox(height: 14),

          // ✅ NUEVO: Filtros adicionales — Palabra clave y Cosecha
          if (porFecha.isNotEmpty) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _palabraClaveCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Palabra clave (lote, cultivo…)',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              if (_tiposCosecha.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _cosechaFiltro,
                      hint: const Text('Cosecha',
                          style: TextStyle(fontSize: 13)),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas')),
                        ..._tiposCosecha.map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (v) =>
                          setState(() => _cosechaFiltro = v),
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 6),
            if (_palabraClaveCtrl.text.isNotEmpty ||
                _cosechaFiltro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${filtered.length} resultado(s)',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              ),
          ],

          const SizedBox(height: 8),

          if (porFecha.isEmpty)
            _emptyState(
                'Selecciona un rango de fechas y presiona Filtrar')
          else if (filtered.isEmpty)
            _emptyState('Sin resultados para los filtros aplicados')
          else ...[
            _sectionTitle(
                'Producción: ${desde!.day}/${desde!.month} — ${hasta!.day}/${hasta!.month}'),
            const SizedBox(height: 10),
            _chartCard(SizedBox(
              height: 220,
              child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _fechaCorta(filtered[i]['fecha']),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF6B7F66),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, x, bar, i) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF6B7F66),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6B7F66).withOpacity(0.1),
                    ),
                    spots: filtered.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        (e.value['total_kg'] ?? 0).toDouble(),
                      );
                    }).toList(),
                  ),
                ],
              )),
            )),
            const SizedBox(height: 16),
            // Tabla de resultados
            ...filtered.map(_filaTabla),
          ],
        ],
      ),
    );
  }

  Widget _filaTabla(dynamic row) {
    final r = row as Map;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF6B7F66)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fechaLarga(r['fecha'] ?? ''),
                  style: const TextStyle(fontSize: 13)),
              if (r['tipo_cultivo'] != null)
                Text(
                  '${r['tipo_cultivo']} ${r['variedad'] ?? ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ),
        Text('${r['total_kg'] ?? 0} kg',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7F66),
                fontSize: 13)),
      ]),
    );
  }

  // ─── helpers UI ────────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }

  Widget _chartCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(children: [
        const Icon(Icons.bar_chart, size: 40, color: Colors.black26),
        const SizedBox(height: 8),
        Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45)),
      ]),
    );
  }

  Widget _dateButton(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_month, size: 16, color: Color(0xFF6B7F66)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? label,
              style: TextStyle(
                  fontSize: 13,
                  color: value != null ? Colors.black87 : Colors.grey),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Enum modo finca ──────────────────────────────────────────────────────────
enum _ModoFinca { todas, multiple, unica }
