part of '../../paginas/pagina_ventas.dart';

extension _PaginaVentasSelectorSecciones on _PaginaVentasState {
  Widget _selectorSecciones() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...SeccionVenta.values.map((seccion) {
          final activa = !_modoPreparacion && _seccionActiva == seccion;

          return _botonSeccion(
            texto: _nombreSeccion(seccion),
            icono: _iconoSeccion(seccion),
            activo: activa,
            colores: _coloresSeccion(seccion),
            onTap: () {
              _actualizarEstado(() {
                _modoPreparacion = false;
                _seccionActiva = seccion;
                _abrirCategoriasSeccion(seccion);
              });
            },
          );
        }),
        _botonSeccion(
          texto: 'Pedidos',
          icono: Icons.restaurant_menu_rounded,
          activo: _modoPreparacion,
          colores: const [Color(0xFFFFD166), ColoresApp.principal],
          contador: _pedidosPreparacion.length + _pedidosNoEnviados.length,
          onTap: () {
            _actualizarEstado(() {
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: activo ? LinearGradient(colors: colores) : null,
          color: activo ? null : ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activo ? Colors.transparent : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 18,
              color: activo ? Colors.black : ColoresApp.textoPrincipal,
            ),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.black : ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (contador > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: activo ? Colors.black : ColoresApp.principal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$contador',
                  style: TextStyle(
                    color: activo ? ColoresApp.principal : Colors.black,
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
        icon: const Icon(Icons.refresh_rounded, color: ColoresApp.principal),
        label: const Text(
          'Actualizar pedidos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColoresApp.textoPrincipal,
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _campoBusqueda() {
    return TextField(
      onChanged: (valor) {
        _actualizarEstado(() {
          _busqueda = valor;

          if (valor.trim().isNotEmpty) {
            _categoriasAbiertas.addAll(
              _productosFiltrados.map(
                (producto) => _normalizarCategoria(producto.categoria),
              ),
            );
          }
        });
      },
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        hintText:
            'Buscar en ${_nombreSeccion(_seccionActiva).toLowerCase()}...',
        hintStyle: const TextStyle(color: ColoresApp.textoSecundario),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: _colorSuaveSeccion(_seccionActiva),
        ),
        filled: true,
        fillColor: ColoresApp.fondoSecundario,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
