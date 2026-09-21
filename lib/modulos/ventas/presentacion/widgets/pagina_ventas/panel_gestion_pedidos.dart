part of '../../paginas/pagina_ventas.dart';

extension _PaginaVentasGestionPedidos on _PaginaVentasState {
  Widget _listaGestionPedidos(bool esCelular) {
    if (_cargandoPreparacion) {
      return const Center(
        child: CircularProgressIndicator(color: ColoresApp.principal),
      );
    }

    if (_pedidosPreparacion.isEmpty && _pedidosNoEnviados.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColoresApp.fondoSecundario,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'No hay pedidos pendientes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ColoresApp.textoSecundario),
        ),
      );
    }

    final contenido = <Widget>[];

    if (_pedidosNoEnviados.isNotEmpty) {
      contenido.add(
        _tituloGrupo('Pendientes de enviar', _pedidosNoEnviados.length),
      );

      for (final pedido in _pedidosNoEnviados) {
        contenido.add(const SizedBox(height: 12));

        contenido.add(_tarjetaPedidoGestion(pedido, enviado: false));
      }
    }

    if (_pedidosPreparacion.isNotEmpty) {
      if (contenido.isNotEmpty) {
        contenido.add(const SizedBox(height: 22));
      }

      contenido.add(
        _tituloGrupo('Preparación y cobro', _pedidosPreparacion.length),
      );

      for (final pedido in _pedidosPreparacion) {
        contenido.add(const SizedBox(height: 12));

        contenido.add(_tarjetaPedidoGestion(pedido, enviado: true));
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

  Widget _tituloGrupo(String titulo, int cantidad) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ColoresApp.principal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.principal.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColoresApp.principal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.nombrePedido,
                      style: const TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${nombreTipoPedido(pedido.tipoPedido)} • ${_formatearHora(pedido.fecha)}',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _etiquetaEstadoCobro(pedido.estadoCobro),
            ],
          ),
          if (pedido.barrio.isNotEmpty) ...[
            const SizedBox(height: 12),
            _datoPedido(Icons.location_on_rounded, 'Barrio: ${pedido.barrio}'),
          ],
          if (pedido.responsableDinero.isNotEmpty) ...[
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
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${detalle.cantidad} x ${detalle.nombreProducto}',
                    style: const TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (detalle.descripcionesConfiguracion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...detalle.descripcionesConfiguracion.map(
                      (descripcion) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $descripcion',
                          style: const TextStyle(
                            color: ColoresApp.principal,
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
          _filaResumenPedido('Consumo', pedido.subtotal),
          if (pedido.totalRecargos > 0) ...[
            const SizedBox(height: 6),
            _filaResumenPedido('Recargos', pedido.totalRecargos),
          ],
          const SizedBox(height: 6),
          _filaResumenPedido('Total', pedido.total, resaltar: true),
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
                    _cobrarPedidoPendiente(pedido);
                  },
                ),
              if (!enviado)
                _botonAccionPedido(
                  texto: 'Enviar a preparación',
                  icono: Icons.restaurant_menu_rounded,
                  onPressed: () {
                    _enviarPedidoPreparacion(pedido);
                  },
                ),
              if (enviado && pedido.estadoPreparacion != 'listo')
                _botonAccionPedido(
                  texto: 'Marcar listo',
                  icono: Icons.check_circle_rounded,
                  onPressed: () {
                    _marcarPedidoListo(pedido);
                  },
                ),
              if (pedido.dineroConRepartidor)
                _botonAccionPedido(
                  texto: 'Dinero entregado',
                  icono: Icons.account_balance_wallet_rounded,
                  onPressed: () {
                    _marcarDineroEntregado(pedido);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datoPedido(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 18, color: ColoresApp.principal),
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

  Widget _etiquetaEstadoCobro(EstadoCobroVenta estado) {
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
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
      icon: Icon(icono, size: 18),
      label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w900)),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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
              fontWeight: resaltar ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
            fontSize: resaltar ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
