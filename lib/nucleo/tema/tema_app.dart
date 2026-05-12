import 'package:flutter/material.dart';
import 'colores_app.dart';

class TemaApp {
  static ThemeData obtenerTema() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ColoresApp.fondoPrincipal,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ColoresApp.principal,
        onPrimary: Colors.black,
        secondary: ColoresApp.principalClaro,
        onSecondary: Colors.black,
        error: ColoresApp.error,
        onError: Colors.white,
        surface: ColoresApp.superficie,
        onSurface: ColoresApp.textoPrincipal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColoresApp.fondoSecundario,
        foregroundColor: ColoresApp.textoPrincipal,
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: ColoresApp.superficie,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: ColoresApp.textoPrincipal),
        bodyMedium: TextStyle(color: ColoresApp.textoPrincipal),
        bodySmall: TextStyle(color: ColoresApp.textoSecundario),
        titleLarge: TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}