import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTabSelected;
  final bool puedeVerReportes;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.puedeVerReportes,
  });

@override
Widget build(BuildContext context) {

  final items = <BottomNavigationBarItem>[
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.eco_outlined),
      activeIcon: Icon(Icons.eco),
      label: 'Lotes',
    ),

    if (puedeVerReportes)
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Reportes',
      ),

    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: onTabSelected,
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFF6B7F66),
    unselectedItemColor: Colors.black54,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    items: items,
  );
}
}
