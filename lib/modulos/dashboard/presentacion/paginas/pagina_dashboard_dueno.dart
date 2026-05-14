import 'package:flutter/material.dart';
import '../../../../nucleo/constantes/app_constantes.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../../../autenticacion/presentacion/paginas/pagina_login.dart';
import '../../../caja/presentacion/paginas/pagina_caja.dart';
import '../../../dashboard/presentacion/widgets/dashboard_supabase.dart';
import '../../../inventario/presentacion/paginas/pagina_inventario.dart';
import '../../../produccion/presentacion/paginas/pagina_produccion.dart';
import '../../../recetas/presentacion/paginas/pagina_recetas.dart';
import '../../../reportes/presentacion/paginas/pagina_historial_ventas.dart';
import '../../../reportes/presentacion/paginas/pagina_reportes.dart';
import '../../../ventas/presentacion/paginas/pagina_ventas.dart';

class PaginaDashboardDueno extends StatefulWidget {
  final Usuario usuario;

  const PaginaDashboardDueno({
    super.key,
    required this.usuario,
  });

  @override
  State<PaginaDashboardDueno> createState() => _PaginaDashboardDuenoState();
}

class _PaginaDashboardDuenoState extends State<PaginaDashboardDueno> {
  DashboardResumen? _resumen;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
    });

    try {
      final resumen = await DashboardSupabase.obtenerResumen();

      if (!mounted) return;

      setState(() {
        _resumen = resumen;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error cargando dashboard: $e',
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
  }

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => pagina),
    );
  }

  void _cerrarSesion() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PaginaLogin(),
      ),
    );
  }

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 650;
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstantes.nombreApp),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (esCelular)
            IconButton(
              onPressed: _cerrarSesion,
              icon: const Icon(
                Icons.logout_rounded,
                color: ColoresApp.principal,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: TextButton.icon(
                  onPressed: _cerrarSesion,
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
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(
                  color: ColoresApp.principal,
                ),
              )
            : resumen == null
                ? const Center(
                    child: Text(
                      'No se pudo cargar el dashboard.',
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: ColoresApp.principal,
                    backgroundColor: ColoresApp.superficie,
                    onRefresh: _cargar,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(esCelular ? 14 : 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cabecera(resumen, esCelular),
                              SizedBox(height: esCelular ? 14 : 22),
                              _metricas(resumen),
                              SizedBox(height: esCelular ? 14 : 22),
                              _contenidoPrincipal(resumen),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _cabecera(DashboardResumen resumen, bool esCelular) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 24),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(esCelular ? 22 : 24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: esCelular
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconoCabecera(esCelular),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Dashboard de ${widget.usuario.nombre}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Resumen operativo del negocio',
                  style: TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _estadoCaja(resumen),
              ],
            )
          : Row(
              children: [
                _iconoCabecera(esCelular),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard de ${widget.usuario.nombre}',
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Resumen operativo del negocio',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _estadoCaja(resumen),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _iconoCabecera(bool esCelular) {
    return Container(
      width: esCelular ? 64 : 84,
      height: esCelular ? 64 : 84,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(esCelular ? 18 : 22),
      ),
      child: Icon(
        Icons.dashboard_rounded,
        size: esCelular ? 34 : 42,
        color: ColoresApp.principal,
      ),
    );
  }

  Widget _estadoCaja(DashboardResumen resumen) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        resumen.hayCajaAbierta
            ? 'Caja abierta #${resumen.cajaId}'
            : 'No hay caja abierta',
        style: TextStyle(
          color: resumen.hayCajaAbierta
              ? const Color(0xFF00A896)
              : Colors.redAccent,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _metricas(DashboardResumen resumen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        int columnas;
        double alto;

        if (ancho < 430) {
          columnas = 2;
          alto = 156;
        } else if (ancho < 850) {
          columnas = 2;
          alto = 145;
        } else {
          columnas = 4;
          alto = 145;
        }

        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: (ancho / columnas) / alto,
          children: [
            _tarjetaMetrica(
              'Ventas hoy',
              '${resumen.cantidadVentasHoy}',
              ColoresApp.principal,
              Icons.receipt_long_rounded,
            ),
            _tarjetaMetrica(
              'Total vendido hoy',
              '\$${resumen.totalVentasHoy.toStringAsFixed(2)}',
              const Color(0xFF00A896),
              Icons.attach_money_rounded,
            ),
            _tarjetaMetrica(
              'Ingredientes críticos',
              '${resumen.ingredientesCriticos}',
              Colors.redAccent,
              Icons.warning_amber_rounded,
            ),
            _tarjetaMetrica(
              'Productos bajos',
              '${resumen.productosBajos}',
              const Color(0xFFFFA726),
              Icons.inventory_2_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _contenidoPrincipal(DashboardResumen resumen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final esCelular = ancho < 800;

        if (esCelular) {
          return Column(
            children: [
              _bloqueAccesos(esCelular: true),
              const SizedBox(height: 14),
              _bloqueAlertas(resumen, esCelular: true),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _bloqueAccesos(esCelular: false),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 2,
              child: _bloqueAlertas(resumen, esCelular: false),
            ),
          ],
        );
      },
    );
  }

  Widget _bloqueAccesos({required bool esCelular}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 20),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accesos rápidos',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Módulos principales del sistema',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;

              int columnas;
              double alto;

              if (ancho < 430) {
                columnas = 2;
                alto = 138;
              } else if (ancho < 760) {
                columnas = 2;
                alto = 145;
              } else {
                columnas = 3;
                alto = 150;
              }

              return GridView.count(
                crossAxisCount: columnas,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: (ancho / columnas) / alto,
                children: [
                  _tarjetaAcceso(
                    titulo: 'Reportes',
                    subtitulo: 'Centro analítico',
                    icono: Icons.bar_chart_rounded,
                    onTap: () => _abrir(
                      context,
                      const PaginaReportes(),
                    ),
                  ),
                  _tarjetaAcceso(
                    titulo: 'Ventas',
                    subtitulo: 'Cobrar y registrar',
                    icono: Icons.point_of_sale_rounded,
                    onTap: () => _abrir(
                      context,
                      PaginaVentas(
                        usuario: widget.usuario,
                      ),
                    ),
                  ),
                  _tarjetaAcceso(
                    titulo: 'Caja',
                    subtitulo: 'Apertura y cierre',
                    icono: Icons.account_balance_wallet_rounded,
                    onTap: () => _abrir(
                      context,
                      PaginaCaja(
                        usuario: widget.usuario,
                      ),
                    ),
                  ),
                  _tarjetaAcceso(
                    titulo: 'Inventario',
                    subtitulo: 'Ingredientes',
                    icono: Icons.inventory_2_rounded,
                    onTap: () => _abrir(
                      context,
                      PaginaInventario(
                        usuario: widget.usuario,
                      ),
                    ),
                  ),
                  _tarjetaAcceso(
                    titulo: 'Recetas',
                    subtitulo: 'Fórmulas',
                    icono: Icons.menu_book_rounded,
                    onTap: () => _abrir(
                      context,
                      PaginaRecetas(
                        usuario: widget.usuario,
                      ),
                    ),
                  ),
                  _tarjetaAcceso(
                    titulo: 'Producción',
                    subtitulo: 'Fabricar stock',
                    icono: Icons.bakery_dining_rounded,
                    onTap: () => _abrir(
                      context,
                      PaginaProduccion(
                        usuario: widget.usuario,
                      ),
                    ),
                  ),
                  _tarjetaAcceso(
                    titulo: 'Historial',
                    subtitulo: 'Ventas recientes',
                    icono: Icons.receipt_long_rounded,
                    onTap: () => _abrir(
                      context,
                      const PaginaHistorialVentas(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bloqueAlertas(
    DashboardResumen resumen, {
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 20),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${resumen.alertas.length} avisos importantes',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          if (resumen.alertas.isEmpty)
            const Text(
              'No hay alertas por ahora.',
              style: TextStyle(
                color: ColoresApp.textoSecundario,
              ),
            )
          else
            ...resumen.alertas.map(
              (alerta) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColoresApp.fondoSecundario,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: ColoresApp.principal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alerta,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          _filaMiniResumen(
            'Ingredientes en mínimo',
            '${resumen.ingredientesMinimos}',
          ),
          _filaMiniResumen(
            'Ingredientes en crítico',
            '${resumen.ingredientesCriticos}',
          ),
          _filaMiniResumen(
            'Productos bajos',
            '${resumen.productosBajos}',
          ),
        ],
      ),
    );
  }

  Widget _tarjetaMetrica(
    String titulo,
    String valor,
    Color color,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 27),
          const Spacer(),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAcceso({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: ColoresApp.principal, size: 29),
            const Spacer(),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaMiniResumen(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}