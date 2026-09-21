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

part '../widgets/pagina_ventas/panel_productos_ventas.dart';
part '../widgets/pagina_ventas/selector_secciones_ventas.dart';
part '../widgets/pagina_ventas/lista_productos_ventas.dart';
part '../widgets/pagina_ventas/panel_gestion_pedidos.dart';
part '../widgets/pagina_ventas/panel_pedido_actual.dart';

class PaginaVentas extends StatefulWidget {
  final Usuario usuario;

  const PaginaVentas({super.key, required this.usuario});

  @override
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  List<ProductoVenta> _productos = [];

  List<PedidoPreparacion> _pedidosPreparacion = [];

  List<PedidoPreparacion> _pedidosNoEnviados = [];

  List<RecargoConfiguracion> _recargosDisponibles = [];

  List<PlataformaConfiguracion> _plataformasDisponibles = [];

  final List<ItemPedido> _pedido = [];

  final Set<String> _categoriasAbiertas = {};

  String _busqueda = '';

  SeccionVenta _seccionActiva = SeccionVenta.individuales;

  bool _guardandoVenta = false;

  bool _modoPreparacion = false;

  bool _cargandoPreparacion = false;

  bool get _esDueno {
    return widget.usuario.rol == 'dueno';
  }

  double get _subtotal {
    return _pedido.fold(0, (total, item) => total + item.subtotal);
  }

  List<ProductoVenta> get _productosFiltrados {
    final busqueda = _busqueda.trim().toLowerCase();

    return _productos.where((producto) {
      final coincideSeccion = producto.seccion == _seccionActiva;

      final coincideBusqueda =
          busqueda.isEmpty ||
          producto.nombre.toLowerCase().contains(busqueda) ||
          producto.categoria.toLowerCase().contains(busqueda);

      return coincideSeccion && coincideBusqueda;
    }).toList();
  }

  List<ProductoVenta> get _saboresEmpanadas {
    return _productos.where((producto) {
      return producto.seccion == SeccionVenta.individuales &&
          producto.categoria.toLowerCase() == 'empanadas';
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
      _cargarPlataformas(),
      _cargarPreparacion(),
    ]);
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await ProductosSupabase.obtenerProductos();

      if (!mounted) return;

      setState(() {
        _productos = productos;

        if (_categoriasAbiertas.isEmpty) {
          _categoriasAbiertas.addAll(
            productos.map(
              (producto) => _normalizarCategoria(producto.categoria),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error cargando productos: $e');
    }
  }

  Future<void> _cargarRecargos() async {
    try {
      final recargos = await VentasSupabase.obtenerRecargosConfiguracion();

      if (!mounted) return;

      setState(() {
        _recargosDisponibles = recargos;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error cargando recargos: $e');
    }
  }

  Future<void> _cargarPlataformas() async {
    try {
      final plataformas =
          await VentasSupabase.obtenerPlataformasConfiguracion();

      if (!mounted) return;

      setState(() {
        _plataformasDisponibles = plataformas;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error cargando plataformas: $e');
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

      _mostrarMensaje('Error cargando pedidos: $e');
    }
  }

  Future<void> _refrescarTodo() async {
    await _cargarTodo();
  }

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');

    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _nombreSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return 'Individuales';

      case SeccionVenta.combos:
        return 'Combos';

      case SeccionVenta.uber:
        return 'Plataformas';
    }
  }

  IconData _iconoSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return Icons.fastfood_rounded;

      case SeccionVenta.combos:
        return Icons.local_offer_rounded;

      case SeccionVenta.uber:
        return Icons.delivery_dining_rounded;
    }
  }

  List<Color> _coloresSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
      case SeccionVenta.combos:
        return const [ColoresApp.principalClaro, ColoresApp.principal];

      case SeccionVenta.uber:
        return const [Color(0xFF06D6A0), Color(0xFF00A896)];
    }
  }

  Color _colorSuaveSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
      case SeccionVenta.combos:
        return const Color(0xFFD99A1B);

      case SeccionVenta.uber:
        return const Color(0xFF00A896);
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
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: ColoresApp.principal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<ResultadoSeleccionCombo?> _seleccionarCombo(ProductoVenta producto) {
    if (producto.componentesCombo.isEmpty) {
      _mostrarMensaje(
        'Este combo no tiene componentes configurados. EdÃÆ’­talo antes de venderlo.',
      );

      return Future.value(null);
    }

    return showDialog<ResultadoSeleccionCombo>(
      context: context,
      builder: (_) => DialogoComboSabores(combo: producto),
    );
  }

  Future<void> _agregarProducto(ProductoVenta producto) async {
    List<String> sabores = [];
    List<EleccionComponenteCombo> eleccionesCombo = [];

    if (producto.esCombo) {
      final seleccion = await _seleccionarCombo(producto);

      if (seleccion == null || seleccion.elecciones.isEmpty) {
        return;
      }

      eleccionesCombo = seleccion.elecciones;
    } else if (producto.requiereSabores) {
      _mostrarMensaje(
        'Este producto usa la selecciÃÆ’³n antigua de sabores. EdÃÆ’­talo y configÃÆ’ºralo como combo para venderlo correctamente.',
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

  Future<void> _editarConfiguracionItem(ItemPedido item) async {
    if (!item.producto.esCombo) {
      return;
    }

    final seleccion = await _seleccionarCombo(item.producto);

    if (seleccion == null || seleccion.elecciones.isEmpty) {
      return;
    }

    setState(() {
      item.eleccionesCombo = seleccion.elecciones;
      item.sabores = [];
    });

    _mostrarMensaje('ConfiguraciÃÆ’³n del combo actualizada.');
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
      _mostrarMensaje('No hay productos en el pedido.');

      return;
    }

    final existeCajaAbierta = await VentasSupabase.hayCajaAbierta();

    if (!existeCajaAbierta) {
      _mostrarMensaje('Primero debes abrir caja.');

      return;
    }

    if (!mounted) return;

    final resultado = await showDialog<ResultadoCobro>(
      context: context,
      builder: (_) => DialogoCobro(
        subtotal: _subtotal,
        recargosDisponibles: _recargosDisponibles,
        esVentaPlataforma: _seccionActiva == SeccionVenta.uber,
        plataformasDisponibles: _plataformasDisponibles,
      ),
    );

    if (resultado == null) return;

    final datosPedido = resultado.datosPedido;

    if (datosPedido == null) {
      _mostrarMensaje('No se recibieron los datos del pedido.');

      return;
    }

    final items = List<ItemPedido>.from(_pedido);

    final subtotalActual = _subtotal;

    setState(() {
      _guardandoVenta = true;
    });

    try {
      await VentasSupabase.guardarPedido(
        usuarioLogin: widget.usuario.usuario,
        resultadoCobro: resultado.cobroRealizado ? resultado : null,
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

      if (datosPedido.enviarPreparacion && resultado.cobroRealizado) {
        _mostrarMensaje('Pedido cobrado y enviado a preparaciÃÆ’³n.');
      } else if (datosPedido.enviarPreparacion) {
        _mostrarMensaje(
          'Pedido enviado a preparaciÃÆ’³n. El cobro quedÃÆ’³ pendiente.',
        );
      } else if (resultado.cobroRealizado) {
        _mostrarMensaje('Pedido cobrado y guardado para enviar despuÃÆ’©s.');
      } else {
        _mostrarMensaje('Pedido guardado. Cobro y preparaciÃÆ’³n pendientes.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardandoVenta = false;
      });

      _mostrarMensaje('Error guardando pedido: $e');
    }
  }

  Future<void> _cobrarPedidoPendiente(PedidoPreparacion pedido) async {
    final existeCajaAbierta = await VentasSupabase.hayCajaAbierta();

    if (!existeCajaAbierta) {
      _mostrarMensaje('Primero debes abrir caja.');

      return;
    }

    if (!mounted) return;

    final resultado = await showDialog<ResultadoCobro>(
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

      _mostrarMensaje('${pedido.nombrePedido} cobrado correctamente.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error cobrando el pedido: $e');
    }
  }

  Future<void> _enviarPedidoPreparacion(PedidoPreparacion pedido) async {
    try {
      await VentasSupabase.enviarPedidoPreparacion(pedido.id);

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje('${pedido.nombrePedido} enviado a preparaciÃÆ’³n.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error enviando el pedido: $e');
    }
  }

  Future<void> _marcarPedidoListo(PedidoPreparacion pedido) async {
    try {
      await VentasSupabase.marcarPedidoListo(pedido.id);

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje('${pedido.nombrePedido} marcado como listo.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error marcando el pedido como listo: $e');
    }
  }

  Future<void> _marcarDineroEntregado(PedidoPreparacion pedido) async {
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
          '¿Confirmas que ${pedido.responsableDinero} entregÃÆ’³ el dinero de ${pedido.nombrePedido}?',
          style: const TextStyle(color: ColoresApp.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.principal,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await VentasSupabase.marcarDineroEntregado(pedido.id);

      await _cargarPreparacion();

      if (!mounted) return;

      _mostrarMensaje('Dinero marcado como entregado.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error actualizando el dinero: $e');
    }
  }

  Future<void> _nuevoProducto() async {
    final resultado = await showDialog<ProductoVenta>(
      context: context,
      builder: (_) => const DialogoProductoVenta(),
    );

    if (resultado == null) return;

    try {
      final productoCreado = await ProductosSupabase.crearProducto(resultado);

      if (!mounted) return;

      setState(() {
        _productos.add(productoCreado);
        _categoriasAbiertas.add(_normalizarCategoria(productoCreado.categoria));
      });

      _mostrarMensaje('Producto creado.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error creando producto: $e');
    }
  }

  Future<void> _editarProducto(ProductoVenta producto) async {
    final resultado = await showDialog<ProductoVenta>(
      context: context,
      builder: (_) => DialogoProductoVenta(producto: producto),
    );

    if (resultado == null) return;

    try {
      final productoActualizado = await ProductosSupabase.actualizarProducto(
        resultado.copyWith(id: producto.id),
      );

      if (!mounted) return;

      setState(() {
        final index = _productos.indexWhere((item) => item.id == producto.id);

        if (index >= 0) {
          _productos[index] = productoActualizado;
        }

        _categoriasAbiertas.add(
          _normalizarCategoria(productoActualizado.categoria),
        );

        for (final item in _pedido) {
          if (item.producto.id == producto.id) {
            item.producto = productoActualizado;
          }
        }
      });

      _mostrarMensaje('Producto actualizado.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error actualizando producto: $e');
    }
  }

  Future<void> _eliminarProducto(ProductoVenta producto) async {
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
          style: const TextStyle(color: ColoresApp.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
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
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ProductosSupabase.eliminarProducto(producto.id);

      if (!mounted) return;

      setState(() {
        _productos.removeWhere((item) => item.id == producto.id);

        _pedido.removeWhere((item) => item.producto.id == producto.id);
      });

      _mostrarMensaje('Producto eliminado.');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error eliminando producto: $e');
    }
  }

  void _actualizarEstado(VoidCallback accion) {
    if (!mounted) return;
    setState(accion);
  }

  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;

    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas', overflow: TextOverflow.ellipsis),
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
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                widget.usuario.nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
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

  Widget _layoutCelular(List<ProductoVenta> productos) {
    return RefreshIndicator(
      color: ColoresApp.principal,
      backgroundColor: ColoresApp.superficie,
      onRefresh: _refrescarTodo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _panelProductos(
              productos: productos,
              alturaFija: false,
              esCelular: true,
            ),
            const SizedBox(height: 14),
            _panelPedido(alturaFija: false, esCelular: true),
          ],
        ),
      ),
    );
  }

  Widget _layoutEscritorio(List<ProductoVenta> productos) {
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
            child: _panelPedido(alturaFija: true, esCelular: false),
          ),
        ],
      ),
    );
  }
}
