import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../widgets/dialogo_receta.dart';
import '../widgets/recetas_supabase.dart';

class PaginaRecetas extends StatefulWidget {
  final Usuario usuario;

  const PaginaRecetas({
    super.key,
    required this.usuario,
  });

  @override
  State<PaginaRecetas> createState() => _PaginaRecetasState();
}

class _PaginaRecetasState extends State<PaginaRecetas> {
  List<ProductoReceta> _productos = [];
  List<IngredienteRecetaDisponible> _ingredientes = [];
  bool _cargando = true;
  String _busqueda = '';

  bool get _esDueno => widget.usuario.rol == 'dueno';

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
      final productos = await RecetasSupabase.obtenerProductos();
      final ingredientes = await RecetasSupabase.obtenerIngredientes();

      if (!mounted) return;

      setState(() {
        _productos = productos;
        _ingredientes = ingredientes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
      _mostrarMensaje('Error cargando recetas: $e');
    }
  }

  List<ProductoReceta> get _productosFiltrados {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _productos;

    return _productos.where((p) {
      return p.nombre.toLowerCase().contains(q) ||
          p.categoria.toLowerCase().contains(q);
    }).toList();
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

  Future<void> _abrirEditor(ProductoReceta producto) async {
    final receta = await RecetasSupabase.obtenerRecetaPorProducto(producto.id);

    if (!mounted) return;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => DialogoReceta(
        producto: producto,
        ingredientesDisponibles: _ingredientes,
        recetaExistente: receta,
      ),
    );

    if (resultado == null) return;

    try {
      final detalles = List<RecetaDetalleItem>.from(
        resultado['detalles'] as List,
      );

      await RecetasSupabase.guardarReceta(
        productoId: producto.id,
        nombreReceta: resultado['nombreReceta'] as String,
        detalles: detalles,
      );

      if (!mounted) return;
      _mostrarMensaje('Receta guardada correctamente.');
      await _cargar();
    } catch (e) {
      _mostrarMensaje('Error guardando receta: $e');
    }
  }

  Future<void> _verReceta(ProductoReceta producto) async {
    final receta = await RecetasSupabase.obtenerRecetaPorProducto(producto.id);

    if (!mounted) return;

    if (receta == null) {
      _mostrarMensaje('Este producto todavía no tiene receta.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 720,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
            maxWidth: MediaQuery.of(context).size.width * 0.94,
          ),
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
                      'Receta • ${producto.nombre}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
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
                  receta.nombreReceta,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: receta.detalles.isEmpty
                    ? const Center(
                        child: Text(
                          'La receta no tiene ingredientes.',
                          style: TextStyle(
                            color: ColoresApp.textoSecundario,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: receta.detalles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final detalle = receta.detalles[index];

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ColoresApp.fondoSecundario,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compacto = constraints.maxWidth < 430;

                                if (compacto) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detalle.ingredienteNombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: ColoresApp.textoPrincipal,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        detalle.ingredienteCategoria,
                                        style: const TextStyle(
                                          color: ColoresApp.textoSecundario,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${detalle.cantidad.toStringAsFixed(3)} ${detalle.unidadMedida}',
                                        style: const TextStyle(
                                          color: ColoresApp.principal,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            detalle.ingredienteNombre,
                                            style: const TextStyle(
                                              color:
                                                  ColoresApp.textoPrincipal,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            detalle.ingredienteCategoria,
                                            style: const TextStyle(
                                              color:
                                                  ColoresApp.textoSecundario,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${detalle.cantidad.toStringAsFixed(3)} ${detalle.unidadMedida}',
                                      style: const TextStyle(
                                        color: ColoresApp.principal,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                );
                              },
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

  Future<void> _eliminarReceta(ProductoReceta producto) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: ColoresApp.superficie,
      title: const Text(
        'Eliminar receta',
        style: TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(
        '¿Seguro que deseas eliminar la receta de "${producto.nombre}"?\n\nEsta acción no se puede deshacer.',
        style: const TextStyle(
          color: ColoresApp.textoSecundario,
          height: 1.35,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Sí, eliminar',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  try {
    await RecetasSupabase.eliminarReceta(producto.id);
    if (!mounted) return;
    _mostrarMensaje('Receta eliminada.');
    await _cargar();
  } catch (e) {
    _mostrarMensaje('Error eliminando receta: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;
    final totalConReceta = _productos.where((p) => p.tieneReceta).length;
    final totalSinReceta = _productos.where((p) => !p.tieneReceta).length;
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: esCelular ? 10 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: esCelular ? 110 : 220),
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
        child: RefreshIndicator(
          color: ColoresApp.principal,
          backgroundColor: ColoresApp.superficie,
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(esCelular ? 14 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  children: [
                    _resumenSuperior(
                      totalConReceta: totalConReceta,
                      totalSinReceta: totalSinReceta,
                      totalIngredientes: _ingredientes.length,
                    ),
                    const SizedBox(height: 18),
                    _panelProductosRecetas(
                      productos: productos,
                      esCelular: esCelular,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumenSuperior({
    required int totalConReceta,
    required int totalSinReceta,
    required int totalIngredientes,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho < 430 ? 2 : 3;
        final alto = ancho < 430 ? 118.0 : 112.0;

        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: (ancho / columnas) / alto,
          children: [
            _tarjetaResumen(
              'Con receta',
              '$totalConReceta',
              const Color(0xFF00A896),
            ),
            _tarjetaResumen(
              'Sin receta',
              '$totalSinReceta',
              const Color(0xFFFFA726),
            ),
            _tarjetaResumen(
              'Ingredientes',
              '$totalIngredientes',
              ColoresApp.principal,
            ),
          ],
        );
      },
    );
  }

  Widget _panelProductosRecetas({
    required List<ProductoReceta> productos,
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
            'Productos y recetas',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cada producto puede tener una receta con ingredientes reales',
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
            style: const TextStyle(color: ColoresApp.textoPrincipal),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
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
              height: 260,
              child: Center(
                child: CircularProgressIndicator(
                  color: ColoresApp.principal,
                ),
              ),
            )
          else if (productos.isEmpty)
            Container(
              width: double.infinity,
              height: 180,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No hay productos registrados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 15,
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: productos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final producto = productos[index];
                return _tarjetaProductoReceta(producto);
              },
            ),
        ],
      ),
    );
  }

  Widget _tarjetaProductoReceta(ProductoReceta producto) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSecundario,
            borderRadius: BorderRadius.circular(18),
          ),
          child: compacto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezadoProducto(producto),
                    const SizedBox(height: 14),
                    _accionesProducto(producto, compacto: true),
                  ],
                )
              : Row(
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
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _encabezadoProducto(
                        producto,
                        conIcono: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _accionesProducto(producto, compacto: false),
                  ],
                ),
        );
      },
    );
  }

  Widget _encabezadoProducto(
    ProductoReceta producto, {
    bool conIcono = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conIcono) ...[
          Container(
            width: 54,
            height: 54,
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
              Icons.menu_book_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                producto.categoria,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: producto.tieneReceta
                ? const Color(0x2200A896)
                : const Color(0x22FFA726),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            producto.tieneReceta ? 'CON RECETA' : 'SIN RECETA',
            style: TextStyle(
              color: producto.tieneReceta
                  ? const Color(0xFF00A896)
                  : const Color(0xFFFFA726),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _accionesProducto(
    ProductoReceta producto, {
    required bool compacto,
  }) {
    final textoAccion =
        producto.tieneReceta ? 'Editar receta' : 'Crear receta';

    if (compacto) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _botonPrincipal(producto, textoAccion),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _botonVer(producto),
          ),
          if (_esDueno && producto.tieneReceta) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: _botonEliminar(producto),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 42,
          child: _botonPrincipal(producto, textoAccion),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          height: 42,
          child: _botonVer(producto),
        ),
        if (_esDueno && producto.tieneReceta) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            height: 42,
            child: _botonEliminar(producto),
          ),
        ],
      ],
    );
  }

  Widget _botonPrincipal(ProductoReceta producto, String texto) {
    return ElevatedButton(
      onPressed: _esDueno ? () => _abrirEditor(producto) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _botonVer(ProductoReceta producto) {
    return OutlinedButton(
      onPressed: () => _verReceta(producto),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Ver receta',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _botonEliminar(ProductoReceta producto) {
    return OutlinedButton(
      onPressed: () => _eliminarReceta(producto),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: BorderSide(
          color: Colors.redAccent.withOpacity(0.45),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Eliminar',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, Color color) {
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
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
              height: 1.15,
            ),
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}