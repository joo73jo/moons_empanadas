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
import '../../../ventas/presentacion/paginas/pagina_ventas.dart';
import '../../../reportes/presentacion/paginas/pagina_reportes.dart';

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

  @override
  Widget build(BuildContext context) {
    final resumen = _resumen;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstantes.nombreApp),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
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
        color: ColoresApp.fondoPrincipal,
        padding: const EdgeInsets.all(24),
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
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1300),
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
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Icon(
                                      Icons.dashboard_rounded,
                                      size: 42,
                                      color: ColoresApp.principal,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ColoresApp.fondoSecundario,
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: _tarjetaMetrica(
                                    'Ventas hoy',
                                    '${resumen.cantidadVentasHoy}',
                                    ColoresApp.principal,
                                    Icons.receipt_long_rounded,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _tarjetaMetrica(
                                    'Total vendido hoy',
                                    '\$${resumen.totalVentasHoy.toStringAsFixed(2)}',
                                    const Color(0xFF00A896),
                                    Icons.attach_money_rounded,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _tarjetaMetrica(
                                    'Ingredientes críticos',
                                    '${resumen.ingredientesCriticos}',
                                    Colors.redAccent,
                                    Icons.warning_amber_rounded,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _tarjetaMetrica(
                                    'Productos bajos',
                                    '${resumen.productosBajos}',
                                    const Color(0xFFFFA726),
                                    Icons.inventory_2_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: ColoresApp.superficie,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Accesos rápidos',
                                          style: TextStyle(
                                            color: ColoresApp.textoPrincipal,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
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
                                        GridView.count(
                                          crossAxisCount: 3,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          childAspectRatio: 1.3,
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
                                              icono:
                                                  Icons.point_of_sale_rounded,
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
                                              icono:
                                                  Icons.account_balance_wallet_rounded,
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
                                              icono:
                                                  Icons.bakery_dining_rounded,
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
                                              icono:
                                                  Icons.receipt_long_rounded,
                                              onTap: () => _abrir(
                                                context,
                                                const PaginaHistorialVentas(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: ColoresApp.superficie,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Alertas',
                                          style: TextStyle(
                                            color: ColoresApp.textoPrincipal,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
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
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color:
                                                    ColoresApp.fondoSecundario,
                                                borderRadius:
                                                    BorderRadius.circular(16),
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
                                                      style: const TextStyle(
                                                        color: ColoresApp
                                                            .textoPrincipal,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.all(18),
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
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: ColoresApp.principal, size: 30),
            const Spacer(),
            Text(
              titulo,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 13,
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