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
  State<PaginaVentas> createState() => _PaginaVentasState();
}

class _PaginaVentasState extends State<PaginaVentas> {
  late List<ProductoVenta> _productos;
  final List<ItemPedido> _pedido = [];

  String _busqueda = '';
  SeccionVenta _seccionActiva = SeccionVenta.individuales;
  bool _guardandoVenta = false;

  bool get _esDueno => widget.usuario.rol == 'dueno';

  @override
  void initState() {
    super.initState();
    _productos = [];
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await ProductosSupabase.obtenerProductos();

      if (!mounted) return;

      setState(() {
        _productos = productos;
      });
    } catch (e) {
      debugPrint('ERROR PRODUCTOS SUPABASE: $e');
      _mostrarMensaje('Error cargando productos desde Supabase: $e');
    }
  }

  List<ProductoVenta> get _productosFiltrados {
    return _productos.where((producto) {
      final coincideSeccion = producto.seccion == _seccionActiva;
      final coincideBusqueda = _busqueda.trim().isEmpty ||
          producto.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          producto.categoria.toLowerCase().contains(_busqueda.toLowerCase());

      return coincideSeccion && coincideBusqueda;
    }).toList();
  }

  List<ProductoVenta> get _saboresEmpanadas {
    return _productos.where((producto) {
      return producto.seccion == SeccionVenta.individuales &&
          producto.categoria.toLowerCase() == 'empanadas';
    }).toList();
  }

  double get _subtotal {
    return _pedido.fold(0, (total, item) => total + item.subtotal);
  }

  String _nombreSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return 'Individuales';
      case SeccionVenta.combos:
        return 'Combos';
      case SeccionVenta.uber:
        return 'Uber';
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
        return const [
          ColoresApp.principalClaro,
          ColoresApp.principal,
        ];
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

  Color _colorSuaveSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return const Color(0xFFD99A1B);
      case SeccionVenta.combos:
        return const Color(0xFFD99A1B);
      case SeccionVenta.uber:
        return const Color(0xFF00A896);
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

  Future<List<String>?> _seleccionarSabores(ProductoVenta producto) {
    if (_saboresEmpanadas.isEmpty) {
      _mostrarMensaje('No hay empanadas disponibles para seleccionar sabores.');
      return Future.value(null);
    }

    return showDialog<List<String>>(
      context: context,
      builder: (_) => DialogoComboSabores(
        combo: producto,
        saboresDisponibles: _saboresEmpanadas,
      ),
    );
  }

  Future<void> _agregarProducto(ProductoVenta producto) async {
    List<String> sabores = [];

    if (producto.requiereSabores) {
      final seleccion = await _seleccionarSabores(producto);

      if (seleccion == null || seleccion.isEmpty) {
        return;
      }

      sabores = seleccion;
    }

    final index = _pedido.indexWhere(
      (item) => item.mismaConfiguracion(producto, sabores),
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
          ),
        );
      }
    });
  }

  Future<void> _editarSaboresItem(ItemPedido item) async {
    final seleccion = await _seleccionarSabores(item.producto);

    if (seleccion == null || seleccion.isEmpty) {
      return;
    }

    setState(() {
      item.sabores = seleccion;
    });

    _mostrarMensaje('Sabores actualizados.');
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

  Future<void> _cobrarPedido() async {
    if (_pedido.isEmpty) {
      _mostrarMensaje('No hay productos en el pedido.');
      return;
    }

    final existeCajaAbierta = await VentasSupabase.hayCajaAbierta();
    if (!existeCajaAbierta) {
      _mostrarMensaje('Primero debes abrir caja.');
      return;
    }

    final resultado = await showDialog<ResultadoCobro>(
      context: context,
      builder: (_) => DialogoCobro(total: _subtotal),
    );

    if (resultado == null) return;

    setState(() {
      _guardandoVenta = true;
    });

    try {
      await VentasSupabase.guardarVenta(
        usuarioLogin: widget.usuario.usuario,
        resultadoCobro: resultado,
        items: List<ItemPedido>.from(_pedido),
        subtotal: _subtotal,
      );

      if (!mounted) return;

      setState(() {
        _pedido.clear();
        _guardandoVenta = false;
      });

      _mostrarMensaje('Venta guardada correctamente en Supabase.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardandoVenta = false;
      });

      _mostrarMensaje('Error guardando venta: $e');
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
      });

      _mostrarMensaje('Producto creado.');
    } catch (e) {
      _mostrarMensaje('Error creando producto en Supabase.');
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
        final index = _productos.indexWhere((p) => p.id == producto.id);
        if (index >= 0) {
          _productos[index] = productoActualizado;
        }

        for (final item in _pedido) {
          if (item.producto.id == producto.id) {
            item.producto = productoActualizado;
          }
        }
      });

      _mostrarMensaje('Producto actualizado.');
    } catch (e) {
      _mostrarMensaje('Error actualizando producto en Supabase.');
    }
  }

  Future<void> _eliminarProducto(ProductoVenta producto) async {
    try {
      await ProductosSupabase.eliminarProducto(producto.id);

      if (!mounted) return;

      setState(() {
        _productos.removeWhere((p) => p.id == producto.id);
        _pedido.removeWhere((item) => item.producto.id == producto.id);
      });

      _mostrarMensaje('Producto eliminado.');
    } catch (e) {
      _mostrarMensaje('Error eliminando producto en Supabase.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esCelular ? 'Ventas' : 'Ventas',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_esDueno)
            esCelular
                ? IconButton(
                    onPressed: _nuevoProducto,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: ColoresApp.principal,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: _nuevoProducto,
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: ColoresApp.principal,
                      ),
                      label: const Text(
                        'Nuevo producto',
                        style: TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          Padding(
            padding: EdgeInsets.only(right: esCelular ? 10 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: esCelular ? 92 : 180),
                child: Text(
                  widget.usuario.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontWeight: FontWeight.w600,
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
      onRefresh: _cargarProductos,
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
            _panelPedido(
              alturaFija: false,
              esCelular: true,
            ),
            const SizedBox(height: 18),
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
    final contenido = Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 16 : 18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: alturaFija ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            'Productos',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 23 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Empanadas, combos y productos por sección',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          _selectorSecciones(),
          const SizedBox(height: 16),
          _campoBusqueda(),
          const SizedBox(height: 18),
          if (alturaFija)
            Expanded(
              child: _listaProductos(productos, esCelular),
            )
          else
            _listaProductos(productos, esCelular),
        ],
      ),
    );

    return contenido;
  }

  Widget _selectorSecciones() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: SeccionVenta.values.map((seccion) {
        final activa = _seccionActiva == seccion;
        final colores = _coloresSeccion(seccion);

        return InkWell(
          onTap: () {
            setState(() {
              _seccionActiva = seccion;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: activa ? LinearGradient(colors: colores) : null,
              color: activa ? null : ColoresApp.fondoSecundario,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activa ? Colors.transparent : Colors.white.withOpacity(0.08),
              ),
              boxShadow: activa
                  ? [
                      BoxShadow(
                        color: colores.last.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconoSeccion(seccion),
                  size: 18,
                  color: activa ? Colors.black : ColoresApp.textoPrincipal,
                ),
                const SizedBox(width: 8),
                Text(
                  _nombreSeccion(seccion),
                  style: TextStyle(
                    color: activa ? Colors.black : ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _campoBusqueda() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _busqueda = value;
        });
      },
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        hintText: 'Buscar en ${_nombreSeccion(_seccionActiva).toLowerCase()}...',
        hintStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: _colorSuaveSeccion(_seccionActiva),
        ),
        filled: true,
        fillColor: ColoresApp.fondoSecundario,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _colorSuaveSeccion(_seccionActiva),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _listaProductos(List<ProductoVenta> productos, bool esCelular) {
    if (_productos.isEmpty) {
      return SizedBox(
        height: esCelular ? 220 : null,
        child: const Center(
          child: CircularProgressIndicator(
            color: ColoresApp.principal,
          ),
        ),
      );
    }

    if (productos.isEmpty) {
      return SizedBox(
        height: esCelular ? 180 : null,
        child: Center(
          child: Text(
            'No hay productos en ${_nombreSeccion(_seccionActiva)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    if (esCelular) {
      return ListView.separated(
        itemCount: productos.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final producto = productos[index];

          return SizedBox(
            height: 220,
            child: TarjetaProductoVenta(
              producto: producto,
              esDueno: _esDueno,
              onAgregar: () => _agregarProducto(producto),
              onEditar: () => _editarProducto(producto),
              onEliminar: () => _eliminarProducto(producto),
            ),
          );
        },
      );
    }

    return GridView.builder(
      itemCount: productos.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
          onAgregar: () => _agregarProducto(producto),
          onEditar: () => _editarProducto(producto),
          onEliminar: () => _eliminarProducto(producto),
        );
      },
    );
  }

  Widget _panelPedido({
    required bool alturaFija,
    required bool esCelular,
  }) {
    final contenido = Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 16 : 18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: alturaFija ? MainAxisSize.max : MainAxisSize.min,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          if (alturaFija)
            Expanded(
              child: _listaPedido(esCelular),
            )
          else
            _listaPedido(esCelular),
          const SizedBox(height: 16),
          _totalesPedido(),
          const SizedBox(height: 16),
          _botonesPedido(esCelular),
        ],
      ),
    );

    return contenido;
  }

  Widget _listaPedido(bool esCelular) {
    if (_pedido.isEmpty) {
      return Container(
        width: double.infinity,
        height: esCelular ? 130 : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No hay productos agregados.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 15,
          ),
        ),
      );
    }

    if (esCelular) {
      return ListView.separated(
        itemCount: _pedido.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _pedido[index];

          return TarjetaItemPedido(
            item: item,
            onSumar: () => _sumarCantidad(item),
            onRestar: () => _restarCantidad(item),
            onEliminar: () => _eliminarItem(item),
            onEditarSabores:
                item.sabores.isNotEmpty ? () => _editarSaboresItem(item) : null,
          );
        },
      );
    }

    return ListView.separated(
      itemCount: _pedido.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _pedido[index];

        return TarjetaItemPedido(
          item: item,
          onSumar: () => _sumarCantidad(item),
          onRestar: () => _restarCantidad(item),
          onEliminar: () => _eliminarItem(item),
          onEditarSabores:
              item.sabores.isNotEmpty ? () => _editarSaboresItem(item) : null,
        );
      },
    );
  }

  Widget _totalesPedido() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _filaTotal('Subtotal', _subtotal),
          const SizedBox(height: 10),
          _filaTotal('Total', _subtotal, resaltar: true),
        ],
      ),
    );
  }

  Widget _botonesPedido(bool esCelular) {
    if (esCelular) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _botonCobrar(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _botonLimpiar(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: _botonLimpiar(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: _botonCobrar(),
          ),
        ),
      ],
    );
  }

  Widget _botonLimpiar() {
    return OutlinedButton(
      onPressed: _limpiarPedido,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        foregroundColor: ColoresApp.textoPrincipal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Text(
        'Limpiar',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _botonCobrar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: _coloresSeccion(_seccionActiva)),
      ),
      child: ElevatedButton(
        onPressed: _guardandoVenta ? null : _cobrarPedido,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _guardandoVenta
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.black,
                  ),
                ),
              )
            : const Text(
                'Cobrar',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _filaTotal(String titulo, double valor, {bool resaltar = false}) {
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
              fontWeight: resaltar ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color: resaltar
                  ? _colorSuaveSeccion(_seccionActiva)
                  : ColoresApp.textoPrincipal,
              fontSize: resaltar ? 22 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}