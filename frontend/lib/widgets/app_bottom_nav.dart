import 'package:flutter/material.dart';

/// Barra de navegación inferior reutilizable de CafeNova.
///
/// Cada pantalla define su propio [onTabSelected] para manejar la navegación,
/// porque Flutter no tiene un router global configurado y cada pantalla
/// ya importa las demás directamente.
///
/// Ejemplo de uso:
/// ```dart
/// bottomNavigationBar: AppBottomNav(
///   currentIndex: 1,            // índice de la pestaña activa
///   onTabSelected: _onItemTapped, // función de la pantalla
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
