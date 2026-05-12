import 'package:flutter/material.dart';
import '../modulos/autenticacion/presentacion/paginas/pagina_login.dart';
import '../nucleo/constantes/app_constantes.dart';
import '../nucleo/tema/tema_app.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstantes.nombreApp,
      theme: TemaApp.obtenerTema(),
      home: const PaginaLogin(),
    );
  }
}