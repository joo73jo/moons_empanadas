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
          constraints: const BoxConstraints(maxHeight: 720),
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detalle.ingredienteNombre,
                                        style: const TextStyle(
                                          color: ColoresApp.textoPrincipal,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                widget.usuario.nombre,
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
        color: ColoresApp.fondoPrincipal,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _tarjetaResumen(
                    'Con receta',
                    '$totalConReceta',
                    const Color(0xFF00A896),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _tarjetaResumen(
                    'Sin receta',
                    '$totalSinReceta',
                    const Color(0xFFFFA726),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _tarjetaResumen(
                    'Ingredientes',
                    '${_ingredientes.length}',
                    ColoresApp.principal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
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
                      'Productos y recetas',
                      style: TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cada producto puede tener una receta con ingredientes reales',
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
                    Expanded(
                      child: _cargando
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: ColoresApp.principal,
                              ),
                            )
                          : productos.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay productos registrados.',
                                    style: TextStyle(
                                      color: ColoresApp.textoSecundario,
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: productos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final producto = productos[index];

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: ColoresApp.fondoSecundario,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
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
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.menu_book_rounded,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        producto.nombre,
                                                        style: const TextStyle(
                                                          color: ColoresApp
                                                              .textoPrincipal,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: producto
                                                                .tieneReceta
                                                            ? const Color(
                                                                0x2200A896)
                                                            : const Color(
                                                                0x22FFA726),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        producto.tieneReceta
                                                            ? 'CON RECETA'
                                                            : 'SIN RECETA',
                                                        style: TextStyle(
                                                          color: producto
                                                                  .tieneReceta
                                                              ? const Color(
                                                                  0xFF00A896)
                                                              : const Color(
                                                                  0xFFFFA726),
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  producto.categoria,
                                                  style: const TextStyle(
                                                    color: ColoresApp
                                                        .textoSecundario,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            children: [
                                              SizedBox(
                                                width: 150,
                                                height: 42,
                                                child: ElevatedButton(
                                                  onPressed: _esDueno
                                                      ? () => _abrirEditor(
                                                            producto,
                                                          )
                                                      : null,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        ColoresApp.principal,
                                                    foregroundColor:
                                                        Colors.black,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    producto.tieneReceta
                                                        ? 'Editar receta'
                                                        : 'Crear receta',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: 150,
                                                height: 42,
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      _verReceta(producto),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor: ColoresApp
                                                        .textoPrincipal,
                                                    side: BorderSide(
                                                      color: Colors.white
                                                          .withOpacity(0.12),
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Ver receta',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (_esDueno &&
                                                  producto.tieneReceta) ...[
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  width: 150,
                                                  height: 42,
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        _eliminarReceta(
                                                          producto,
                                                        ),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.redAccent,
                                                      side: BorderSide(
                                                        color: Colors.redAccent
                                                            .withOpacity(0.45),
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Eliminar',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
}