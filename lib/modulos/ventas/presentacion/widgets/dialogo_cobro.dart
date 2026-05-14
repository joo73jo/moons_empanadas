import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';

enum MetodoPago {
  efectivo,
  transferencia,
  tarjeta,
}

class PagoCobro {
  final MetodoPago metodoPago;
  final double monto;
  final String? banco;
  final String? datofono;
  final double? valorRecibido;
  final double cambio;

  const PagoCobro({
    required this.metodoPago,
    required this.monto,
    this.banco,
    this.datofono,
    this.valorRecibido,
    this.cambio = 0,
  });
}

class ResultadoCobro {
  final MetodoPago metodoPago;
  final String? banco;
  final String? datofono;
  final double total;
  final double? valorRecibido;
  final double cambio;
  final List<PagoCobro> pagos;

  const ResultadoCobro({
    required this.metodoPago,
    required this.total,
    required this.cambio,
    required this.pagos,
    this.valorRecibido,
    this.banco,
    this.datofono,
  });

  bool get esPagoMixto => pagos.length > 1;

  double get totalPagado {
    double totalPagos = 0;
    for (final pago in pagos) {
      totalPagos += pago.monto;
    }
    return totalPagos;
  }
}

class DialogoCobro extends StatefulWidget {
  final double total;

  const DialogoCobro({
    super.key,
    required this.total,
  });

  @override
  State<DialogoCobro> createState() => _DialogoCobroState();
}

class _DialogoCobroState extends State<DialogoCobro> {
  bool _pagoDividido = false;
  MetodoPago _metodoPago = MetodoPago.efectivo;

  final TextEditingController _bancoController = TextEditingController();
  final TextEditingController _valorRecibidoController =
      TextEditingController();

  final TextEditingController _montoEfectivoController =
      TextEditingController();
  final TextEditingController _recibidoEfectivoMixtoController =
      TextEditingController();

  final TextEditingController _montoTransferenciaController =
      TextEditingController();
  final TextEditingController _bancoMixtoController = TextEditingController();

  final TextEditingController _montoTarjetaController = TextEditingController();

  String? _datofonoSeleccionado = 'Bendo';
  String? _datofonoMixtoSeleccionado = 'Bendo';

  @override
  void initState() {
    super.initState();
    _valorRecibidoController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _bancoController.dispose();
    _valorRecibidoController.dispose();
    _montoEfectivoController.dispose();
    _recibidoEfectivoMixtoController.dispose();
    _montoTransferenciaController.dispose();
    _bancoMixtoController.dispose();
    _montoTarjetaController.dispose();
    super.dispose();
  }

  String _nombreMetodo(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
    }
  }

  IconData _iconoMetodo(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return Icons.payments_rounded;
      case MetodoPago.transferencia:
        return Icons.account_balance_rounded;
      case MetodoPago.tarjeta:
        return Icons.credit_card_rounded;
    }
  }

  double _leerMonto(TextEditingController controller) {
    final texto = controller.text.trim().replaceAll(',', '.');
    return double.tryParse(texto) ?? 0;
  }

  double get _valorRecibido {
    return _leerMonto(_valorRecibidoController);
  }

  double get _cambioSimple {
    if (_metodoPago != MetodoPago.efectivo) return 0;
    final cambio = _valorRecibido - widget.total;
    return cambio < 0 ? 0 : cambio;
  }

  bool get _efectivoSimpleInsuficiente {
    return _metodoPago == MetodoPago.efectivo &&
        _valorRecibido < widget.total;
  }

  double get _montoEfectivoMixto => _leerMonto(_montoEfectivoController);
  double get _recibidoEfectivoMixto =>
      _leerMonto(_recibidoEfectivoMixtoController);
  double get _montoTransferencia => _leerMonto(_montoTransferenciaController);
  double get _montoTarjeta => _leerMonto(_montoTarjetaController);

  double get _totalDividido {
    return _montoEfectivoMixto + _montoTransferencia + _montoTarjeta;
  }

  double get _faltanteDividido {
    final faltante = widget.total - _totalDividido;
    return faltante < 0 ? 0 : faltante;
  }

  double get _excedenteDividido {
    final excedente = _totalDividido - widget.total;
    return excedente < 0 ? 0 : excedente;
  }

  double get _cambioMixto {
    if (_montoEfectivoMixto <= 0) return 0;
    final cambio = _recibidoEfectivoMixto - _montoEfectivoMixto;
    return cambio < 0 ? 0 : cambio;
  }

  bool get _efectivoMixtoInsuficiente {
    return _montoEfectivoMixto > 0 &&
        _recibidoEfectivoMixto < _montoEfectivoMixto;
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

  void _confirmarSimple() {
    if (_metodoPago == MetodoPago.efectivo) {
      if (_valorRecibidoController.text.trim().isEmpty) {
        _mostrarMensaje('Ingresa cuánto entregó el cliente.');
        return;
      }

      if (_valorRecibido < widget.total) {
        _mostrarMensaje(
          'El valor recibido no puede ser menor al total a cobrar.',
        );
        return;
      }
    }

    if (_metodoPago == MetodoPago.transferencia &&
        _bancoController.text.trim().isEmpty) {
      _mostrarMensaje('Ingresa el banco de la transferencia.');
      return;
    }

    final pago = PagoCobro(
      metodoPago: _metodoPago,
      monto: widget.total,
      valorRecibido:
          _metodoPago == MetodoPago.efectivo ? _valorRecibido : null,
      cambio: _metodoPago == MetodoPago.efectivo ? _cambioSimple : 0,
      banco: _metodoPago == MetodoPago.transferencia
          ? _bancoController.text.trim()
          : null,
      datofono:
          _metodoPago == MetodoPago.tarjeta ? _datofonoSeleccionado : null,
    );

    Navigator.pop(
      context,
      ResultadoCobro(
        metodoPago: _metodoPago,
        total: widget.total,
        valorRecibido:
            _metodoPago == MetodoPago.efectivo ? _valorRecibido : null,
        cambio: _metodoPago == MetodoPago.efectivo ? _cambioSimple : 0,
        banco: _metodoPago == MetodoPago.transferencia
            ? _bancoController.text.trim()
            : null,
        datofono:
            _metodoPago == MetodoPago.tarjeta ? _datofonoSeleccionado : null,
        pagos: [pago],
      ),
    );
  }

  void _confirmarDividido() {
    final pagos = <PagoCobro>[];

    if (_montoEfectivoMixto > 0) {
      if (_recibidoEfectivoMixtoController.text.trim().isEmpty) {
        _mostrarMensaje('Ingresa cuánto recibió en efectivo.');
        return;
      }

      if (_recibidoEfectivoMixto < _montoEfectivoMixto) {
        _mostrarMensaje(
          'El efectivo recibido no puede ser menor al monto en efectivo.',
        );
        return;
      }

      pagos.add(
        PagoCobro(
          metodoPago: MetodoPago.efectivo,
          monto: _montoEfectivoMixto,
          valorRecibido: _recibidoEfectivoMixto,
          cambio: _cambioMixto,
        ),
      );
    }

    if (_montoTransferencia > 0) {
      if (_bancoMixtoController.text.trim().isEmpty) {
        _mostrarMensaje('Ingresa el banco de la transferencia.');
        return;
      }

      pagos.add(
        PagoCobro(
          metodoPago: MetodoPago.transferencia,
          monto: _montoTransferencia,
          banco: _bancoMixtoController.text.trim(),
        ),
      );
    }

    if (_montoTarjeta > 0) {
      pagos.add(
        PagoCobro(
          metodoPago: MetodoPago.tarjeta,
          monto: _montoTarjeta,
          datofono: _datofonoMixtoSeleccionado,
        ),
      );
    }

    if (pagos.isEmpty) {
      _mostrarMensaje('Ingresa al menos una forma de pago.');
      return;
    }

    if ((_totalDividido - widget.total).abs() > 0.01) {
      if (_totalDividido < widget.total) {
        _mostrarMensaje(
          'Falta por cobrar \$${_faltanteDividido.toStringAsFixed(2)}.',
        );
      } else {
        _mostrarMensaje(
          'Los pagos superan el total por \$${_excedenteDividido.toStringAsFixed(2)}.',
        );
      }
      return;
    }

    if (pagos.length == 1) {
      final pago = pagos.first;

      Navigator.pop(
        context,
        ResultadoCobro(
          metodoPago: pago.metodoPago,
          total: widget.total,
          valorRecibido: pago.valorRecibido,
          cambio: pago.cambio,
          banco: pago.banco,
          datofono: pago.datofono,
          pagos: pagos,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ResultadoCobro(
        metodoPago: pagos.first.metodoPago,
        total: widget.total,
        valorRecibido: _montoEfectivoMixto > 0 ? _recibidoEfectivoMixto : null,
        cambio: _montoEfectivoMixto > 0 ? _cambioMixto : 0,
        pagos: pagos,
      ),
    );
  }

  void _confirmar() {
    if (_pagoDividido) {
      _confirmarDividido();
    } else {
      _confirmarSimple();
    }
  }

  void _seleccionarMetodo(MetodoPago metodo) {
    setState(() {
      _metodoPago = metodo;

      if (metodo == MetodoPago.efectivo &&
          _valorRecibidoController.text.trim().isEmpty) {
        _valorRecibidoController.text = widget.total.toStringAsFixed(2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cambioSimple = _cambioSimple;
    final insuficienteSimple = _efectivoSimpleInsuficiente;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ColoresApp.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cobrar pedido',
                      style: TextStyle(
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
              _tarjetaTotal(),
              const SizedBox(height: 16),
              _selectorTipoCobro(),
              const SizedBox(height: 16),
              if (!_pagoDividido)
                _contenidoCobroSimple(
                  cambioSimple,
                  insuficienteSimple,
                )
              else
                _contenidoCobroDividido(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColoresApp.textoPrincipal,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColoresApp.principal,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Confirmar cobro',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaTotal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Total a cobrar',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${widget.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: ColoresApp.principal,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

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
              activo: !_pagoDividido,
              onTap: () {
                setState(() {
                  _pagoDividido = false;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _botonTipoCobro(
              texto: 'Dividir pago',
              activo: _pagoDividido,
              onTap: () {
                setState(() {
                  _pagoDividido = true;
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _contenidoCobroSimple(
    double cambioSimple,
    bool insuficienteSimple,
  ) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Método de pago',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: MetodoPago.values.map((metodo) {
            final activo = _metodoPago == metodo;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _seleccionarMetodo(metodo),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: activo
                        ? ColoresApp.principal.withOpacity(0.14)
                        : ColoresApp.fondoSecundario,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: activo
                          ? ColoresApp.principal
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconoMetodo(metodo),
                        color: activo
                            ? ColoresApp.principal
                            : ColoresApp.textoSecundario,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _nombreMetodo(metodo),
                        style: TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontWeight:
                              activo ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_metodoPago == MetodoPago.efectivo) ...[
          const SizedBox(height: 8),
          _campoDinero(
            controller: _valorRecibidoController,
            label: 'Cliente paga con',
            onChanged: (_) => setState(() {}),
            error: insuficienteSimple,
          ),
          const SizedBox(height: 12),
          _resumenCambioSimple(
            insuficienteSimple: insuficienteSimple,
            cambioSimple: cambioSimple,
          ),
        ],
        if (_metodoPago == MetodoPago.transferencia) ...[
          const SizedBox(height: 8),
          _campoTexto(
            controller: _bancoController,
            label: 'Banco',
          ),
        ],
        if (_metodoPago == MetodoPago.tarjeta) ...[
          const SizedBox(height: 8),
          _selectorDatofono(
            value: _datofonoSeleccionado,
            onChanged: (value) {
              setState(() {
                _datofonoSeleccionado = value;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _contenidoCobroDividido() {
    final faltante = _faltanteDividido;
    final excedente = _excedenteDividido;
    final completo = (_totalDividido - widget.total).abs() <= 0.01;
    final colorEstado = completo
        ? ColoresApp.exito
        : excedente > 0
            ? ColoresApp.error
            : ColoresApp.principal;

    return Column(
      children: [
        _bloquePagoDividido(
          titulo: 'Efectivo',
          icono: Icons.payments_rounded,
          children: [
            _campoDinero(
              controller: _montoEfectivoController,
              label: 'Monto en efectivo',
              onChanged: (value) {
                setState(() {
                  if (_recibidoEfectivoMixtoController.text.trim().isEmpty) {
                    _recibidoEfectivoMixtoController.text = value;
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            _campoDinero(
              controller: _recibidoEfectivoMixtoController,
              label: 'Cliente entrega en efectivo',
              onChanged: (_) => setState(() {}),
              error: _efectivoMixtoInsuficiente,
            ),
            const SizedBox(height: 10),
            _miniResumen(
              titulo: _efectivoMixtoInsuficiente
                  ? 'Falta efectivo'
                  : 'Vuelto efectivo',
              valor: _efectivoMixtoInsuficiente
                  ? '\$${(_montoEfectivoMixto - _recibidoEfectivoMixto).toStringAsFixed(2)}'
                  : '\$${_cambioMixto.toStringAsFixed(2)}',
              color:
                  _efectivoMixtoInsuficiente ? ColoresApp.error : ColoresApp.principal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _bloquePagoDividido(
          titulo: 'Transferencia',
          icono: Icons.account_balance_rounded,
          children: [
            _campoDinero(
              controller: _montoTransferenciaController,
              label: 'Monto por transferencia',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _campoTexto(
              controller: _bancoMixtoController,
              label: 'Banco',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _bloquePagoDividido(
          titulo: 'Tarjeta',
          icono: Icons.credit_card_rounded,
          children: [
            _campoDinero(
              controller: _montoTarjetaController,
              label: 'Monto por tarjeta',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _selectorDatofono(
              value: _datofonoMixtoSeleccionado,
              onChanged: (value) {
                setState(() {
                  _datofonoMixtoSeleccionado = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSecundario,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorEstado.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              _filaResumenDividido(
                'Total a cobrar',
                '\$${widget.total.toStringAsFixed(2)}',
                ColoresApp.textoPrincipal,
              ),
              const SizedBox(height: 8),
              _filaResumenDividido(
                'Total ingresado',
                '\$${_totalDividido.toStringAsFixed(2)}',
                colorEstado,
              ),
              const SizedBox(height: 8),
              if (completo)
                _filaResumenDividido(
                  'Estado',
                  'Completo',
                  ColoresApp.exito,
                )
              else if (excedente > 0)
                _filaResumenDividido(
                  'Excedente',
                  '\$${excedente.toStringAsFixed(2)}',
                  ColoresApp.error,
                )
              else
                _filaResumenDividido(
                  'Falta por cobrar',
                  '\$${faltante.toStringAsFixed(2)}',
                  ColoresApp.principal,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bloquePagoDividido({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icono, color: ColoresApp.principal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _campoDinero({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    bool error = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        prefixStyle: const TextStyle(
          color: ColoresApp.principal,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: error ? ColoresApp.error : Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: error ? ColoresApp.error : ColoresApp.principal,
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _selectorDatofono({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        labelText: 'Datáfono',
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Bendo',
          child: Text('Bendo'),
        ),
        DropdownMenuItem(
          value: 'Ya Ganaste',
          child: Text('Ya Ganaste'),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _resumenCambioSimple({
    required bool insuficienteSimple,
    required double cambioSimple,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insuficienteSimple
            ? ColoresApp.error.withOpacity(0.12)
            : ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: insuficienteSimple
              ? ColoresApp.error.withOpacity(0.4)
              : ColoresApp.principal.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            insuficienteSimple
                ? Icons.warning_amber_rounded
                : Icons.payments_rounded,
            color: insuficienteSimple ? ColoresApp.error : ColoresApp.principal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insuficienteSimple ? 'Falta por pagar' : 'Vuelto a entregar',
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            insuficienteSimple
                ? '\$${(widget.total - _valorRecibido).toStringAsFixed(2)}'
                : '\$${cambioSimple.toStringAsFixed(2)}',
            style: TextStyle(
              color: insuficienteSimple ? ColoresApp.error : ColoresApp.principal,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniResumen({
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaResumenDividido(String titulo, String valor, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}