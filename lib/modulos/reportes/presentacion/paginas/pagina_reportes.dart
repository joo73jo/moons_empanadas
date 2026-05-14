import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../widgets/reportes_ejecutivo_supabase.dart';

class PaginaReportes extends StatefulWidget {
  const PaginaReportes({super.key});

  @override
  State<PaginaReportes> createState() => _PaginaReportesState();
}

class _PaginaReportesState extends State<PaginaReportes> {
  ReporteEjecutivoData? _reporte;
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
      final reporte = await ReportesEjecutivoSupabase.obtenerReporteEjecutivo();

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

  String _formatearFecha(DateTime fecha) {
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
        title: const Text('Reportes'),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        color: ColoresApp.fondoPrincipal,
        padding: const EdgeInsets.all(20),
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
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1350),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reporte ejecutivo',
                              style: TextStyle(
                                color: ColoresApp.textoPrincipal,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Vista general del negocio con indicadores y tendencias',
                              style: TextStyle(
                                color: ColoresApp.textoSecundario,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reporte.kpis.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 320,
                                mainAxisExtent: 150,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemBuilder: (context, index) {
                                final kpi = reporte.kpis[index];
                                return _tarjetaKpi(kpi);
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _bloque(
                                    titulo: 'Ventas últimos 7 días',
                                    subtitulo: 'Comportamiento diario de ingresos',
                                    child: _graficoBarrasVentas(
                                      reporte.ventas7Dias,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _bloque(
                                    titulo: 'Métodos de pago',
                                    subtitulo: 'Distribución del ingreso de hoy',
                                    child: Column(
                                      children: reporte.metodosPago
                                          .map((item) => _filaMetodoPago(item))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _bloque(
                                    titulo: 'Top productos',
                                    subtitulo: 'Los más vendidos en la última semana',
                                    child: Column(
                                      children: reporte.topProductos
                                          .map((item) => _filaTopProducto(item))
                                          .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _bloque(
                                    titulo: 'Alertas de stock',
                                    subtitulo:
                                        'Ingredientes y productos comprometidos',
                                    child: reporte.alertasStock.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              'No hay alertas de stock.',
                                              style: TextStyle(
                                                color:
                                                    ColoresApp.textoSecundario,
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: reporte.alertasStock
                                                .map(
                                                  (item) => _filaAlerta(item),
                                                )
                                                .toList(),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _bloque(
                              titulo: 'Producción reciente',
                              subtitulo: 'Últimos movimientos de fabricación',
                              child: reporte.produccionesRecientes.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'No hay producciones registradas.',
                                        style: TextStyle(
                                          color: ColoresApp.textoSecundario,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: reporte.produccionesRecientes
                                          .map(
                                            (item) => _filaProduccion(
                                              item,
                                              _formatearFecha(item.fecha),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _tarjetaKpi(KpiReporte kpi) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            kpi.valor,
            style: const TextStyle(
              color: ColoresApp.principal,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kpi.subtitulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
        ],
      ),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 22,
              fontWeight: FontWeight.w800,
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

  Widget _graficoBarrasVentas(List<SerieDiaReporte> datos) {
    double maxValor = 0;
    for (final item in datos) {
      if (item.valor > maxValor) {
        maxValor = item.valor;
      }
    }
    if (maxValor <= 0) {
      maxValor = 1;
    }

    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: datos.map((item) {
          final porcentaje = item.valor / maxValor;
          final altura = 40 + (porcentaje * 150);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.etiqueta,
                    style: const TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _filaMetodoPago(MetodoPagoReporte item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.metodo,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: ColoresApp.principal,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaTopProducto(TopProductoReporte item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.nombre,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${item.cantidad} und',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: ColoresApp.principal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaAlerta(AlertaStockReporte item) {
    final esCritico = item.nivel == 'Crítico';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: esCritico ? Colors.redAccent : const Color(0xFFFFA726),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.nombre,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${item.nivel} • ${item.stockActual.toStringAsFixed(3)}',
            style: TextStyle(
              color: esCritico ? Colors.redAccent : const Color(0xFFFFA726),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaProduccion(
    ProduccionRecienteReporte item,
    String fechaTexto,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fechaTexto • ${item.usuario}',
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.cantidad.toStringAsFixed(3),
            style: const TextStyle(
              color: ColoresApp.principal,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}