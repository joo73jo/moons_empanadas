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
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 760,
          constraints: const BoxConstraints(maxHeight: 760),
          padding: const EdgeInsets.all(20),
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
                      style: const TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
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
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 14,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final detalle = venta.detalles[index];

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ColoresApp.fondoSecundario,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detalle.nombreProducto,
                                  style: const TextStyle(
                                    color: ColoresApp.textoPrincipal,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  detalle.categoriaProducto,
                                  style: const TextStyle(
                                    color: ColoresApp.textoSecundario,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _datoDetalle(
                                        'Precio',
                                        detalle.precioUnitario,
                                      ),
                                    ),
                                    Expanded(
                                      child: _datoDetalleCantidad(
                                        'Cantidad',
                                        detalle.cantidad,
                                      ),
                                    ),
                                    Expanded(
                                      child: _datoDetalle(
                                        'Subtotal',
                                        detalle.subtotal,
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: ColoresApp.principal
                                                  .withOpacity(0.16),
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
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColoresApp.fondoSecundario,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datoDetalle(String titulo, double valor, {bool resaltar = false}) {
    return Column(
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
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _datoDetalleCantidad(String titulo, int valor) {
    return Column(
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
          '$valor',
          style: const TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ventas = _ventasFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
      ),
      body: Container(
        color: ColoresApp.fondoPrincipal,
        padding: const EdgeInsets.all(20),
        child: Container(
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
              const Text(
                'Ventas recientes',
                style: TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consulta rápida del historial registrado en Supabase',
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _busqueda = value;
                  });
                },
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  hintText: 'Buscar por venta, vendedor, método o producto...',
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
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ColoresApp.principal,
                        ),
                      )
                    : ventas.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay ventas registradas.',
                              style: TextStyle(
                                color: ColoresApp.textoSecundario,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: ventas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final venta = ventas[index];

                              return InkWell(
                                onTap: () => _verDetalle(venta),
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: ColoresApp.fondoSecundario,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              ColoresApp.principalClaro,
                                              ColoresApp.principal,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_rounded,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Venta #${venta.id}',
                                              style: const TextStyle(
                                                color: ColoresApp.textoPrincipal,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatearFechaHora(venta.fecha),
                                              style: const TextStyle(
                                                color: ColoresApp.textoSecundario,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${venta.vendedorNombre} • ${_nombreMetodo(venta)}',
                                              style: const TextStyle(
                                                color: ColoresApp.textoSecundario,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}