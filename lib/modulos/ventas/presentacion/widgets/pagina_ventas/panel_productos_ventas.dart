part of '../../paginas/pagina_ventas.dart';

extension _PaginaVentasPanelProductos on _PaginaVentasState {
  Widget _panelProductos({
    required List<ProductoVenta> productos,
    required bool alturaFija,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 16 : 18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: alturaFija ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            _modoPreparacion ? 'Pedidos' : 'Productos',
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
                  ? _listaGestionPedidos(esCelular)
                  : _listaProductos(productos, esCelular),
            )
          else if (_modoPreparacion)
            _listaGestionPedidos(esCelular)
          else
            _listaProductos(productos, esCelular),
        ],
      ),
    );
  }
}
