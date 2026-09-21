part of '../../paginas/pagina_ventas.dart';

extension _PaginaVentasPedidoActual on _PaginaVentasState {
  Widget _panelPedido({required bool alturaFija, required bool esCelular}) {
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
            style: const TextStyle(color: ColoresApp.textoSecundario),
          ),
          const SizedBox(height: 18),
          if (alturaFija)
            Expanded(child: _listaPedido(esCelular))
          else
            _listaPedido(esCelular),
          const SizedBox(height: 16),
          _totalesPedido(),
          const SizedBox(height: 16),
          _botonesPedido(esCelular),
        ],
      ),
    );
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
          style: TextStyle(color: ColoresApp.textoSecundario),
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
              item.producto.esCombo && item.eleccionesCombo.isNotEmpty
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _filaTotal('Subtotal', _subtotal),
          const SizedBox(height: 10),
          _filaTotal('Total inicial', _subtotal, resaltar: true),
          const SizedBox(height: 8),
          const Text(
            'Delivery y plataforma se configuran al finalizar el pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _botonesPedido(bool esCelular) {
    final limpiar = OutlinedButton(
      onPressed: _guardandoVenta ? null : _limpiarPedido,
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        'Limpiar',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    final finalizar = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: _coloresSeccion(_seccionActiva)),
      ),
      child: ElevatedButton(
        onPressed: _guardandoVenta ? null : _finalizarPedido,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                'Finalizar pedido',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
      ),
    );

    if (esCelular) {
      return Column(
        children: [
          SizedBox(width: double.infinity, height: 52, child: finalizar),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 48, child: limpiar),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: SizedBox(height: 52, child: limpiar)),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 52, child: finalizar)),
      ],
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
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: resaltar
                ? _colorSuaveSeccion(_seccionActiva)
                : ColoresApp.textoPrincipal,
            fontSize: resaltar ? 22 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
