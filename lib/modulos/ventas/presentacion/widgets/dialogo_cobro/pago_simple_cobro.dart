part of '../dialogo_cobro.dart';

extension _DialogoCobroPagoSimple on _DialogoCobroState {
  Widget _selectorTipoCobro() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _botonTipoCobro(
              texto: 'Pago único',
              activo: !_dividirPorComensales,
              onTap: () {
                _actualizarEstado(() {
                  _dividirPorComensales = false;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _botonTipoCobro(
              texto: 'Por comensales',
              activo: _dividirPorComensales,
              onTap: () {
                _actualizarEstado(() {
                  _dividirPorComensales = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonTipoCobro({
    required String texto,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: activo ? ColoresApp.principal : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: activo ? Colors.black : ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _contenidoPagoSimple() {
    return _bloque(
      titulo: 'Método de pago',
      icono: Icons.payments_rounded,
      child: Column(
        children: [
          ...MetodoPago.values.map(
            (metodo) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _opcionMetodo(
                metodo: metodo,
                activo: _metodoPagoSimple == metodo,
                onTap: () {
                  _seleccionarMetodoSimple(metodo);
                },
              ),
            ),
          ),
          if (_metodoPagoSimple == MetodoPago.efectivo) ...[
            const SizedBox(height: 4),
            _campoDinero(
              controller: _valorRecibidoSimpleController,
              label: 'Cliente paga con',
              error: _efectivoSimpleInsuficiente,
              onChanged: (_) {
                _actualizarEstado(() {});
              },
            ),
            const SizedBox(height: 12),
            _resumenEfectivoSimple(),
          ],
          if (_metodoPagoSimple == MetodoPago.transferencia) ...[
            const SizedBox(height: 4),
            _campoTexto(controller: _bancoSimpleController, label: 'Banco'),
          ],
          if (_metodoPagoSimple == MetodoPago.tarjeta) ...[
            const SizedBox(height: 4),
            _selectorDatofono(
              valor: _datofonoSimple,
              onChanged: (valor) {
                _actualizarEstado(() {
                  _datofonoSimple = valor ?? 'Bendo';
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
