import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../presentacion/widgets/ventas_historial_supabase.dart';

class PaginaHistorialVentas extends StatefulWidget {
  const PaginaHistorialVentas({super.key});

  @override
  State<PaginaHistorialVentas> createState() => _PaginaHistorialVentasState();
}

class _PaginaHistorialVentasState extends State<PaginaHistorialVentas> {
  List<VentaHistorial> _ventas = [];
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _cargando = true;
    });

    try {
      final ventas = await VentasHistorialSupabase.obtenerVentas();

      if (!mounted) return;

      setState(() {
        _ventas = ventas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      _mostrarMensaje('Error cargando historial: $e');
    }
  }

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
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

  String _formatearFechaHora(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final yyyy = fecha.year.toString();
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _nombreMetodo(VentaHistorial venta) {
    switch (venta.metodoPago) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return venta.banco == null || venta.banco!.isEmpty
            ? 'Transferencia'
            : 'Transferencia • ${venta.banco}';
      case 'tarjeta':
        return venta.datofono == null || venta.datofono!.isEmpty
            ? 'Tarjeta'
            : 'Tarjeta • ${venta.datofono}';
      case 'mixto':
        return 'Pago mixto';
      default:
        return venta.metodoPago;
    }
  }

  List<VentaHistorial> get _ventasFiltradas {
    final q = _busqueda.trim().toLowerCase();

    if (q.isEmpty) return _ventas;

    return _ventas.where((venta) {
      final coincideVenta = venta.id.toString().contains(q) ||
          venta.vendedorNombre.toLowerCase().contains(q) ||
          venta.vendedorLogin.toLowerCase().contains(q) ||
          _nombreMetodo(venta).toLowerCase().contains(q);

      final coincideDetalles = venta.detalles.any((detalle) =>
          detalle.nombreProducto.toLowerCase().contains(q) ||
          detalle.categoriaProducto.toLowerCase().contains(q) ||
          detalle.sabores.any((sabor) => sabor.toLowerCase().contains(q)));

      return coincideVenta || coincideDetalles;
    }).toList();
  }

  Future<void> _verDetalle(VentaHistorial venta) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        final ancho = MediaQuery.of(context).size.width;
        final alto = MediaQuery.of(context).size.height;
        final esCelular = ancho < 760;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: esCelular ? ancho * 0.94 : 760,
            constraints: BoxConstraints(
              maxHeight: alto * 0.88,
              maxWidth: ancho * 0.94,
            ),
            padding: EdgeInsets.all(esCelular ? 16 : 20),
            decoration: BoxDecoration(
              color: ColoresApp.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Venta #${venta.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: esCelular ? 22 : 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_formatearFechaHora(venta.fecha)} • ${venta.vendedorNombre} • ${_nombreMetodo(venta)}',
                    maxLines: esCelular ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: venta.detalles.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay detalles para esta venta.',
                            style: TextStyle(
                              color: ColoresApp.textoSecundario,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: venta.detalles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final detalle = venta.detalles[index];
                            return _tarjetaDetalleVenta(detalle);
                          },
                        ),
                ),
                const SizedBox(height: 14),
                _resumenTotalDetalle(venta, esCelular),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tarjetaDetalleVenta(DetalleVentaHistorial detalle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 430;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detalle.nombreProducto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detalle.categoriaProducto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              if (compacto)
                Column(
                  children: [
                    _datoDetalleCaja(
                      'Precio',
                      '\$${detalle.precioUnitario.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _datoDetalleCaja(
                      'Cantidad',
                      '${detalle.cantidad}',
                    ),
                    const SizedBox(height: 8),
                    _datoDetalleCaja(
                      'Subtotal',
                      '\$${detalle.subtotal.toStringAsFixed(2)}',
                      resaltar: true,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _datoDetalleCaja(
                        'Precio',
                        '\$${detalle.precioUnitario.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _datoDetalleCaja(
                        'Cantidad',
                        '${detalle.cantidad}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _datoDetalleCaja(
                        'Subtotal',
                        '\$${detalle.subtotal.toStringAsFixed(2)}',
                        resaltar: true,
                      ),
                    ),
                  ],
                ),
              if (detalle.sabores.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Sabores',
                  style: TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    detalle.sabores.length,
                    (i) {
                      final sabor = detalle.sabores[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColoresApp.principal.withOpacity(0.16),
                          ),
                        ),
                        child: Text(
                          '${i + 1}. $sabor',
                          style: const TextStyle(
                            color: ColoresApp.textoPrincipal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _resumenTotalDetalle(VentaHistorial venta, bool esCelular) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: esCelular
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subtotal: \$${venta.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${venta.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtotal: \$${venta.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Total: \$${venta.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _datoDetalleCaja(
    String titulo,
    String valor, {
    bool resaltar = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
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
              color: ColoresApp.textoSecundario,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ventas = _ventasFiltradas;
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: ColoresApp.fondoPrincipal,
        child: RefreshIndicator(
          color: ColoresApp.principal,
          backgroundColor: ColoresApp.superficie,
          onRefresh: _cargarVentas,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(esCelular ? 14 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Container(
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
                        'Ventas recientes',
                        style: TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: esCelular ? 24 : 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Consulta rápida del historial registrado en Supabase',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _busqueda = value;
                          });
                        },
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              esCelular ? 'Buscar venta...' : 'Buscar por venta, vendedor, método o producto...',
                          hintStyle: const TextStyle(
                            color: ColoresApp.textoSecundario,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: ColoresApp.principal,
                          ),
                          filled: true,
                          fillColor: ColoresApp.fondoSecundario,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_cargando)
                        const SizedBox(
                          height: 320,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColoresApp.principal,
                            ),
                          ),
                        )
                      else if (ventas.isEmpty)
                        Container(
                          width: double.infinity,
                          height: 260,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: ColoresApp.fondoSecundario,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'No hay ventas registradas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ColoresApp.textoSecundario,
                              fontSize: 15,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          itemCount: ventas.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final venta = ventas[index];
                            return _tarjetaVenta(venta);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaVenta(VentaHistorial venta) {
    return InkWell(
      onTap: () => _verDetalle(venta),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(18),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 560;

            if (compacto) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _iconoVenta(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoVenta(venta),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _resumenVenta(venta, compacto: true),
                ],
              );
            }

            return Row(
              children: [
                _iconoVenta(),
                const SizedBox(width: 14),
                Expanded(
                  child: _infoVenta(venta),
                ),
                const SizedBox(width: 12),
                _resumenVenta(venta, compacto: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _iconoVenta() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ColoresApp.principalClaro,
            ColoresApp.principal,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.receipt_long_rounded,
        color: Colors.black,
      ),
    );
  }

  Widget _infoVenta(VentaHistorial venta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venta #${venta.id}',
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
          _formatearFechaHora(venta.fecha),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${venta.vendedorNombre} • ${_nombreMetodo(venta)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 13,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _resumenVenta(
    VentaHistorial venta, {
    required bool compacto,
  }) {
    final contenido = Column(
      crossAxisAlignment:
          compacto ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          '\$${venta.total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: ColoresApp.principal,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${venta.detalles.length} detalle(s)',
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 12,
          ),
        ),
      ],
    );

    if (compacto) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        child: contenido,
      );
    }

    return contenido;
  }
}