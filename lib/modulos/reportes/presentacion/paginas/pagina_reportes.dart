import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../widgets/reportes_ejecutivo_supabase.dart';

enum FiltroReporteRapido {
  hoy,
  sieteDias,
  treintaDias,
  mesActual,
  personalizado,
}

class PaginaReportes extends StatefulWidget {
  const PaginaReportes({super.key});

  @override
  State<PaginaReportes> createState() => _PaginaReportesState();
}

class _PaginaReportesState extends State<PaginaReportes> {
  ReporteEjecutivoData? _reporte;
  bool _cargando = true;
  FiltroReporteRapido _filtro = FiltroReporteRapido.hoy;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _aplicarFiltro(FiltroReporteRapido.hoy, cargar: false);
    _cargar();
  }

  void _aplicarFiltro(
    FiltroReporteRapido filtro, {
    bool cargar = true,
  }) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    setState(() {
      _filtro = filtro;

      switch (filtro) {
        case FiltroReporteRapido.hoy:
          _fechaInicio = hoy;
          _fechaFin = hoy;
          break;
        case FiltroReporteRapido.sieteDias:
          _fechaInicio = hoy.subtract(const Duration(days: 6));
          _fechaFin = hoy;
          break;
        case FiltroReporteRapido.treintaDias:
          _fechaInicio = hoy.subtract(const Duration(days: 29));
          _fechaFin = hoy;
          break;
        case FiltroReporteRapido.mesActual:
          _fechaInicio = DateTime(hoy.year, hoy.month, 1);
          _fechaFin = hoy;
          break;
        case FiltroReporteRapido.personalizado:
          break;
      }
    });

    if (cargar) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
    });

    try {
      final reporte = await ReportesEjecutivoSupabase.obtenerReporteEjecutivo(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      if (!mounted) return;

      setState(() {
        _reporte = reporte;
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
            'Error cargando reportes: $e',
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

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: _builderDatePicker,
    );

    if (fecha == null) return;

    setState(() {
      _filtro = FiltroReporteRapido.personalizado;
      _fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
      if (_fechaFin.isBefore(_fechaInicio)) {
        _fechaFin = _fechaInicio;
      }
    });

    _cargar();
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: _fechaInicio,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: _builderDatePicker,
    );

    if (fecha == null) return;

    setState(() {
      _filtro = FiltroReporteRapido.personalizado;
      _fechaFin = DateTime(fecha.year, fecha.month, fecha.day);
    });

    _cargar();
  }

  Widget _builderDatePicker(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: ColoresApp.principal,
          onPrimary: Colors.black,
          surface: ColoresApp.superficie,
          onSurface: ColoresApp.textoPrincipal,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final yyyy = fecha.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatearFechaHora(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final yyyy = fecha.year.toString();
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final reporte = _reporte;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro analítico'),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
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
            : reporte == null
                ? const Center(
                    child: Text(
                      'No se pudieron cargar los reportes.',
                      style: TextStyle(color: ColoresApp.textoSecundario),
                    ),
                  )
                : RefreshIndicator(
                    color: ColoresApp.principal,
                    backgroundColor: ColoresApp.superficie,
                    onRefresh: _cargar,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1450),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cabecera(reporte),
                              const SizedBox(height: 18),
                              _filtros(),
                              const SizedBox(height: 18),
                              _gridKpis(reporte),
                              const SizedBox(height: 18),
                              _layoutPrincipal(reporte),
                              const SizedBox(height: 18),
                              _layoutSecundario(reporte),
                              const SizedBox(height: 18),
                              _bloqueInsights(reporte),
                              const SizedBox(height: 18),
                              _layoutOperativo(reporte),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _cabecera(ReporteEjecutivoData reporte) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF151515),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ColoresApp.principalClaro,
                  ColoresApp.principal,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.black,
              size: 38,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reporte ejecutivo inteligente',
                  style: TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatearFecha(reporte.fechaInicio)} - ${_formatearFecha(reporte.fechaFin)}   |   Comparado con ${_formatearFecha(reporte.fechaInicioAnterior)} - ${_formatearFecha(reporte.fechaFinAnterior)}',
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _badgeEstado(reporte),
        ],
      ),
    );
  }

  Widget _badgeEstado(ReporteEjecutivoData reporte) {
    final variacion = reporte.totalAnterior == 0
        ? reporte.totalVendido > 0
            ? 100.0
            : 0.0
        : ((reporte.totalVendido - reporte.totalAnterior) /
                reporte.totalAnterior) *
            100;

    final positivo = variacion >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: positivo
              ? ColoresApp.exito.withOpacity(0.3)
              : ColoresApp.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            positivo
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: positivo ? ColoresApp.exito : ColoresApp.error,
          ),
          const SizedBox(width: 8),
          Text(
            '${positivo ? '+' : ''}${variacion.toStringAsFixed(1)}%',
            style: TextStyle(
              color: positivo ? ColoresApp.exito : ColoresApp.error,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _botonFiltro('Hoy', FiltroReporteRapido.hoy),
          _botonFiltro('7 días', FiltroReporteRapido.sieteDias),
          _botonFiltro('30 días', FiltroReporteRapido.treintaDias),
          _botonFiltro('Mes actual', FiltroReporteRapido.mesActual),
          _botonFecha(
            titulo: 'Desde',
            valor: _formatearFecha(_fechaInicio),
            onTap: _seleccionarFechaInicio,
          ),
          _botonFecha(
            titulo: 'Hasta',
            valor: _formatearFecha(_fechaFin),
            onTap: _seleccionarFechaFin,
          ),
        ],
      ),
    );
  }

  Widget _botonFiltro(String texto, FiltroReporteRapido filtro) {
    final seleccionado = _filtro == filtro;

    return InkWell(
      onTap: () => _aplicarFiltro(filtro),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? ColoresApp.principal : ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: seleccionado ? Colors.black : ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _botonFecha({
    required String titulo,
    required String valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColoresApp.principal.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: ColoresApp.principal,
              size: 19,
            ),
            const SizedBox(width: 8),
            Text(
              '$titulo: $valor',
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridKpis(ReporteEjecutivoData reporte) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reporte.kpis.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 168,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return _tarjetaKpi(reporte.kpis[index]);
      },
    );
  }

  Widget _tarjetaKpi(KpiReporte kpi) {
    final positivo = kpi.variacionPorcentual >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            kpi.valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.principal,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  kpi.subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
              if (kpi.mostrarVariacion) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: positivo
                        ? ColoresApp.exito.withOpacity(0.12)
                        : ColoresApp.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${positivo ? '+' : ''}${kpi.variacionPorcentual.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: positivo ? ColoresApp.exito : ColoresApp.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _layoutPrincipal(ReporteEjecutivoData reporte) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 950;

        if (compacto) {
          return Column(
            children: [
              _bloque(
                titulo: 'Ventas por día',
                subtitulo: 'Ingresos diarios del rango seleccionado',
                child: _graficoBarrasDias(reporte.ventasPorDia),
              ),
              const SizedBox(height: 16),
              _bloque(
                titulo: 'Métodos de pago',
                subtitulo: 'Distribución por ingreso y transacciones',
                child: _listaMetodosPago(reporte.metodosPago),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _bloque(
                titulo: 'Ventas por día',
                subtitulo: 'Ingresos diarios del rango seleccionado',
                child: _graficoBarrasDias(reporte.ventasPorDia),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _bloque(
                titulo: 'Métodos de pago',
                subtitulo: 'Distribución por ingreso y transacciones',
                child: _listaMetodosPago(reporte.metodosPago),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _layoutSecundario(ReporteEjecutivoData reporte) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 1050;

        final izquierda = _bloque(
          titulo: 'Top productos por cantidad',
          subtitulo: 'Mayor rotación operativa',
          child: _listaTopProductos(reporte.topProductosCantidad),
        );

        final centro = _bloque(
          titulo: 'Top productos por ingresos',
          subtitulo: 'Productos que más dinero generan',
          child: _listaTopProductos(reporte.topProductosIngresos),
        );

        final derecha = _bloque(
          titulo: 'Ventas por hora',
          subtitulo: 'Horas fuertes para producción y personal',
          child: _listaHoras(reporte.ventasPorHora),
        );

        if (compacto) {
          return Column(
            children: [
              izquierda,
              const SizedBox(height: 16),
              centro,
              const SizedBox(height: 16),
              derecha,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: izquierda),
            const SizedBox(width: 16),
            Expanded(child: centro),
            const SizedBox(width: 16),
            Expanded(child: derecha),
          ],
        );
      },
    );
  }

  Widget _layoutOperativo(ReporteEjecutivoData reporte) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 1050;

        final categorias = _bloque(
          titulo: 'Categorías fuertes',
          subtitulo: 'Peso de cada línea en los ingresos',
          child: _listaCategorias(reporte.categorias),
        );

        final vendedores = _bloque(
          titulo: 'Ranking de vendedores',
          subtitulo: 'Desempeño por usuario',
          child: _listaVendedores(reporte.vendedores),
        );

        final alertas = _bloque(
          titulo: 'Alertas de stock',
          subtitulo: 'Inventario comprometido',
          child: _listaAlertas(reporte.alertasStock),
        );

        final produccion = _bloque(
          titulo: 'Producción reciente',
          subtitulo: 'Últimos movimientos de fabricación',
          child: _listaProduccion(reporte.produccionesRecientes),
        );

        if (compacto) {
          return Column(
            children: [
              categorias,
              const SizedBox(height: 16),
              vendedores,
              const SizedBox(height: 16),
              alertas,
              const SizedBox(height: 16),
              produccion,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: categorias),
                const SizedBox(width: 16),
                Expanded(child: vendedores),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: alertas),
                const SizedBox(width: 16),
                Expanded(child: produccion),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bloque({
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _graficoBarrasDias(List<SerieDiaReporte> datos) {
    if (datos.isEmpty) {
      return _vacio('No hay datos para graficar.');
    }

    double maxValor = 0;
    for (final item in datos) {
      if (item.valor > maxValor) maxValor = item.valor;
    }
    if (maxValor <= 0) maxValor = 1;

    return SizedBox(
      height: 290,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: datos.map((item) {
            final porcentaje = item.valor / maxValor;
            final altura = 28 + (porcentaje * 175);

            return Container(
              width: datos.length > 14 ? 58 : 78,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.valor.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 7),
                  Container(
                    height: altura,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          ColoresApp.principal,
                          ColoresApp.principalClaro,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.etiqueta,
                    style: const TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${item.cantidadVentas} v.',
                    style: const TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _listaMetodosPago(List<MetodoPagoReporte> datos) {
    if (datos.isEmpty) return _vacio('Sin pagos registrados.');

    return Column(
      children: datos.map((item) {
        return _filaBarra(
          titulo: item.metodo,
          subtitulo: '${item.cantidad} venta(s)',
          valor: '\$${item.total.toStringAsFixed(2)}',
          porcentaje: item.porcentaje,
        );
      }).toList(),
    );
  }

  Widget _listaTopProductos(List<TopProductoReporte> datos) {
    if (datos.isEmpty) return _vacio('Sin productos vendidos.');

    return Column(
      children: datos.map((item) {
        return _filaBarra(
          titulo: item.nombre,
          subtitulo: '${item.categoria} • ${item.cantidad} und.',
          valor: '\$${item.total.toStringAsFixed(2)}',
          porcentaje: item.porcentaje,
        );
      }).toList(),
    );
  }

  Widget _listaHoras(List<SerieHoraReporte> datos) {
    if (datos.isEmpty) return _vacio('Sin ventas por hora.');

    return Column(
      children: datos.take(8).map((item) {
        return _filaSimple(
          icono: Icons.schedule_rounded,
          titulo: item.hora,
          subtitulo: '${item.ventas} venta(s)',
          valor: '\$${item.total.toStringAsFixed(2)}',
        );
      }).toList(),
    );
  }

  Widget _listaCategorias(List<CategoriaReporte> datos) {
    if (datos.isEmpty) return _vacio('Sin categorías registradas.');

    return Column(
      children: datos.map((item) {
        return _filaBarra(
          titulo: item.categoria,
          subtitulo: '${item.cantidad} und.',
          valor: '\$${item.total.toStringAsFixed(2)}',
          porcentaje: item.porcentaje,
        );
      }).toList(),
    );
  }

  Widget _listaVendedores(List<VendedorReporte> datos) {
    if (datos.isEmpty) return _vacio('Sin vendedores en el período.');

    return Column(
      children: datos.map((item) {
        return _filaSimple(
          icono: Icons.person_rounded,
          titulo: item.nombre,
          subtitulo:
              '${item.ventas} venta(s) • Ticket \$${item.ticketPromedio.toStringAsFixed(2)}',
          valor: '\$${item.total.toStringAsFixed(2)}',
        );
      }).toList(),
    );
  }

  Widget _listaAlertas(List<AlertaStockReporte> datos) {
    if (datos.isEmpty) return _vacio('No hay alertas de stock.');

    return Column(
      children: datos.map((item) {
        final critico = item.nivel == 'Crítico';

        return _filaSimple(
          icono: Icons.warning_amber_rounded,
          iconColor: critico ? Colors.redAccent : const Color(0xFFFFA726),
          titulo: item.nombre,
          subtitulo:
              '${item.tipo} • ${item.nivel} • Mín: ${item.stockMinimo.toStringAsFixed(2)}',
          valor: item.stockActual.toStringAsFixed(3),
          valorColor: critico ? Colors.redAccent : const Color(0xFFFFA726),
        );
      }).toList(),
    );
  }

  Widget _listaProduccion(List<ProduccionRecienteReporte> datos) {
    if (datos.isEmpty) return _vacio('Sin producción reciente.');

    return Column(
      children: datos.map((item) {
        return _filaSimple(
          icono: Icons.bakery_dining_rounded,
          titulo: item.producto,
          subtitulo: '${_formatearFechaHora(item.fecha)} • ${item.usuario}',
          valor: item.cantidad.toStringAsFixed(3),
        );
      }).toList(),
    );
  }

  Widget _bloqueInsights(ReporteEjecutivoData reporte) {
    return _bloque(
      titulo: 'Lectura ejecutiva automática',
      subtitulo: 'Conclusiones accionables para tomar decisiones',
      child: Column(
        children: reporte.insights.map((insight) {
          Color color;
          IconData icono;

          switch (insight.tipo) {
            case 'positivo':
              color = ColoresApp.exito;
              icono = Icons.trending_up_rounded;
              break;
            case 'riesgo':
              color = ColoresApp.error;
              icono = Icons.dangerous_rounded;
              break;
            case 'advertencia':
              color = const Color(0xFFFFA726);
              icono = Icons.warning_amber_rounded;
              break;
            default:
              color = ColoresApp.principal;
              icono = Icons.insights_rounded;
          }

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColoresApp.fondoSecundario,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.titulo,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight.descripcion,
                        style: const TextStyle(
                          color: ColoresApp.textoSecundario,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _filaBarra({
    required String titulo,
    required String subtitulo,
    required String valor,
    required double porcentaje,
  }) {
    final porcentajeSeguro = porcentaje.clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                valor,
                style: const TextStyle(
                  color: ColoresApp.principal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${porcentajeSeguro.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: porcentajeSeguro / 100,
              minHeight: 8,
              backgroundColor: Colors.black,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColoresApp.principal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaSimple({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required String valor,
    Color iconColor = ColoresApp.principal,
    Color valorColor = ColoresApp.principal,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icono, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            valor,
            style: TextStyle(
              color: valorColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vacio(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: ColoresApp.textoSecundario,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}