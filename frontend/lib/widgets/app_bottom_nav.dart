import 'package:flutter/material.dart';

/// Barra de navegación inferior reutilizable de CafeNova.
///
/// FIX #5 — La navegación desde cada pantalla debe usar
/// [Navigator.pushAndRemoveUntil] al ir a Inicio (índice 0)
/// para limpiar la pila y evitar que al presionar Atrás se
/// regrese a Reportes en lugar del panel de Inicio.
///
/// Ejemplo de uso (implementar en cada pantalla):
/// ```dart
/// void _onItemTapped(int index) async {
///   if (index == _miIndice) return;          // ya estoy aquí
///   final prefs = await SharedPreferences.getInstance();
///   final n = prefs.getString('nombre') ?? '';
///   final c = prefs.getString('correo') ?? '';
///   final r = prefs.getString('rol')    ?? '';
///   if (!mounted) return;
///
///   switch (index) {
///     case 0:
///       // SIEMPRE limpiar la pila al volver a Inicio
///       Navigator.pushAndRemoveUntil(
///         context,
///         MaterialPageRoute(builder: (_) => HomeScreen(nombre: n, correo: c, rol: r)),
///         (route) => false,
///       );
///       break;
///     case 1:
///       Navigator.push(context,
///           MaterialPageRoute(builder: (_) => LotesScreen(nombreUsuario: n)));
///       break;
///     case 2:
///       Navigator.push(context,
///           MaterialPageRoute(builder: (_) => ReportesScreen()));
///       break;
///     case 3:
///       Navigator.push(context,
///           MaterialPageRoute(builder: (_) => ProfileScreen(nombre: n, correo: c)));
///       break;
///   }
/// }
///
/// bottomNavigationBar: AppBottomNav(
///   currentIndex: 0,               // índice de la pestaña activa
///   onTabSelected: _onItemTapped,
/// ),
/// ```
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF6B7F66),
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.eco_outlined),
          activeIcon: Icon(Icons.eco),
          label: 'Lotes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Reportes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
