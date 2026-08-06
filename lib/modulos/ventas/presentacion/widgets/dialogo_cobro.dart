import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

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
  final DatosPedidoVenta? datosPedido;
  final bool cobroRealizado;

  const ResultadoCobro({
    required this.metodoPago,
    required this.total,
    required this.cambio,
    required this.pagos,
    this.valorRecibido,
    this.banco,
    this.datofono,
    this.datosPedido,
    this.cobroRealizado = true,
  });

  bool get esPagoMixto {
    if (pagos.length <= 1) {
      return false;
    }

    return pagos
            .map((pago) => pago.metodoPago)
            .toSet()
            .length >
        1;
  }

  double get totalPagado {
    return pagos.fold(
      0,
      (total, pago) => total + pago.monto,
    );
  }
}

class _PagoComensal {
  MetodoPago metodoPago;
  String datofono;

  final TextEditingController montoController;
  final TextEditingController bancoController;
  final TextEditingController recibidoController;

  _PagoComensal({
    this.metodoPago = MetodoPago.efectivo,
    this.datofono = 'Bendo',
    String montoInicial = '',
  })  : montoController = TextEditingController(
          text: montoInicial,
        ),
        bancoController = TextEditingController(),
        recibidoController = TextEditingController(
          text: montoInicial,
        );

  double get monto {
    return _leerNumero(montoController.text);
  }

  double get recibido {
    return _leerNumero(recibidoController.text);
  }

  double get cambio {
    if (metodoPago != MetodoPago.efectivo) {
      return 0;
    }

    final resultado = recibido - monto;

    return resultado > 0 ? resultado : 0;
  }

  bool get efectivoInsuficiente {
    return metodoPago == MetodoPago.efectivo &&
        monto > 0 &&
        recibido < monto;
  }

  static double _leerNumero(String texto) {
    return double.tryParse(
          texto.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  void dispose() {
    montoController.dispose();
    bancoController.dispose();
    recibidoController.dispose();
  }
}

class DialogoCobro extends StatefulWidget {
  final double subtotal;

  // Se conserva para no romper las llamadas existentes desde pagina_ventas.
  // El recargo ya no depende de esta lista.
  final List<RecargoConfiguracion> recargosDisponibles;

  /// Cuando es true, el pedido ya existe y únicamente se cobra.
  final bool soloCobro;

  final String? nombrePedido;

  const DialogoCobro({
    super.key,
    double? subtotal,
    double? total,
    this.recargosDisponibles = const [],
    this.soloCobro = false,
    this.nombrePedido,
  }) : subtotal = subtotal ?? total ?? 0;

  @override
  State<DialogoCobro> createState() =>
      _DialogoCobroState();
}

class _DialogoCobroState extends State<DialogoCobro> {
  final TextEditingController _nombrePedidoController =
      TextEditingController();

  final TextEditingController _barrioController =
      TextEditingController();

  final TextEditingController _responsableDineroController =
      TextEditingController();

  final TextEditingController _porcentajeRecargoController =
      TextEditingController();

  final TextEditingController _bancoSimpleController =
      TextEditingController();

  final TextEditingController _valorRecibidoSimpleController =
      TextEditingController();

  final List<_PagoComensal> _comensales = [];

  TipoPedido _tipoPedido = TipoPedido.local;

  EstadoCobroVenta _estadoCobro =
      EstadoCobroVenta.pagado;

  MetodoPago _metodoPagoSimple =
      MetodoPago.efectivo;

  bool _dividirPorComensales = false;

  String _datofonoSimple = 'Bendo';

  @override
  void initState() {
    super.initState();

    final nombre = widget.nombrePedido?.trim() ?? '';

    if (nombre.isNotEmpty) {
      _nombrePedidoController.text = nombre;
    }

    final totalInicial =
        widget.subtotal.toStringAsFixed(2);

    _valorRecibidoSimpleController.text =
        totalInicial;

    _comensales.add(
      _PagoComensal(
        montoInicial: totalInicial,
      ),
    );
  }

  @override
  void dispose() {
    _nombrePedidoController.dispose();
    _barrioController.dispose();
    _responsableDineroController.dispose();
    _porcentajeRecargoController.dispose();
    _bancoSimpleController.dispose();
    _valorRecibidoSimpleController.dispose();

    for (final comensal in _comensales) {
      comensal.dispose();
    }

    super.dispose();
  }

  double _leerNumero(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text
              .trim()
              .replaceAll(',', '.'),
        ) ??
        0;
  }

  double get _porcentajeRecargo {
    final porcentaje =
        _leerNumero(_porcentajeRecargoController);

    if (porcentaje < 0) {
      return 0;
    }

    if (porcentaje > 100) {
      return 100;
    }

    return porcentaje;
  }

  double get _valorRecargo {
    return widget.subtotal *
        _porcentajeRecargo /
        100;
  }

  List<RecargoAplicado> get _recargosAplicados {
    if (widget.soloCobro ||
        _porcentajeRecargo <= 0) {
      return const [];
    }

    return [
      RecargoAplicado(
        configuracionId: null,
        nombre: 'Recargo',
        porcentaje: _porcentajeRecargo,
        valor: _valorRecargo,
      ),
    ];
  }

  double get _totalRecargos {
    return _recargosAplicados.fold(
      0,
      (total, recargo) => total + recargo.valor,
    );
  }

  double get _totalFinal {
    return widget.subtotal + _totalRecargos;
  }

  bool get _requiereCobroAhora {
    if (widget.soloCobro) {
      return true;
    }

    return _estadoCobro ==
        EstadoCobroVenta.pagado;
  }

  double get _valorRecibidoSimple {
    return _leerNumero(
      _valorRecibidoSimpleController,
    );
  }

  double get _cambioSimple {
    if (_metodoPagoSimple !=
        MetodoPago.efectivo) {
      return 0;
    }

    final cambio =
        _valorRecibidoSimple - _totalFinal;

    return cambio > 0 ? cambio : 0;
  }

  bool get _efectivoSimpleInsuficiente {
    return _metodoPagoSimple ==
            MetodoPago.efectivo &&
        _valorRecibidoSimple < _totalFinal;
  }

  double get _totalComensales {
    return _comensales.fold(
      0,
      (total, comensal) =>
          total + comensal.monto,
    );
  }

  double get _restanteComensales {
    final restante =
        _totalFinal - _totalComensales;

    return restante > 0 ? restante : 0;
  }

  double get _excedenteComensales {
    final excedente =
        _totalComensales - _totalFinal;

    return excedente > 0 ? excedente : 0;
  }

  bool get _cuentaCompleta {
    return (_totalComensales - _totalFinal)
            .abs() <=
        0.01;
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

  String _nombreEstadoCobro(
    EstadoCobroVenta estado,
  ) {
    switch (estado) {
      case EstadoCobroVenta.pagado:
        return 'Cobrar ahora';

      case EstadoCobroVenta.pendientePago:
        return 'Pagar después de consumir';

      case EstadoCobroVenta.cobradoRepartidor:
        return 'Dinero con repartidor';

      case EstadoCobroVenta.entregado:
        return 'Dinero entregado';
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

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

  void _actualizarMontosAlCambiarTotal() {
    final total =
        _totalFinal.toStringAsFixed(2);

    _valorRecibidoSimpleController.text =
        total;

    if (_comensales.length == 1) {
      final comensal = _comensales.first;

      comensal.montoController.text = total;

      if (comensal.metodoPago ==
          MetodoPago.efectivo) {
        comensal.recibidoController.text =
            total;
      }
    }
  }

  void _seleccionarMetodoSimple(
    MetodoPago metodo,
  ) {
    setState(() {
      _metodoPagoSimple = metodo;

      if (metodo == MetodoPago.efectivo &&
          _valorRecibidoSimpleController.text
              .trim()
              .isEmpty) {
        _valorRecibidoSimpleController.text =
            _totalFinal.toStringAsFixed(2);
      }
    });
  }

  void _agregarComensal() {
    setState(() {
      final restante =
          _restanteComensales;

      _comensales.add(
        _PagoComensal(
          montoInicial: restante > 0
              ? restante.toStringAsFixed(2)
              : '',
        ),
      );
    });
  }

  void _eliminarComensal(int index) {
    if (_comensales.length <= 1) {
      _mostrarMensaje(
        'Debe existir al menos un comensal.',
      );

      return;
    }

    final comensal = _comensales[index];

    setState(() {
      _comensales.removeAt(index);
    });

    comensal.dispose();
  }

  void _usarRestante(int index) {
    double sumaOtros = 0;

    for (int i = 0;
        i < _comensales.length;
        i++) {
      if (i != index) {
        sumaOtros += _comensales[i].monto;
      }
    }

    final restante =
        _totalFinal - sumaOtros;

    final monto =
        restante > 0 ? restante : 0;

    setState(() {
      final comensal = _comensales[index];

      comensal.montoController.text =
          monto.toStringAsFixed(2);

      if (comensal.metodoPago ==
          MetodoPago.efectivo) {
        comensal.recibidoController.text =
            monto.toStringAsFixed(2);
      }
    });
  }

  DatosPedidoVenta? _crearDatosPedido() {
    if (widget.soloCobro) {
      return null;
    }

    final nombrePedido =
        _nombrePedidoController.text.trim();

    if (nombrePedido.isEmpty) {
      _mostrarMensaje(
        'Ingresa el nombre del pedido.',
      );

      return null;
    }

    final barrio =
        _barrioController.text.trim();

    if (_tipoPedido ==
            TipoPedido.domicilio &&
        barrio.isEmpty) {
      _mostrarMensaje(
        'Ingresa el barrio del domicilio.',
      );

      return null;
    }

    final responsable =
        _responsableDineroController.text
            .trim();

    if (_estadoCobro ==
            EstadoCobroVenta
                .cobradoRepartidor &&
        responsable.isEmpty) {
      _mostrarMensaje(
        'Indica quién tiene el dinero.',
      );

      return null;
    }

    return DatosPedidoVenta(
      nombrePedido: nombrePedido,
      tipoPedido: _tipoPedido,
      barrio: barrio,
      estadoCobro: _estadoCobro,
      responsableDinero: responsable,

      // Todo pedido entra obligatoriamente
      // a preparación.
      enviarPreparacion: true,

      recargos: _recargosAplicados,
    );
  }

  ResultadoCobro? _crearPagoSimple(
    DatosPedidoVenta? datosPedido,
  ) {
    if (_metodoPagoSimple ==
        MetodoPago.efectivo) {
      if (_valorRecibidoSimpleController.text
          .trim()
          .isEmpty) {
        _mostrarMensaje(
          'Ingresa cuánto entregó el cliente.',
        );

        return null;
      }

      if (_efectivoSimpleInsuficiente) {
        _mostrarMensaje(
          'El valor recibido no puede ser menor al total.',
        );

        return null;
      }
    }

    if (_metodoPagoSimple ==
            MetodoPago.transferencia &&
        _bancoSimpleController.text
            .trim()
            .isEmpty) {
      _mostrarMensaje(
        'Ingresa el banco de la transferencia.',
      );

      return null;
    }

    final pago = PagoCobro(
      metodoPago: _metodoPagoSimple,
      monto: _totalFinal,
      banco: _metodoPagoSimple ==
              MetodoPago.transferencia
          ? _bancoSimpleController.text.trim()
          : null,
      datofono: _metodoPagoSimple ==
              MetodoPago.tarjeta
          ? _datofonoSimple
          : null,
      valorRecibido: _metodoPagoSimple ==
              MetodoPago.efectivo
          ? _valorRecibidoSimple
          : null,
      cambio: _metodoPagoSimple ==
              MetodoPago.efectivo
          ? _cambioSimple
          : 0,
    );

    return ResultadoCobro(
      metodoPago: pago.metodoPago,
      total: _totalFinal,
      banco: pago.banco,
      datofono: pago.datofono,
      valorRecibido: pago.valorRecibido,
      cambio: pago.cambio,
      pagos: [pago],
      datosPedido: datosPedido,
      cobroRealizado: true,
    );
  }

  ResultadoCobro? _crearPagoComensales(
    DatosPedidoVenta? datosPedido,
  ) {
    final pagos = <PagoCobro>[];

    for (int i = 0;
        i < _comensales.length;
        i++) {
      final comensal = _comensales[i];

      final numero = i + 1;

      if (comensal.monto <= 0) {
        _mostrarMensaje(
          'Ingresa el monto del comensal $numero.',
        );

        return null;
      }

      if (comensal.metodoPago ==
          MetodoPago.efectivo) {
        if (comensal
            .recibidoController.text
            .trim()
            .isEmpty) {
          _mostrarMensaje(
            'Ingresa cuánto entrega el comensal $numero.',
          );

          return null;
        }

        if (comensal.efectivoInsuficiente) {
          _mostrarMensaje(
            'El efectivo del comensal $numero es insuficiente.',
          );

          return null;
        }
      }

      if (comensal.metodoPago ==
              MetodoPago.transferencia &&
          comensal.bancoController.text
              .trim()
              .isEmpty) {
        _mostrarMensaje(
          'Ingresa el banco del comensal $numero.',
        );

        return null;
      }

      pagos.add(
        PagoCobro(
          metodoPago: comensal.metodoPago,
          monto: comensal.monto,
          banco: comensal.metodoPago ==
                  MetodoPago.transferencia
              ? comensal.bancoController.text
                  .trim()
              : null,
          datofono: comensal.metodoPago ==
                  MetodoPago.tarjeta
              ? comensal.datofono
              : null,
          valorRecibido:
              comensal.metodoPago ==
                      MetodoPago.efectivo
                  ? comensal.recibido
                  : null,
          cambio: comensal.metodoPago ==
                  MetodoPago.efectivo
              ? comensal.cambio
              : 0,
        ),
      );
    }

    if (!_cuentaCompleta) {
      if (_totalComensales < _totalFinal) {
        _mostrarMensaje(
          'Falta por cobrar \$${_restanteComensales.toStringAsFixed(2)}.',
        );
      } else {
        _mostrarMensaje(
          'Los pagos superan el total por \$${_excedenteComensales.toStringAsFixed(2)}.',
        );
      }

      return null;
    }

    final primerPago = pagos.first;

    return ResultadoCobro(
      metodoPago: primerPago.metodoPago,
      total: _totalFinal,
      banco:
          pagos.length == 1 ? primerPago.banco : null,
      datofono: pagos.length == 1
          ? primerPago.datofono
          : null,
      valorRecibido: pagos.length == 1
          ? primerPago.valorRecibido
          : null,
      cambio:
          pagos.length == 1 ? primerPago.cambio : 0,
      pagos: pagos,
      datosPedido: datosPedido,
      cobroRealizado: true,
    );
  }

  void _confirmar() {
    final datosPedido =
        _crearDatosPedido();

    if (!widget.soloCobro &&
        datosPedido == null) {
      return;
    }

    if (!_requiereCobroAhora) {
      Navigator.pop(
        context,
        ResultadoCobro(
          metodoPago: MetodoPago.efectivo,
          total: _totalFinal,
          cambio: 0,
          pagos: const [],
          datosPedido: datosPedido,
          cobroRealizado: false,
        ),
      );

      return;
    }

    final resultado =
        _dividirPorComensales
            ? _crearPagoComensales(
                datosPedido,
              )
            : _crearPagoSimple(
                datosPedido,
              );

    if (resultado == null) {
      return;
    }

    Navigator.pop(
      context,
      resultado,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho =
        MediaQuery.of(context).size.width;

    final alto =
        MediaQuery.of(context).size.height;

    final esCelular = ancho < 760;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: esCelular ? 12 : 24,
        vertical: 18,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: esCelular
            ? double.infinity
            : 760,
        constraints: BoxConstraints(
          maxWidth: ancho * 0.96,
          maxHeight: alto * 0.94,
        ),
        padding: EdgeInsets.all(
          esCelular ? 16 : 22,
        ),
        decoration: BoxDecoration(
          color: ColoresApp.superficie,
          borderRadius:
              BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            _encabezado(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!widget.soloCobro) ...[
                      _seccionIdentificacion(),
                      const SizedBox(height: 14),
                      _seccionTipoPedido(),
                      if (_tipoPedido ==
                          TipoPedido.domicilio) ...[
                        const SizedBox(height: 14),
                        _campoTexto(
                          controller:
                              _barrioController,
                          label:
                              'Barrio del domicilio',
                        ),
                      ],
                      const SizedBox(height: 14),
                      _seccionRecargo(),
                      const SizedBox(height: 14),
                    ],
                    _tarjetaTotales(),
                    if (!widget.soloCobro) ...[
                      const SizedBox(height: 14),
                      _seccionMomentoPago(),
                      if (_estadoCobro ==
                          EstadoCobroVenta
                              .cobradoRepartidor) ...[
                        const SizedBox(height: 14),
                        _campoTexto(
                          controller:
                              _responsableDineroController,
                          label:
                              'Quién tiene el dinero',
                        ),
                      ],
                    ],
                    if (_requiereCobroAhora) ...[
                      const SizedBox(height: 18),
                      _selectorTipoCobro(),
                      const SizedBox(height: 16),
                      if (_dividirPorComensales)
                        _contenidoComensales()
                      else
                        _contenidoPagoSimple(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _botonesInferiores(esCelular),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    final titulo = widget.soloCobro
        ? 'Cobrar ${widget.nombrePedido?.trim().isNotEmpty == true ? widget.nombrePedido!.trim() : 'pedido'}'
        : 'Finalizar pedido';

    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close_rounded,
            color: ColoresApp.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _seccionIdentificacion() {
    return _bloque(
      titulo: 'Identificación',
      icono: Icons.badge_rounded,
      child: _campoTexto(
        controller: _nombrePedidoController,
        label: 'Nombre del pedido',
        hint: 'Ejemplo: Juan, Mesa 4, Uber Ana',
      ),
    );
  }

  Widget _seccionTipoPedido() {
    return _bloque(
      titulo: 'Tipo de pedido',
      icono: Icons.shopping_bag_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: TipoPedido.values.map(
          (tipo) {
            final activo =
                _tipoPedido == tipo;

            return ChoiceChip(
              selected: activo,
              label: Text(
                nombreTipoPedido(tipo),
              ),
              selectedColor:
                  ColoresApp.principal,
              backgroundColor: Colors.black,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: activo
                    ? Colors.black
                    : ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: activo
                    ? Colors.transparent
                    : Colors.white
                        .withOpacity(0.08),
              ),
              onSelected: (_) {
                setState(() {
                  _tipoPedido = tipo;

                  if (tipo !=
                      TipoPedido.domicilio) {
                    _barrioController.clear();
                  }
                });
              },
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _seccionRecargo() {
    return _bloque(
      titulo: 'Recargo',
      icono: Icons.percent_rounded,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Escribe el porcentaje que se aplicará únicamente a esta venta.',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller:
                _porcentajeRecargoController,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) {
              setState(() {
                _actualizarMontosAlCambiarTotal();
              });
            },
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              labelText:
                  'Porcentaje de recargo',
              hintText: 'Ejemplo: 10',
              suffixText: '%',
              suffixStyle: const TextStyle(
                color: ColoresApp.principal,
                fontWeight: FontWeight.w900,
              ),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _miniResumen(
            titulo: 'Valor del recargo',
            valor:
                '\$${_valorRecargo.toStringAsFixed(2)}',
            color: ColoresApp.principal,
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTotales() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: ColoresApp.principal
              .withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          if (!widget.soloCobro) ...[
            _filaResumen(
              titulo: 'Consumo',
              valor:
                  '\$${widget.subtotal.toStringAsFixed(2)}',
              color: ColoresApp.textoPrincipal,
            ),
            const SizedBox(height: 9),
            _filaResumen(
              titulo: 'Recargo',
              valor:
                  '\$${_totalRecargos.toStringAsFixed(2)}',
              color:
                  ColoresApp.textoSecundario,
            ),
            const Divider(height: 22),
          ],
          _filaResumen(
            titulo: widget.soloCobro
                ? 'Total pendiente'
                : 'Total',
            valor:
                '\$${_totalFinal.toStringAsFixed(2)}',
            color: ColoresApp.principal,
          ),
        ],
      ),
    );
  }

  Widget _seccionMomentoPago() {
    final estados = [
      EstadoCobroVenta.pagado,
      EstadoCobroVenta.pendientePago,
      EstadoCobroVenta.cobradoRepartidor,
    ];

    return _bloque(
      titulo: 'Momento del pago',
      icono:
          Icons.account_balance_wallet_rounded,
      child: Column(
        children: estados.map(
          (estado) {
            final activo =
                _estadoCobro == estado;

            return RadioListTile<
                EstadoCobroVenta>(
              value: estado,
              groupValue: _estadoCobro,
              activeColor:
                  ColoresApp.principal,
              contentPadding: EdgeInsets.zero,
              title: Text(
                _nombreEstadoCobro(estado),
                style: TextStyle(
                  color:
                      ColoresApp.textoPrincipal,
                  fontWeight: activo
                      ? FontWeight.w900
                      : FontWeight.w600,
                ),
              ),
              subtitle: estado ==
                      EstadoCobroVenta
                          .pendientePago
                  ? const Text(
                      'El pedido se prepara ahora y aparecerá pendiente para cobrarlo después.',
                      style: TextStyle(
                        color: ColoresApp
                            .textoSecundario,
                      ),
                    )
                  : null,
              onChanged: (nuevoEstado) {
                if (nuevoEstado == null) {
                  return;
                }

                setState(() {
                  _estadoCobro = nuevoEstado;
                });
              },
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _selectorTipoCobro() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _botonTipoCobro(
              texto: 'Pago único',
              activo: !_dividirPorComensales,
              onTap: () {
                setState(() {
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
                setState(() {
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
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: activo
              ? ColoresApp.principal
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: activo
                ? Colors.black
                : ColoresApp.textoPrincipal,
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
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: _opcionMetodo(
                metodo: metodo,
                activo:
                    _metodoPagoSimple == metodo,
                onTap: () {
                  _seleccionarMetodoSimple(
                    metodo,
                  );
                },
              ),
            ),
          ),
          if (_metodoPagoSimple ==
              MetodoPago.efectivo) ...[
            const SizedBox(height: 4),
            _campoDinero(
              controller:
                  _valorRecibidoSimpleController,
              label: 'Cliente paga con',
              error:
                  _efectivoSimpleInsuficiente,
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            _resumenEfectivoSimple(),
          ],
          if (_metodoPagoSimple ==
              MetodoPago.transferencia) ...[
            const SizedBox(height: 4),
            _campoTexto(
              controller:
                  _bancoSimpleController,
              label: 'Banco',
            ),
          ],
          if (_metodoPagoSimple ==
              MetodoPago.tarjeta) ...[
            const SizedBox(height: 4),
            _selectorDatofono(
              valor: _datofonoSimple,
              onChanged: (valor) {
                setState(() {
                  _datofonoSimple =
                      valor ?? 'Bendo';
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _contenidoComensales() {
    return Column(
      children: [
        ListView.separated(
          itemCount: _comensales.length,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) {
            return const SizedBox(height: 14);
          },
          itemBuilder: (context, index) {
            return _tarjetaComensal(index);
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _agregarComensal,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: ColoresApp.principal,
            ),
            label: const Text(
              'Agregar otro comensal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  ColoresApp.textoPrincipal,
              side: BorderSide(
                color: ColoresApp.principal
                    .withOpacity(0.40),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _resumenComensales(),
      ],
    );
  }

  Widget _tarjetaComensal(int index) {
    final comensal = _comensales[index];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comensal ${index + 1}',
                  style: const TextStyle(
                    color:
                        ColoresApp.textoPrincipal,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _eliminarComensal(index);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campoDinero(
            controller:
                comensal.montoController,
            label: 'Monto que paga',
            onChanged: (valor) {
              setState(() {
                if (comensal.metodoPago ==
                        MetodoPago.efectivo &&
                    comensal
                        .recibidoController.text
                        .trim()
                        .isEmpty) {
                  comensal
                      .recibidoController.text =
                      valor;
                }
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _usarRestante(index);
              },
              icon: const Icon(
                Icons.calculate_rounded,
                size: 18,
              ),
              label: const Text(
                'Usar monto restante',
              ),
              style: TextButton.styleFrom(
                foregroundColor:
                    ColoresApp.principal,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MetodoPago.values.map(
              (metodo) {
                final activo =
                    comensal.metodoPago ==
                        metodo;

                return ChoiceChip(
                  selected: activo,
                  label: Text(
                    _nombreMetodo(metodo),
                  ),
                  avatar: Icon(
                    _iconoMetodo(metodo),
                    size: 18,
                    color: activo
                        ? Colors.black
                        : ColoresApp
                            .textoSecundario,
                  ),
                  selectedColor:
                      ColoresApp.principal,
                  backgroundColor: Colors.black,
                  labelStyle: TextStyle(
                    color: activo
                        ? Colors.black
                        : ColoresApp
                            .textoPrincipal,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) {
                    setState(() {
                      comensal.metodoPago =
                          metodo;

                      if (metodo ==
                              MetodoPago
                                  .efectivo &&
                          comensal
                              .recibidoController
                              .text
                              .trim()
                              .isEmpty) {
                        comensal
                                .recibidoController
                                .text =
                            comensal
                                .montoController
                                .text;
                      }
                    });
                  },
                );
              },
            ).toList(),
          ),
          if (comensal.metodoPago ==
              MetodoPago.efectivo) ...[
            const SizedBox(height: 14),
            _campoDinero(
              controller:
                  comensal.recibidoController,
              label: 'Entrega en efectivo',
              error:
                  comensal.efectivoInsuficiente,
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
            _miniResumen(
              titulo:
                  comensal.efectivoInsuficiente
                      ? 'Falta efectivo'
                      : 'Vuelto',
              valor:
                  comensal.efectivoInsuficiente
                      ? '\$${(comensal.monto - comensal.recibido).toStringAsFixed(2)}'
                      : '\$${comensal.cambio.toStringAsFixed(2)}',
              color:
                  comensal.efectivoInsuficiente
                      ? ColoresApp.error
                      : ColoresApp.principal,
            ),
          ],
          if (comensal.metodoPago ==
              MetodoPago.transferencia) ...[
            const SizedBox(height: 14),
            _campoTexto(
              controller:
                  comensal.bancoController,
              label: 'Banco',
            ),
          ],
          if (comensal.metodoPago ==
              MetodoPago.tarjeta) ...[
            const SizedBox(height: 14),
            _selectorDatofono(
              valor: comensal.datofono,
              onChanged: (valor) {
                setState(() {
                  comensal.datofono =
                      valor ?? 'Bendo';
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _resumenComensales() {
    final completo = _cuentaCompleta;

    final excedente =
        _excedenteComensales;

    final Color color;

    if (completo) {
      color = ColoresApp.exito;
    } else if (excedente > 0) {
      color = ColoresApp.error;
    } else {
      color = ColoresApp.principal;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          _filaResumen(
            titulo: 'Total de la cuenta',
            valor:
                '\$${_totalFinal.toStringAsFixed(2)}',
            color: ColoresApp.textoPrincipal,
          ),
          const SizedBox(height: 9),
          _filaResumen(
            titulo: 'Total ingresado',
            valor:
                '\$${_totalComensales.toStringAsFixed(2)}',
            color: color,
          ),
          const SizedBox(height: 9),
          if (completo)
            _filaResumen(
              titulo: 'Estado',
              valor: 'Completo',
              color: ColoresApp.exito,
            )
          else if (excedente > 0)
            _filaResumen(
              titulo: 'Excedente',
              valor:
                  '\$${excedente.toStringAsFixed(2)}',
              color: ColoresApp.error,
            )
          else
            _filaResumen(
              titulo: 'Falta por pagar',
              valor:
                  '\$${_restanteComensales.toStringAsFixed(2)}',
              color: ColoresApp.principal,
            ),
        ],
      ),
    );
  }

  Widget _bloque({
    required String titulo,
    required IconData icono,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: ColoresApp.principal,
              ),
              const SizedBox(width: 9),
              Text(
                titulo,
                style: const TextStyle(
                  color:
                      ColoresApp.textoPrincipal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _opcionMetodo({
    required MetodoPago metodo,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: activo
              ? ColoresApp.principal
                  .withOpacity(0.14)
              : Colors.black,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: activo
                ? ColoresApp.principal
                : Colors.white
                    .withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconoMetodo(metodo),
              color: activo
                  ? ColoresApp.principal
                  : ColoresApp
                      .textoSecundario,
            ),
            const SizedBox(width: 12),
            Text(
              _nombreMetodo(metodo),
              style: TextStyle(
                color:
                    ColoresApp.textoPrincipal,
                fontWeight: activo
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenEfectivoSimple() {
    return _miniResumen(
      titulo: _efectivoSimpleInsuficiente
          ? 'Falta por pagar'
          : 'Vuelto a entregar',
      valor: _efectivoSimpleInsuficiente
          ? '\$${(_totalFinal - _valorRecibidoSimple).toStringAsFixed(2)}'
          : '\$${_cambioSimple.toStringAsFixed(2)}',
      color: _efectivoSimpleInsuficiente
          ? ColoresApp.error
          : ColoresApp.principal,
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
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: onChanged,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        labelStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        prefixStyle: const TextStyle(
          color: ColoresApp.principal,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide(
            color: error
                ? ColoresApp.error
                : Colors.white
                    .withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide(
            color: error
                ? ColoresApp.error
                : ColoresApp.principal,
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        hintStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _selectorDatofono({
    required String valor,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: valor,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      decoration: InputDecoration(
        labelText: 'Datáfono',
        labelStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
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
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color:
                    ColoresApp.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaResumen({
    required String titulo,
    required String valor,
    required Color color,
  }) {
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

  Widget _botonesInferiores(
    bool esCelular,
  ) {
    final cancelar = OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor:
            ColoresApp.textoPrincipal,
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
      child: const Text('Cancelar'),
    );

    final String textoConfirmar;

    if (widget.soloCobro) {
      textoConfirmar = 'Confirmar cobro';
    } else if (_requiereCobroAhora) {
      textoConfirmar =
          'Cobrar y enviar a preparación';
    } else {
      textoConfirmar =
          'Enviar a preparación';
    }

    final confirmar = ElevatedButton(
      onPressed: _confirmar,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
      child: Text(
        textoConfirmar,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (esCelular) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: confirmar,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: cancelar,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: cancelar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: confirmar,
          ),
        ),
      ],
    );
  }
}