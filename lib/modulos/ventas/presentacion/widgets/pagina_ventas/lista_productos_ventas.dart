part of '../../paginas/pagina_ventas.dart';

extension _PaginaVentasListaProductos on _PaginaVentasState {
  String _normalizarCategoria(String categoria) {
    final valor = categoria.trim().toLowerCase();

    return valor.isEmpty ? 'sin categoría' : valor;
  }

  String _nombreVisibleCategoria(List<ProductoVenta> productos) {
    if (productos.isEmpty) {
      return 'Sin categoría';
    }

    final categoria = productos.first.categoria.trim();

    return categoria.isEmpty ? 'Sin categoría' : categoria;
  }

  Map<String, List<ProductoVenta>> _agruparProductos(
    List<ProductoVenta> productos,
  ) {
    final grupos = <String, List<ProductoVenta>>{};

    for (final producto in productos) {
      final clave = _normalizarCategoria(producto.categoria);

      grupos.putIfAbsent(clave, () => []);
      grupos[clave]!.add(producto);
    }

    for (final productosCategoria in grupos.values) {
      productosCategoria.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );
    }

    final entradas = grupos.entries.toList()
      ..sort((a, b) {
        final nombreA = _nombreVisibleCategoria(a.value).toLowerCase();

        final nombreB = _nombreVisibleCategoria(b.value).toLowerCase();

        return nombreA.compareTo(nombreB);
      });

    return Map<String, List<ProductoVenta>>.fromEntries(entradas);
  }

  void _abrirCategoriasSeccion(SeccionVenta seccion) {
    _categoriasAbiertas.addAll(
      _productos
          .where((producto) => producto.seccion == seccion)
          .map((producto) => _normalizarCategoria(producto.categoria)),
    );
  }

  void _abrirTodasCategorias(List<ProductoVenta> productos) {
    _actualizarEstado(() {
      _categoriasAbiertas.addAll(
        productos.map((producto) => _normalizarCategoria(producto.categoria)),
      );
    });
  }

  void _cerrarTodasCategorias(List<ProductoVenta> productos) {
    final categorias = productos
        .map((producto) => _normalizarCategoria(producto.categoria))
        .toSet();

    _actualizarEstado(() {
      _categoriasAbiertas.removeAll(categorias);
    });
  }

  Widget _listaProductos(List<ProductoVenta> productos, bool esCelular) {
    if (_productos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ColoresApp.principal),
      );
    }

    if (productos.isEmpty) {
      return Center(
        child: Text(
          'No hay productos en ${_nombreSeccion(_seccionActiva)}.',
          style: const TextStyle(color: ColoresApp.textoSecundario),
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
              icon: const Icon(Icons.unfold_more_rounded, size: 18),
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
              icon: const Icon(Icons.unfold_less_rounded, size: 18),
              label: const Text('Cerrar todas'),
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.textoSecundario,
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
    final abierta = _categoriasAbiertas.contains(claveCategoria);

    final nombreCategoria = _nombreVisibleCategoria(productos);

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
              _actualizarEstado(() {
                if (abierta) {
                  _categoriasAbiertas.remove(claveCategoria);
                } else {
                  _categoriasAbiertas.add(claveCategoria);
                }
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColoresApp.principal.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
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
                        color: ColoresApp.textoPrincipal,
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
                      color: ColoresApp.principal.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
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
                    duration: const Duration(milliseconds: 180),
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
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: GridView.builder(
                itemCount: productos.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
}
