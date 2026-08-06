import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../widgets/dialogo_cobro.dart';
import '../widgets/dialogo_combo_sabores.dart';
import '../widgets/dialogo_producto_venta.dart';
import '../widgets/productos_supabase.dart';
import '../widgets/tarjeta_item_pedido.dart';
import '../widgets/tarjeta_producto_venta.dart';
import '../widgets/ventas_modelos.dart';
import '../widgets/ventas_supabase.dart';

class PaginaVentas extends StatefulWidget {
  final Usuario usuario;

  const PaginaVentas({
    super.key,
    required this.usuario,
  });

  @override
  State<PaginaVentas> createState() =>
      _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  List<ProductoVenta> _productos = [];

  List<PedidoPreparacion> _pedidosPreparacion = [];

  List<PedidoPreparacion> _pedidosNoEnviados = [];

  List<RecargoConfiguracion> _recargosDisponibles = [];

  final List<ItemPedido> _pedido = [];

  final Set<String> _categoriasAbiertas = {};

  String _busqueda = '';

  SeccionVenta _seccionActiva =
      SeccionVenta.individuales;

  bool _guardandoVenta = false;

  bool _modoPreparacion = false;

  bool _cargandoPreparacion = false;

  bool get _esDueno {
    return widget.usuario.rol == 'dueno';
  }

  double get _subtotal {
    return _pedido.fold(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  List<ProductoVenta> get _productosFiltrados {
    final busqueda = _busqueda.trim().toLowerCase();

    return _productos.where((producto) {
      final coincideSeccion =
          producto.seccion == _seccionActiva;

      final coincideBusqueda = busqueda.isEmpty ||
          producto.nombre.toLowerCase().contains(busqueda) ||
          producto.categoria.toLowerCase().contains(busqueda);

      return coincideSeccion && coincideBusqueda;
    }).toList();
  }

  List<ProductoVenta> get _saboresEmpanadas {
    return _productos.where((producto) {
      return producto.seccion ==
              SeccionVenta.individuales &&
          producto.categoria.toLowerCase() ==
              'empanadas';
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    await Future.wait([
      _cargarProductos(),
      _cargarRecargos(),
      _cargarPreparacion(),
    ]);
  }

  Future<void> _cargarProductos() async {
    try {
      final productos =
          await ProductosSupabase.obtenerProductos();

      if (!mounted) return;

      setState(() {
        _productos = productos;

        if (_categoriasAbiertas.isEmpty) {
          _categoriasAbiertas.addAll(
            productos.map(
              (producto) => _normalizarCategoria(
                producto.categoria,
              ),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error cargando productos: $e',
      );
    }
  }

  Future<void> _cargarRecargos() async {
    try {
      final recargos =
          await VentasSupabase.obtenerRecargosConfiguracion();

      if (!mounted) return;

      setState(() {
        _recargosDisponibles = recargos;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error cargando recargos: $e',
      );
    }
  }

  Future<void> _cargarPreparacion() async {
    if (mounted) {
      setState(() {
        _cargandoPreparacion = true;
      });
    }

    try {
      final resultados = await Future.wait([
        VentasSupabase.obtenerPedidosPreparacion(),
        VentasSupabase.obtenerPedidosNoEnviados(),
      ]);

      if (!mounted) return;

      setState(() {
        _pedidosPreparacion = resultados[0];
        _pedidosNoEnviados = resultados[1];
        _cargandoPreparacion = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoPreparacion = false;
      });

      _mostrarMensaje(
        'Error cargando pedidos: $e',
      );
    }
  }

  Future<void> _refrescarTodo() async {
    await _cargarTodo();
  }

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
  }

  String _formatearHora(DateTime fecha) {
    final hora =
        fecha.hour.toString().padLeft(2, '0');

    final minuto =
        fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _nombreSeccion(
    SeccionVenta seccion,
  ) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return 'Individuales';

      case SeccionVenta.combos:
        return 'Combos';

      case SeccionVenta.uber:
        return 'Uber';
    }
  }

  IconData _iconoSeccion(
    SeccionVenta seccion,
  ) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return Icons.fastfood_rounded;

      case SeccionVenta.combos:
        return Icons.local_offer_rounded;

      case SeccionVenta.uber:
        return Icons.delivery_dining_rounded;
    }
  }

  List<Color> _coloresSeccion(
    SeccionVenta seccion,
  ) {
    switch (seccion) {
      case SeccionVenta.individuales:
      case SeccionVenta.combos:
        return const [
          ColoresApp.principalClaro,
          ColoresApp.principal,
        ];

      case SeccionVenta.uber:
        return const [
          Color(0xFF06D6A0),
          Color(0xFF00A896),
        ];
    }
  }

  Color _colorSuaveSeccion(
    SeccionVenta seccion,
  ) {
    switch (seccion) {
      case SeccionVenta.individuales:
      case SeccionVenta.combos:
        return const Color(0xFFD99A1B);

      case SeccionVenta.uber:
        return const Color(0xFF00A896);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: ColoresApp.principal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<ResultadoSeleccionCombo?> _seleccionarCombo(
    ProductoVenta producto,
  ) {
    if (producto.componentesCombo.isEmpty) {
      _mostrarMensaje(
        'Este combo no tiene componentes configurados. Edítalo antes de venderlo.',
      );

      return Future.value(null);
    }

    return showDialog<ResultadoSeleccionCombo>(
      context: context,
      builder: (_) => DialogoComboSabores(
        combo: producto,
      ),
    );
  }

  Future<void> _agregarProducto(
    ProductoVenta producto,
  ) async {
    List<String> sabores = [];
    List<EleccionComponenteCombo> eleccionesCombo = [];

    if (producto.esCombo) {
      final seleccion =
          await _seleccionarCombo(producto);

      if (seleccion == null ||
          seleccion.elecciones.isEmpty) {
        return;
      }

      eleccionesCombo = seleccion.elecciones;
    } else if (producto.requiereSabores) {
      _mostrarMensaje(
        'Este producto usa la selección antigua de sabores. Edítalo y configúralo como combo para venderlo correctamente.',
      );

      return;
    }

    final index = _pedido.indexWhere(
      (item) => item.mismaConfiguracion(
        producto,
        sabores,
        otrasEleccionesCombo: eleccionesCombo,
      ),
    );

    setState(() {
      if (index >= 0) {
        _pedido[index].cantidad++;
      } else {
        _pedido.add(
          ItemPedido(
            producto: producto,
            cantidad: 1,
            sabores: sabores,
            eleccionesCombo: eleccionesCombo,
          ),
        );
      }
    });
  }

  Future<void> _editarConfiguracionItem(
    ItemPedido item,
  ) async {
    if (!item.producto.esCombo) {
      return;
    }

    final seleccion =
        await _seleccionarCombo(item.producto);

    if (seleccion == null ||
        seleccion.elecciones.isEmpty) {
      return;
    }

    setState(() {
      item.eleccionesCombo = seleccion.elecciones;
      item.sabores = [];
    });

    _mostrarMensaje(
      'Configuración del combo actualizada.',
    );
  }

  void _sumarCantidad(ItemPedido item) {
    setState(() {
      item.cantidad++;
    });
  }

  void _restarCantidad(ItemPedido item) {
    setState(() {
      if (item.cantidad > 1) {
        item.cantidad--;
      } else {
        _pedido.remove(item);
      }
    });
  }

  void _eliminarItem(ItemPedido item) {
    setState(() {
      _pedido.remove(item);
    });
  }

  void _limpiarPedido() {
    setState(() {
      _pedido.clear();
    });
  }

  Future<void> _finalizarPedido() async {
    if (_pedido.isEmpty) {
      _mostrarMensaje(
        'No hay productos en el pedido.',
      );

      return;
    }

    final existeCajaAbierta =
        await VentasSupabase.hayCajaAbierta();

    if (!existeCajaAbierta) {
      _mostrarMensaje(
        'Primero debes abrir caja.',
      );

      return;
    }

    if (!mounted) return;

    final resultado =
        await showDialog<ResultadoCobro>(
      context: context,
      builder: (_) => DialogoCobro(
        subtotal: _subtotal,
        recargosDisponibles:
            _recargosDisponibles,
      ),
    );

    if (resultado == null) return;

    final datosPedido = resultado.datosPedido;

    if (datosPedido == null) {
      _mostrarMensaje(
        'No se recibieron los datos del pedido.',
      );

      return;
    }

    final items =
        List<ItemPedido>.from(_pedido);

    final subtotalActual = _subtotal;

    setState(() {
      _guardandoVenta = true;
    });

    try {
      await VentasSupabase.guardarPedido(
        usuarioLogin: widget.usuario.usuario,
        resultadoCobro:
            resultado.cobroRealizado
                ? resultado
                : null,
        items: items,
        subtotal: subtotalActual,
        datosPedido: datosPedido,
      );

      if (!mounted) return;

      setState(() {
        _pedido.clear();
        _guardandoVenta = false;
      });

      await _refrescarTodo();

      if (!mounted) return;

      if (datosPedido.enviarPreparacion &&
          resultado.cobroRealizado) {
        _mostrarMensaje(
          'Pedido cobrado y enviado a preparación.',
        );
      } else if (datosPedido.enviarPreparacion) {
        _mostrarMensaje(
          'Pedido enviado a preparación. El cobro quedó pendiente.',
        );
      } else if (resultado.cobroRealizado) {
        _mostrarMensaje(
          'Pedido cobrado y guardado para enviar después.',
        );
      } else {
        _mostrarMensaje(
          'Pedido guardado. Cobro y preparación pendientes.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardandoVenta = false;
      });

      _mostrarMensaje(
        'Error guardando pedido: $e',
      );
    }
  }

  Future<void> _cobrarPedidoPendiente(
    PedidoPreparacion pedido,
  ) async {
    final existeCajaAbierta =
        await VentasSupabase.hayCajaAbierta();

    if (!existeCajaAbierta) {
      _mostrarMensaje(
        'Primero debes abrir caja.',
      );

      return;
    }

    if (!mounted) return;

    final resultado =
        await showDialog<ResultadoCobro>(
      context: context,
      builder: (_) => DialogoCobro(
        total: pedido.total,
        soloCobro: true,
        nombrePedido: pedido.nombrePedido,
      ),
    );

    if (resultado == null) return;

    try {
      await VentasSupabase.cobrarVentaPendiente(
        ventaId: pedido.id,
        resultadoCobro: resultado,
      );

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje(
        '${pedido.nombrePedido} cobrado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error cobrando el pedido: $e',
      );
    }
  }

  Future<void> _enviarPedidoPreparacion(
    PedidoPreparacion pedido,
  ) async {
    try {
      await VentasSupabase.enviarPedidoPreparacion(
        pedido.id,
      );

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje(
        '${pedido.nombrePedido} enviado a preparación.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error enviando el pedido: $e',
      );
    }
  }

  Future<void> _marcarPedidoListo(
    PedidoPreparacion pedido,
  ) async {
    try {
      await VentasSupabase.marcarPedidoListo(
        pedido.id,
      );

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje(
        '${pedido.nombrePedido} marcado como listo.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error marcando el pedido como listo: $e',
      );
    }
  }

  Future<void> _marcarDineroEntregado(
    PedidoPreparacion pedido,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: const Text(
          'Confirmar entrega',
          style: TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          '¿Confirmas que ${pedido.responsableDinero} entregó el dinero de ${pedido.nombrePedido}?',
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancelar',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  ColoresApp.principal,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await VentasSupabase.marcarDineroEntregado(
        pedido.id,
      );

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje(
        'Dinero marcado como entregado.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error actualizando el dinero: $e',
      );
    }
  }

  Future<void> _nuevoProducto() async {
    final resultado =
        await showDialog<ProductoVenta>(
      context: context,
      builder: (_) =>
          const DialogoProductoVenta(),
    );

    if (resultado == null) return;

    try {
      final productoCreado =
          await ProductosSupabase.crearProducto(
        resultado,
      );

      if (!mounted) return;

      setState(() {
        _productos.add(productoCreado);
        _categoriasAbiertas.add(
          _normalizarCategoria(
            productoCreado.categoria,
          ),
        );
      });

      _mostrarMensaje(
        'Producto creado.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error creando producto: $e',
      );
    }
  }

  Future<void> _editarProducto(
    ProductoVenta producto,
  ) async {
    final resultado =
        await showDialog<ProductoVenta>(
      context: context,
      builder: (_) => DialogoProductoVenta(
        producto: producto,
      ),
    );

    if (resultado == null) return;

    try {
      final productoActualizado =
          await ProductosSupabase
              .actualizarProducto(
        resultado.copyWith(
          id: producto.id,
        ),
      );

      if (!mounted) return;

      setState(() {
        final index = _productos.indexWhere(
          (item) => item.id == producto.id,
        );

        if (index >= 0) {
          _productos[index] =
              productoActualizado;
        }

        _categoriasAbiertas.add(
          _normalizarCategoria(
            productoActualizado.categoria,
          ),
        );

        for (final item in _pedido) {
          if (item.producto.id ==
              producto.id) {
            item.producto =
                productoActualizado;
          }
        }
      });

      _mostrarMensaje(
        'Producto actualizado.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error actualizando producto: $e',
      );
    }
  }

  Future<void> _eliminarProducto(
    ProductoVenta producto,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: const Text(
          'Eliminar producto',
          style: TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          '¿Seguro que deseas eliminar "${producto.nombre}"?',
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancelar',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ProductosSupabase.eliminarProducto(
        producto.id,
      );

      if (!mounted) return;

      setState(() {
        _productos.removeWhere(
          (item) => item.id == producto.id,
        );

        _pedido.removeWhere(
          (item) =>
              item.producto.id == producto.id,
        );
      });

      _mostrarMensaje(
        'Producto eliminado.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error eliminando producto: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;

    final esCelular =
        _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ventas',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_esDueno)
            IconButton(
              tooltip: 'Nuevo producto',
              onPressed: _nuevoProducto,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: ColoresApp.principal,
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                widget.usuario.nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      ColoresApp.textoSecundario,
                  fontWeight: FontWeight.w600,
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
        child: esCelular
            ? _layoutCelular(productos)
            : _layoutEscritorio(productos),
      ),
    );
  }

  Widget _layoutCelular(
    List<ProductoVenta> productos,
  ) {
    return RefreshIndicator(
      color: ColoresApp.principal,
      backgroundColor:
          ColoresApp.superficie,
      onRefresh: _refrescarTodo,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _panelProductos(
              productos: productos,
              alturaFija: false,
              esCelular: true,
            ),
            const SizedBox(height: 14),
            _panelPedido(
              alturaFija: false,
              esCelular: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _layoutEscritorio(
    List<ProductoVenta> productos,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _panelProductos(
              productos: productos,
              alturaFija: true,
              esCelular: false,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _panelPedido(
              alturaFija: true,
              esCelular: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelProductos({
    required List<ProductoVenta> productos,
    required bool alturaFija,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        esCelular ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisSize: alturaFija
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          Text(
            _modoPreparacion
                ? 'Pedidos'
                : 'Productos',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 23 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _modoPreparacion
                ? 'Pedidos pendientes de preparación, cobro o envío'
                : 'Selecciona los productos del pedido',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _selectorSecciones(),
          const SizedBox(height: 16),
          if (_modoPreparacion)
            _botonRefrescarPreparacion()
          else
            _campoBusqueda(),
          const SizedBox(height: 18),
          if (alturaFija)
            Expanded(
              child: _modoPreparacion
                  ? _listaGestionPedidos(
                      esCelular,
                    )
                  : _listaProductos(
                      productos,
                      esCelular,
                    ),
            )
          else if (_modoPreparacion)
            _listaGestionPedidos(
              esCelular,
            )
          else
            _listaProductos(
              productos,
              esCelular,
            ),
        ],
      ),
    );
  }

  Widget _selectorSecciones() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...SeccionVenta.values.map(
          (seccion) {
            final activa =
                !_modoPreparacion &&
                    _seccionActiva == seccion;

            return _botonSeccion(
              texto: _nombreSeccion(seccion),
              icono: _iconoSeccion(seccion),
              activo: activa,
              colores: _coloresSeccion(seccion),
              onTap: () {
                setState(() {
                  _modoPreparacion = false;
                  _seccionActiva = seccion;
                  _abrirCategoriasSeccion(seccion);
                });
              },
            );
          },
        ),
        _botonSeccion(
          texto: 'Pedidos',
          icono:
              Icons.restaurant_menu_rounded,
          activo: _modoPreparacion,
          colores: const [
            Color(0xFFFFD166),
            ColoresApp.principal,
          ],
          contador:
              _pedidosPreparacion.length +
                  _pedidosNoEnviados.length,
          onTap: () {
            setState(() {
              _modoPreparacion = true;
            });

            _cargarPreparacion();
          },
        ),
      ],
    );
  }

  Widget _botonSeccion({
    required String texto,
    required IconData icono,
    required bool activo,
    required List<Color> colores,
    required VoidCallback onTap,
    int contador = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: activo
              ? LinearGradient(
                  colors: colores,
                )
              : null,
          color: activo
              ? null
              : ColoresApp.fondoSecundario,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: activo
                ? Colors.transparent
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 18,
              color: activo
                  ? Colors.black
                  : ColoresApp.textoPrincipal,
            ),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(
                color: activo
                    ? Colors.black
                    : ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (contador > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: activo
                      ? Colors.black
                      : ColoresApp.principal,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '$contador',
                  style: TextStyle(
                    color: activo
                        ? ColoresApp.principal
                        : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _botonRefrescarPreparacion() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _cargarPreparacion,
        icon: const Icon(
          Icons.refresh_rounded,
          color: ColoresApp.principal,
        ),
        label: const Text(
          'Actualizar pedidos',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              ColoresApp.textoPrincipal,
          side: BorderSide(
            color: Colors.white.withOpacity(0.14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _campoBusqueda() {
    return TextField(
      onChanged: (valor) {
        setState(() {
          _busqueda = valor;

          if (valor.trim().isNotEmpty) {
            _categoriasAbiertas.addAll(
              _productosFiltrados.map(
                (producto) => _normalizarCategoria(
                  producto.categoria,
                ),
              ),
            );
          }
        });
      },
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      decoration: InputDecoration(
        hintText:
            'Buscar en ${_nombreSeccion(_seccionActiva).toLowerCase()}...',
        hintStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color:
              _colorSuaveSeccion(_seccionActiva),
        ),
        filled: true,
        fillColor:
            ColoresApp.fondoSecundario,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }

  String _normalizarCategoria(String categoria) {
    final valor = categoria.trim().toLowerCase();

    return valor.isEmpty ? 'sin categoría' : valor;
  }

  String _nombreVisibleCategoria(
    List<ProductoVenta> productos,
  ) {
    if (productos.isEmpty) {
      return 'Sin categoría';
    }

    final categoria = productos.first.categoria.trim();

    return categoria.isEmpty
        ? 'Sin categoría'
        : categoria;
  }

  Map<String, List<ProductoVenta>> _agruparProductos(
    List<ProductoVenta> productos,
  ) {
    final grupos = <String, List<ProductoVenta>>{};

    for (final producto in productos) {
      final clave = _normalizarCategoria(
        producto.categoria,
      );

      grupos.putIfAbsent(clave, () => []);
      grupos[clave]!.add(producto);
    }

    for (final productosCategoria in grupos.values) {
      productosCategoria.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(
              b.nombre.toLowerCase(),
            ),
      );
    }

    final entradas = grupos.entries.toList()
      ..sort((a, b) {
        final nombreA = _nombreVisibleCategoria(
          a.value,
        ).toLowerCase();

        final nombreB = _nombreVisibleCategoria(
          b.value,
        ).toLowerCase();

        return nombreA.compareTo(nombreB);
      });

    return Map<String, List<ProductoVenta>>.fromEntries(
      entradas,
    );
  }

  void _abrirCategoriasSeccion(
    SeccionVenta seccion,
  ) {
    _categoriasAbiertas.addAll(
      _productos
          .where(
            (producto) => producto.seccion == seccion,
          )
          .map(
            (producto) => _normalizarCategoria(
              producto.categoria,
            ),
          ),
    );
  }

  void _abrirTodasCategorias(
    List<ProductoVenta> productos,
  ) {
    setState(() {
      _categoriasAbiertas.addAll(
        productos.map(
          (producto) => _normalizarCategoria(
            producto.categoria,
          ),
        ),
      );
    });
  }

  void _cerrarTodasCategorias(
    List<ProductoVenta> productos,
  ) {
    final categorias = productos
        .map(
          (producto) => _normalizarCategoria(
            producto.categoria,
          ),
        )
        .toSet();

    setState(() {
      _categoriasAbiertas.removeAll(categorias);
    });
  }

  Widget _listaProductos(
    List<ProductoVenta> productos,
    bool esCelular,
  ) {
    if (_productos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColoresApp.principal,
        ),
      );
    }

    if (productos.isEmpty) {
      return Center(
        child: Text(
          'No hay productos en ${_nombreSeccion(_seccionActiva)}.',
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
          ),
        ),
      );
    }

    final grupos = _agruparProductos(productos);

    return ListView(
      shrinkWrap: esCelular,
      physics: esCelular
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${grupos.length} ${grupos.length == 1 ? 'categoría' : 'categorías'}',
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _abrirTodasCategorias(productos);
              },
              icon: const Icon(
                Icons.unfold_more_rounded,
                size: 18,
              ),
              label: const Text('Abrir todas'),
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.principal,
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () {
                _cerrarTodasCategorias(productos);
              },
              icon: const Icon(
                Icons.unfold_less_rounded,
                size: 18,
              ),
              label: const Text('Cerrar todas'),
              style: TextButton.styleFrom(
                foregroundColor:
                    ColoresApp.textoSecundario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...grupos.entries.map(
          (entrada) => _bloqueCategoriaProductos(
            claveCategoria: entrada.key,
            productos: entrada.value,
            esCelular: esCelular,
          ),
        ),
      ],
    );
  }

  Widget _bloqueCategoriaProductos({
    required String claveCategoria,
    required List<ProductoVenta> productos,
    required bool esCelular,
  }) {
    final abierta =
        _categoriasAbiertas.contains(claveCategoria);

    final nombreCategoria =
        _nombreVisibleCategoria(productos);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: abierta
              ? ColoresApp.principal.withOpacity(0.24)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (abierta) {
                  _categoriasAbiertas.remove(
                    claveCategoria,
                  );
                } else {
                  _categoriasAbiertas.add(
                    claveCategoria,
                  );
                }
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColoresApp.principal
                          .withOpacity(0.14),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: ColoresApp.principal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nombreCategoria,
                      style: const TextStyle(
                        color:
                            ColoresApp.textoPrincipal,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresApp.principal
                          .withOpacity(0.14),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${productos.length}',
                      style: const TextStyle(
                        color: ColoresApp.principal,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: abierta ? 0.5 : 0,
                    duration:
                        const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ColoresApp.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(
              width: double.infinity,
              height: 0,
            ),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                0,
                14,
                14,
              ),
              child: GridView.builder(
                itemCount: productos.length,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                gridDelegate: esCelular
                    ? const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisExtent: 230,
                        mainAxisSpacing: 12,
                      )
                    : const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        mainAxisExtent: 235,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                itemBuilder: (context, index) {
                  final producto = productos[index];

                  return TarjetaProductoVenta(
                    producto: producto,
                    esDueno: _esDueno,
                    onAgregar: () {
                      _agregarProducto(producto);
                    },
                    onEditar: () {
                      _editarProducto(producto);
                    },
                    onEliminar: () {
                      _eliminarProducto(producto);
                    },
                  );
                },
              ),
            ),
            crossFadeState: abierta
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _listaGestionPedidos(
    bool esCelular,
  ) {
    if (_cargandoPreparacion) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColoresApp.principal,
        ),
      );
    }

    if (_pedidosPreparacion.isEmpty &&
        _pedidosNoEnviados.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Text(
          'No hay pedidos pendientes.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColoresApp.textoSecundario,
          ),
        ),
      );
    }

    final contenido = <Widget>[];

    if (_pedidosNoEnviados.isNotEmpty) {
      contenido.add(
        _tituloGrupo(
          'Pendientes de enviar',
          _pedidosNoEnviados.length,
        ),
      );

      for (final pedido
          in _pedidosNoEnviados) {
        contenido.add(
          const SizedBox(height: 12),
        );

        contenido.add(
          _tarjetaPedidoGestion(
            pedido,
            enviado: false,
          ),
        );
      }
    }

    if (_pedidosPreparacion.isNotEmpty) {
      if (contenido.isNotEmpty) {
        contenido.add(
          const SizedBox(height: 22),
        );
      }

      contenido.add(
        _tituloGrupo(
          'En preparación',
          _pedidosPreparacion.length,
        ),
      );

      for (final pedido
          in _pedidosPreparacion) {
        contenido.add(
          const SizedBox(height: 12),
        );

        contenido.add(
          _tarjetaPedidoGestion(
            pedido,
            enviado: true,
          ),
        );
      }
    }

    return ListView(
      shrinkWrap: esCelular,
      physics: esCelular
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: contenido,
    );
  }

  Widget _tituloGrupo(
    String titulo,
    int cantidad,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color:
                ColoresApp.principal.withOpacity(0.15),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            '$cantidad',
            style: const TextStyle(
              color: ColoresApp.principal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaPedidoGestion(
    PedidoPreparacion pedido, {
    required bool enviado,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              ColoresApp.principal.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColoresApp.principal
                      .withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Text(
                  '#${pedido.id}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.nombrePedido,
                      style: const TextStyle(
                        color:
                            ColoresApp.textoPrincipal,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${nombreTipoPedido(pedido.tipoPedido)} • ${_formatearHora(pedido.fecha)}',
                      style: const TextStyle(
                        color:
                            ColoresApp.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _etiquetaEstadoCobro(
                pedido.estadoCobro,
              ),
            ],
          ),
          if (pedido.barrio.isNotEmpty) ...[
            const SizedBox(height: 12),
            _datoPedido(
              Icons.location_on_rounded,
              'Barrio: ${pedido.barrio}',
            ),
          ],
          if (pedido.responsableDinero
              .isNotEmpty) ...[
            const SizedBox(height: 8),
            _datoPedido(
              Icons.delivery_dining_rounded,
              'Dinero con: ${pedido.responsableDinero}',
            ),
          ],
          const SizedBox(height: 14),
          ...pedido.detalles.map(
            (detalle) => Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${detalle.cantidad} x ${detalle.nombreProducto}',
                    style: const TextStyle(
                      color:
                          ColoresApp.textoPrincipal,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  if (detalle
                      .descripcionesConfiguracion
                      .isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...detalle
                        .descripcionesConfiguracion
                        .map(
                          (descripcion) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 3,
                            ),
                            child: Text(
                              '• $descripcion',
                              style: const TextStyle(
                                color:
                                    ColoresApp.principal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _filaResumenPedido(
            'Consumo',
            pedido.subtotal,
          ),
          if (pedido.totalRecargos > 0) ...[
            const SizedBox(height: 6),
            _filaResumenPedido(
              'Recargos',
              pedido.totalRecargos,
            ),
          ],
          const SizedBox(height: 6),
          _filaResumenPedido(
            'Total',
            pedido.total,
            resaltar: true,
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pedido.pendienteDeCobro)
                _botonAccionPedido(
                  texto: 'Cobrar',
                  icono: Icons.payments_rounded,
                  onPressed: () {
                    _cobrarPedidoPendiente(
                      pedido,
                    );
                  },
                ),
              if (!enviado)
                _botonAccionPedido(
                  texto: 'Enviar a preparación',
                  icono:
                      Icons.restaurant_menu_rounded,
                  onPressed: () {
                    _enviarPedidoPreparacion(
                      pedido,
                    );
                  },
                ),
              if (enviado)
                _botonAccionPedido(
                  texto: 'Marcar listo',
                  icono:
                      Icons.check_circle_rounded,
                  onPressed: () {
                    _marcarPedidoListo(
                      pedido,
                    );
                  },
                ),
              if (pedido.dineroConRepartidor)
                _botonAccionPedido(
                  texto: 'Dinero entregado',
                  icono:
                      Icons.account_balance_wallet_rounded,
                  onPressed: () {
                    _marcarDineroEntregado(
                      pedido,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datoPedido(
    IconData icono,
    String texto,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          size: 18,
          color: ColoresApp.principal,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _etiquetaEstadoCobro(
    EstadoCobroVenta estado,
  ) {
    final Color color;

    switch (estado) {
      case EstadoCobroVenta.pagado:
      case EstadoCobroVenta.entregado:
        color = ColoresApp.exito;
        break;

      case EstadoCobroVenta.pendientePago:
        color = const Color(0xFFFFA726);
        break;

      case EstadoCobroVenta.cobradoRepartidor:
        color = ColoresApp.principal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        nombreEstadoCobro(estado),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _botonAccionPedido({
    required String texto,
    required IconData icono,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icono,
        size: 18,
      ),
      label: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(13),
        ),
      ),
    );
  }

  Widget _filaResumenPedido(
    String titulo,
    double valor, {
    bool resaltar = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: resaltar
                  ? ColoresApp.textoPrincipal
                  : ColoresApp.textoSecundario,
              fontWeight: resaltar
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: resaltar
                ? ColoresApp.principal
                : ColoresApp.textoPrincipal,
            fontSize: resaltar ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _panelPedido({
    required bool alturaFija,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        esCelular ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisSize: alturaFija
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          Text(
            'Pedido actual',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 23 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Atendido por: ${widget.usuario.nombre}',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
            ),
          ),
          const SizedBox(height: 18),
          if (alturaFija)
            Expanded(
              child: _listaPedido(
                esCelular,
              ),
            )
          else
            _listaPedido(
              esCelular,
            ),
          const SizedBox(height: 16),
          _totalesPedido(),
          const SizedBox(height: 16),
          _botonesPedido(
            esCelular,
          ),
        ],
      ),
    );
  }

  Widget _listaPedido(
    bool esCelular,
  ) {
    if (_pedido.isEmpty) {
      return Container(
        width: double.infinity,
        height: esCelular ? 130 : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Text(
          'No hay productos agregados.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColoresApp.textoSecundario,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _pedido.length,
      shrinkWrap: esCelular,
      physics: esCelular
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (_, __) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final item = _pedido[index];

        return TarjetaItemPedido(
          item: item,
          onSumar: () {
            _sumarCantidad(item);
          },
          onRestar: () {
            _restarCantidad(item);
          },
          onEliminar: () {
            _eliminarItem(item);
          },
          onEditarSabores:
              item.producto.esCombo &&
                      item.eleccionesCombo.isNotEmpty
                  ? () {
                      _editarConfiguracionItem(item);
                    }
                  : null,
        );
      },
    );
  }

  Widget _totalesPedido() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _filaTotal(
            'Subtotal',
            _subtotal,
          ),
          const SizedBox(height: 10),
          _filaTotal(
            'Total inicial',
            _subtotal,
            resaltar: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'Los recargos se aplican al finalizar el pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonesPedido(
    bool esCelular,
  ) {
    final limpiar = OutlinedButton(
      onPressed:
          _guardandoVenta ? null : _limpiarPedido,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            ColoresApp.textoPrincipal,
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
      child: const Text(
        'Limpiar',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final finalizar = Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        gradient: LinearGradient(
          colors:
              _coloresSeccion(_seccionActiva),
        ),
      ),
      child: ElevatedButton(
        onPressed: _guardandoVenta
            ? null
            : _finalizarPedido,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: _guardandoVenta
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.black,
                  ),
                ),
              )
            : const Text(
                'Finalizar pedido',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
      ),
    );

    if (esCelular) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: finalizar,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: limpiar,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: limpiar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: finalizar,
          ),
        ),
      ],
    );
  }

  Widget _filaTotal(
    String titulo,
    double valor, {
    bool resaltar = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: resaltar
                  ? ColoresApp.textoPrincipal
                  : ColoresApp.textoSecundario,
              fontSize: resaltar ? 18 : 15,
              fontWeight: resaltar
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: resaltar
                ? _colorSuaveSeccion(
                    _seccionActiva,
                  )
                : ColoresApp.textoPrincipal,
            fontSize: resaltar ? 22 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}