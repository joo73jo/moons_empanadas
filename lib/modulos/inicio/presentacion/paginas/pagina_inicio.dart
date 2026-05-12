import 'package:flutter/material.dart';
import '../../../../nucleo/constantes/app_constantes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../../../autenticacion/presentacion/paginas/pagina_login.dart';
import '../../../caja/presentacion/paginas/pagina_caja.dart';
import '../../../inventario/presentacion/paginas/pagina_inventario.dart';
import '../../../produccion/presentacion/paginas/pagina_produccion.dart';
import '../../../recetas/presentacion/paginas/pagina_recetas.dart';
import '../../../reportes/presentacion/paginas/pagina_historial_ventas.dart';
import '../../../ventas/presentacion/paginas/pagina_ventas.dart';

class PaginaInicio extends StatelessWidget {
  final Usuario usuario;

  const PaginaInicio({
    super.key,
    required this.usuario,
  });

  String _obtenerNombreRol(String rol) {
    switch (rol) {
      case 'dueno':
        return 'Dueño';
      case 'empleado':
        return 'Empleado';
      case 'invitado':
        return 'Invitado';
      default:
        return rol;
    }
  }

  List<_ModuloInicio> _obtenerModulosPorRol() {
    switch (usuario.rol) {
      case 'dueno':
        return const [
          _ModuloInicio(
            titulo: 'Ventas',
            subtitulo: 'Registrar y consultar ventas',
            icono: Icons.point_of_sale_rounded,
          ),
          _ModuloInicio(
            titulo: 'Caja',
            subtitulo: 'Apertura, cierre y cuadre',
            icono: Icons.account_balance_wallet_rounded,
          ),
          _ModuloInicio(
            titulo: 'Historial ventas',
            subtitulo: 'Consultar ventas recientes',
            icono: Icons.receipt_long_rounded,
          ),
          _ModuloInicio(
            titulo: 'Inventario',
            subtitulo: 'Ingredientes y stock real',
            icono: Icons.inventory_2_rounded,
          ),
          _ModuloInicio(
            titulo: 'Recetas',
            subtitulo: 'Ingredientes por producto',
            icono: Icons.menu_book_rounded,
          ),
          _ModuloInicio(
            titulo: 'Producción',
            subtitulo: 'Consumir ingredientes y sumar stock',
            icono: Icons.bakery_dining_rounded,
          ),
          _ModuloInicio(
            titulo: 'Reportes',
            subtitulo: 'Resumen y métricas',
            icono: Icons.bar_chart_rounded,
          ),
          _ModuloInicio(
            titulo: 'Usuarios',
            subtitulo: 'Control de accesos',
            icono: Icons.group_rounded,
          ),
        ];
      case 'empleado':
        return const [
          _ModuloInicio(
            titulo: 'Ventas',
            subtitulo: 'Registrar ventas',
            icono: Icons.point_of_sale_rounded,
          ),
          _ModuloInicio(
            titulo: 'Caja',
            subtitulo: 'Consulta de caja',
            icono: Icons.account_balance_wallet_rounded,
          ),
          _ModuloInicio(
            titulo: 'Historial ventas',
            subtitulo: 'Consultar ventas recientes',
            icono: Icons.receipt_long_rounded,
          ),
          _ModuloInicio(
            titulo: 'Inventario',
            subtitulo: 'Consulta y movimientos',
            icono: Icons.inventory_2_rounded,
          ),
          _ModuloInicio(
            titulo: 'Recetas',
            subtitulo: 'Consulta de recetas',
            icono: Icons.menu_book_rounded,
          ),
          _ModuloInicio(
            titulo: 'Producción',
            subtitulo: 'Registrar producción',
            icono: Icons.bakery_dining_rounded,
          ),
        ];
      case 'invitado':
        return const [
          _ModuloInicio(
            titulo: 'Ventas',
            subtitulo: 'Acceso rápido de apoyo',
            icono: Icons.point_of_sale_rounded,
          ),
          _ModuloInicio(
            titulo: 'Historial ventas',
            subtitulo: 'Consultar ventas recientes',
            icono: Icons.receipt_long_rounded,
          ),
          _ModuloInicio(
            titulo: 'Inventario',
            subtitulo: 'Consulta y movimientos',
            icono: Icons.inventory_2_rounded,
          ),
          _ModuloInicio(
            titulo: 'Recetas',
            subtitulo: 'Consulta de recetas',
            icono: Icons.menu_book_rounded,
          ),
          _ModuloInicio(
            titulo: 'Producción',
            subtitulo: 'Registrar producción',
            icono: Icons.bakery_dining_rounded,
          ),
        ];
      default:
        return const [];
    }
  }

  void _abrirModulo(BuildContext context, _ModuloInicio modulo) {
    if (modulo.titulo == 'Ventas') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaginaVentas(usuario: usuario),
        ),
      );
      return;
    }

    if (modulo.titulo == 'Caja') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaginaCaja(usuario: usuario),
        ),
      );
      return;
    }

    if (modulo.titulo == 'Historial ventas') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaginaHistorialVentas(),
        ),
      );
      return;
    }

    if (modulo.titulo == 'Inventario') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaginaInventario(usuario: usuario),
        ),
      );
      return;
    }

    if (modulo.titulo == 'Recetas') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaginaRecetas(usuario: usuario),
        ),
      );
      return;
    }

    if (modulo.titulo == 'Producción') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaginaProduccion(usuario: usuario),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Módulo "${modulo.titulo}" en construcción.',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColoresApp.principal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreRol = _obtenerNombreRol(usuario.rol);
    final modulos = _obtenerModulosPorRol();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstantes.nombreApp),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const PaginaLogin(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: ColoresApp.principal,
                ),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: ColoresApp.fondoPrincipal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ColoresApp.superficie,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: ColoresApp.principal.withOpacity(0.15),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: ColoresApp.principal,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido, ${usuario.nombre}',
                                style: const TextStyle(
                                  color: ColoresApp.textoPrincipal,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rol: $nombreRol',
                                style: const TextStyle(
                                  color: ColoresApp.textoSecundario,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ColoresApp.fondoSecundario,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Usuario: ${usuario.usuario}',
                                  style: const TextStyle(
                                    color: ColoresApp.textoPrincipal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Módulos disponibles',
                    style: TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Accesos visibles según el rol del usuario',
                    style: TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modulos.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 170,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final modulo = modulos[index];
                      return _TarjetaModulo(
                        modulo: modulo,
                        onTap: () => _abrirModulo(context, modulo),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaModulo extends StatelessWidget {
  final _ModuloInicio modulo;
  final VoidCallback onTap;

  const _TarjetaModulo({
    required this.modulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: ColoresApp.superficie,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      ColoresApp.principalClaro,
                      ColoresApp.principal,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  modulo.icono,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                modulo.titulo,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                modulo.subtitulo,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuloInicio {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  const _ModuloInicio({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });
}