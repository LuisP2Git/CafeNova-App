import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // Dispositivo
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint &&
        width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Tamaños
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Padding general
  static EdgeInsets screenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 24,
      );
    }

    if (isTablet(context)) {
      return const EdgeInsets.all(24);
    }

    return const EdgeInsets.all(16);
  }

  // Ancho máximo del contenido
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1000;
    }

    if (isTablet(context)) {
      return 750;
    }

    return double.infinity;
  }

  // Formularios
  static double formWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 500;
    }

    if (isTablet(context)) {
      return 450;
    }

    return double.infinity;
  }

  // Grid
  static int columns(BuildContext context) {
    if (isDesktop(context)) return 4;

    if (isTablet(context)) return 3;

    return 2;
  }

  // Cards
  static double cardWidth(BuildContext context) {
    if (isDesktop(context)) return 300;

    if (isTablet(context)) return 260;

    return double.infinity;
  }

  // Texto
  static double titleSize(BuildContext context) {
    if (isDesktop(context)) return 30;

    if (isTablet(context)) return 26;

    return 22;
  }

  static double subtitleSize(BuildContext context) {
    if (isDesktop(context)) return 20;

    if (isTablet(context)) return 18;

    return 16;
  }

  static double bodySize(BuildContext context) {
    if (isDesktop(context)) return 16;

    if (isTablet(context)) return 15;

    return 14;
  }

  // Iconos
  static double iconSize(BuildContext context) {
    if (isDesktop(context)) return 30;

    if (isTablet(context)) return 28;

    return 24;
  }

  // Logo
  static double logoSize(BuildContext context) {
    if (isDesktop(context)) return 180;

    if (isTablet(context)) return 150;

    return 120;
  }

  // Texto pequeño
  static double captionSize(BuildContext context) {
    if (isDesktop(context)) return 13;

    if (isTablet(context)) return 12;

    return 11;
  }

  // Botones
  static double buttonHeight(BuildContext context) {
    if (isDesktop(context)) return 55;

    if (isTablet(context)) return 52;

    return 48;
  }

  // Diálogos
  static double dialogWidth(BuildContext context) {
    if (isDesktop(context)) return 500;

    if (isTablet(context)) return 450;

    return screenWidth(context) * .90;
  }
}