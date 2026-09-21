import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

part 'dialogo_cobro/secciones_pedido_cobro.dart';
part 'dialogo_cobro/pago_simple_cobro.dart';
part 'dialogo_cobro/pago_comensales_cobro.dart';
part 'dialogo_cobro/componentes_cobro.dart';

enum MetodoPago { efectivo, transferencia, tarjeta }

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

    return pagos.map((pago) => pago.metodoPago).toSet().length > 1;
  }

  double get totalPagado {
    return pagos.fold(0, (total, pago) => total + pago.monto);
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
  }) : montoController = TextEditingController(text: montoInicial),
       bancoController = TextEditingController(),
       recibidoController = TextEditingController(text: montoInicial);

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
    return metodoPago == MetodoPago.efectivo && monto > 0 && recibido < monto;
  }

  static double _leerNumero(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.')) ?? 0;
  }

  void dispose() {
    montoController.dispose();
    bancoController.dispose();
    recibidoController.dispose();
  }
}

class DialogoCobro extends StatefulWidget {
  final double subtotal;

  final List<RecargoConfiguracion> recargosDisponibles;

  final bool soloCobro;

  final String? nombrePedido;

  final bool esVentaPlataforma;

  final List<PlataformaConfiguracion> plataformasDisponibles;

  const DialogoCobro({
    super.key,
    double? subtotal,
    double? total,
    this.recargosDisponibles = const [],
    this.soloCobro = false,
    this.nombrePedido,
    this.esVentaPlataforma = false,
    this.plataformasDisponibles = const [],
  }) : subtotal = subtotal ?? total ?? 0;

  @override
  State<DialogoCobro> createState() => _DialogoCobroState();
}

class _DialogoCobroState extends State<DialogoCobro> {
  final TextEditingController _nombrePedidoController = TextEditingController();

  final TextEditingController _barrioController = TextEditingController();

  final TextEditingController _responsableDineroController =
      TextEditingController();

  final TextEditingController _porcentajeRecargoController =
      TextEditingController();

  final TextEditingController _valorDomicilioController =
      TextEditingController();

  final TextEditingController _porcentajePlataformaController =
      TextEditingController();

  final TextEditingController _bancoSimpleController = TextEditingController();

  final TextEditingController _valorRecibidoSimpleController =
      TextEditingController();

  final List<_PagoComensal> _comensales = [];

  TipoPedido _tipoPedido = TipoPedido.local;

  EstadoCobroVenta _estadoCobro = EstadoCobroVenta.pagado;

  MetodoPago _metodoPagoSimple = MetodoPago.efectivo;

  bool _dividirPorComensales = false;

  String _datofonoSimple = 'Bendo';

  bool _usaIndrive = false;

  String _plataformaSeleccionada = '';

  bool _esProgramado = false;

  DateTime? _fechaProgramada;

  @override
  void initState() {
    super.initState();

    final nombre = widget.nombrePedido?.trim() ?? '';

    if (nombre.isNotEmpty) {
      _nombrePedidoController.text = nombre;
    }

    final totalInicial = widget.subtotal.toStringAsFixed(2);

    _valorRecibidoSimpleController.text = totalInicial;

    _comensales.add(_PagoComensal(montoInicial: totalInicial));

    if (widget.esVentaPlataforma && widget.plataformasDisponibles.isNotEmpty) {
      PlataformaConfiguracion? inicial;

      for (final plataforma in widget.plataformasDisponibles) {
        if (plataforma.activo) {
          inicial = plataforma;
          break;
        }
      }

      inicial ??= widget.plataformasDisponibles.first;

      _plataformaSeleccionada = inicial.nombre;

      _porcentajePlataformaController.text = inicial.porcentaje.toStringAsFixed(
        2,
      );
    }
  }

  @override
  void dispose() {
    _nombrePedidoController.dispose();
    _barrioController.dispose();
    _responsableDineroController.dispose();
    _porcentajeRecargoController.dispose();
    _valorDomicilioController.dispose();
    _porcentajePlataformaController.dispose();
    _bancoSimpleController.dispose();
    _valorRecibidoSimpleController.dispose();

    for (final comensal in _comensales) {
      comensal.dispose();
    }

    super.dispose();
  }

  double _leerNumero(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  double get _valorDomicilio {
    if (_tipoPedido != TipoPedido.domicilio) {
      return 0;
    }

    final valor = _leerNumero(_valorDomicilioController);

    return valor < 0 ? 0 : valor;
  }

  double get _porcentajePlataforma {
    if (!widget.esVentaPlataforma) {
      return 0;
    }

    final valor = _leerNumero(_porcentajePlataformaController);

    if (valor < 0) return 0;
    if (valor > 100) return 100;

    return valor;
  }

  double get _descuentoPlataforma {
    if (!widget.esVentaPlataforma) {
      return 0;
    }

    return widget.subtotal * _porcentajePlataforma / 100;
  }

  double get _porcentajeRecargo {
    final porcentaje = _leerNumero(_porcentajeRecargoController);

    if (porcentaje < 0) {
      return 0;
    }

    if (porcentaje > 100) {
      return 100;
    }

    return porcentaje;
  }

  double get _valorRecargo {
    return widget.subtotal * _porcentajeRecargo / 100;
  }

  List<RecargoAplicado> get _recargosAplicados {
    if (widget.soloCobro || _porcentajeRecargo <= 0) {
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
    return widget.subtotal + _totalRecargos + _valorDomicilio;
  }

  bool get _requiereCobroAhora {
    if (widget.soloCobro) {
      return true;
    }

    if (_esProgramado) {
      return false;
    }

    return _estadoCobro == EstadoCobroVenta.pagado;
  }

  double get _valorRecibidoSimple {
    return _leerNumero(_valorRecibidoSimpleController);
  }

  double get _cambioSimple {
    if (_metodoPagoSimple != MetodoPago.efectivo) {
      return 0;
    }

    final cambio = _valorRecibidoSimple - _totalFinal;

    return cambio > 0 ? cambio : 0;
  }

  bool get _efectivoSimpleInsuficiente {
    return _metodoPagoSimple == MetodoPago.efectivo &&
        _valorRecibidoSimple < _totalFinal;
  }

  double get _totalComensales {
    return _comensales.fold(0, (total, comensal) => total + comensal.monto);
  }

  double get _restanteComensales {
    final restante = _totalFinal - _totalComensales;

    return restante > 0 ? restante : 0;
  }

  double get _excedenteComensales {
    final excedente = _totalComensales - _totalFinal;

    return excedente > 0 ? excedente : 0;
  }

  bool get _cuentaCompleta {
    return (_totalComensales - _totalFinal).abs() <= 0.01;
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

  String _nombreEstadoCobro(EstadoCobroVenta estado) {
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

  void _actualizarMontosAlCambiarTotal() {
    final total = _totalFinal.toStringAsFixed(2);

    _valorRecibidoSimpleController.text = total;

    if (_comensales.length == 1) {
      final comensal = _comensales.first;

      comensal.montoController.text = total;

      if (comensal.metodoPago == MetodoPago.efectivo) {
        comensal.recibidoController.text = total;
      }
    }
  }

  void _seleccionarMetodoSimple(MetodoPago metodo) {
    setState(() {
      _metodoPagoSimple = metodo;

      if (metodo == MetodoPago.efectivo &&
          _valorRecibidoSimpleController.text.trim().isEmpty) {
        _valorRecibidoSimpleController.text = _totalFinal.toStringAsFixed(2);
      }
    });
  }

  void _agregarComensal() {
    setState(() {
      final restante = _restanteComensales;

      _comensales.add(
        _PagoComensal(
          montoInicial: restante > 0 ? restante.toStringAsFixed(2) : '',
        ),
      );
    });
  }

  void _eliminarComensal(int index) {
    if (_comensales.length <= 1) {
      _mostrarMensaje('Debe existir al menos un comensal.');

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

    for (int i = 0; i < _comensales.length; i++) {
      if (i != index) {
        sumaOtros += _comensales[i].monto;
      }
    }

    final restante = _totalFinal - sumaOtros;

    final monto = restante > 0 ? restante : 0;

    setState(() {
      final comensal = _comensales[index];

      comensal.montoController.text = monto.toStringAsFixed(2);

      if (comensal.metodoPago == MetodoPago.efectivo) {
        comensal.recibidoController.text = monto.toStringAsFixed(2);
      }
    });
  }

  DatosPedidoVenta? _crearDatosPedido() {
    if (widget.soloCobro) {
      return null;
    }

    final nombrePedido = _nombrePedidoController.text.trim();

    if (nombrePedido.isEmpty) {
      _mostrarMensaje('Ingresa el nombre del pedido.');

      return null;
    }

    final barrio = _barrioController.text.trim();

    if (_tipoPedido == TipoPedido.domicilio && barrio.isEmpty) {
      _mostrarMensaje('Ingresa el barrio del domicilio.');

      return null;
    }

    if (widget.esVentaPlataforma && _plataformaSeleccionada.trim().isEmpty) {
      _mostrarMensaje('Selecciona la plataforma.');

      return null;
    }

    if (_esProgramado) {
      if (_fechaProgramada == null) {
        _mostrarMensaje('Selecciona la fecha y hora de entrega.');

        return null;
      }

      if (_fechaProgramada!.isBefore(DateTime.now())) {
        _mostrarMensaje('La fecha programada debe ser futura.');

        return null;
      }
    }

    final estadoCobroReal = _esProgramado
        ? EstadoCobroVenta.pendientePago
        : _estadoCobro;

    final responsable = _responsableDineroController.text.trim();

    if (estadoCobroReal == EstadoCobroVenta.cobradoRepartidor &&
        responsable.isEmpty) {
      _mostrarMensaje('Indica quién tiene el dinero.');

      return null;
    }

    return DatosPedidoVenta(
      nombrePedido: nombrePedido,
      tipoPedido: _tipoPedido,
      barrio: barrio,
      estadoCobro: estadoCobroReal,
      responsableDinero: responsable,
      enviarPreparacion: true,
      recargos: const [],

      valorDomicilio: _tipoPedido == TipoPedido.domicilio ? _valorDomicilio : 0,

      usaIndrive: _tipoPedido == TipoPedido.domicilio ? _usaIndrive : false,

      plataforma: widget.esVentaPlataforma
          ? _plataformaSeleccionada.trim()
          : '',

      porcentajePlataforma: widget.esVentaPlataforma
          ? _porcentajePlataforma
          : 0,

      descuentoPlataforma: widget.esVentaPlataforma ? _descuentoPlataforma : 0,

      esProgramado: _esProgramado,

      fechaProgramada: _esProgramado ? _fechaProgramada : null,
    );
  }

  ResultadoCobro? _crearPagoSimple(DatosPedidoVenta? datosPedido) {
    if (_metodoPagoSimple == MetodoPago.efectivo) {
      if (_valorRecibidoSimpleController.text.trim().isEmpty) {
        _mostrarMensaje('Ingresa cuánto entregó el cliente.');

        return null;
      }

      if (_efectivoSimpleInsuficiente) {
        _mostrarMensaje('El valor recibido no puede ser menor al total.');

        return null;
      }
    }

    if (_metodoPagoSimple == MetodoPago.transferencia &&
        _bancoSimpleController.text.trim().isEmpty) {
      _mostrarMensaje('Ingresa el banco de la transferencia.');

      return null;
    }

    final pago = PagoCobro(
      metodoPago: _metodoPagoSimple,
      monto: _totalFinal,
      banco: _metodoPagoSimple == MetodoPago.transferencia
          ? _bancoSimpleController.text.trim()
          : null,
      datofono: _metodoPagoSimple == MetodoPago.tarjeta
          ? _datofonoSimple
          : null,
      valorRecibido: _metodoPagoSimple == MetodoPago.efectivo
          ? _valorRecibidoSimple
          : null,
      cambio: _metodoPagoSimple == MetodoPago.efectivo ? _cambioSimple : 0,
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

  ResultadoCobro? _crearPagoComensales(DatosPedidoVenta? datosPedido) {
    final pagos = <PagoCobro>[];

    for (int i = 0; i < _comensales.length; i++) {
      final comensal = _comensales[i];

      final numero = i + 1;

      if (comensal.monto <= 0) {
        _mostrarMensaje('Ingresa el monto del comensal $numero.');

        return null;
      }

      if (comensal.metodoPago == MetodoPago.efectivo) {
        if (comensal.recibidoController.text.trim().isEmpty) {
          _mostrarMensaje('Ingresa cuánto entrega el comensal $numero.');

          return null;
        }

        if (comensal.efectivoInsuficiente) {
          _mostrarMensaje('El efectivo del comensal $numero es insuficiente.');

          return null;
        }
      }

      if (comensal.metodoPago == MetodoPago.transferencia &&
          comensal.bancoController.text.trim().isEmpty) {
        _mostrarMensaje('Ingresa el banco del comensal $numero.');

        return null;
      }

      pagos.add(
        PagoCobro(
          metodoPago: comensal.metodoPago,
          monto: comensal.monto,
          banco: comensal.metodoPago == MetodoPago.transferencia
              ? comensal.bancoController.text.trim()
              : null,
          datofono: comensal.metodoPago == MetodoPago.tarjeta
              ? comensal.datofono
              : null,
          valorRecibido: comensal.metodoPago == MetodoPago.efectivo
              ? comensal.recibido
              : null,
          cambio: comensal.metodoPago == MetodoPago.efectivo
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
      banco: pagos.length == 1 ? primerPago.banco : null,
      datofono: pagos.length == 1 ? primerPago.datofono : null,
      valorRecibido: pagos.length == 1 ? primerPago.valorRecibido : null,
      cambio: pagos.length == 1 ? primerPago.cambio : 0,
      pagos: pagos,
      datosPedido: datosPedido,
      cobroRealizado: true,
    );
  }

  void _confirmar() {
    final datosPedido = _crearDatosPedido();

    if (!widget.soloCobro && datosPedido == null) {
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

    final resultado = _dividirPorComensales
        ? _crearPagoComensales(datosPedido)
        : _crearPagoSimple(datosPedido);

    if (resultado == null) {
      return;
    }

    Navigator.pop(context, resultado);
  }

  void _actualizarEstado(VoidCallback accion) {
    if (!mounted) return;
    setState(accion);
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    final alto = MediaQuery.of(context).size.height;

    final esCelular = ancho < 760;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: esCelular ? 12 : 24,
        vertical: 18,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: esCelular ? double.infinity : 760,
        constraints: BoxConstraints(
          maxWidth: ancho * 0.96,
          maxHeight: alto * 0.94,
        ),
        padding: EdgeInsets.all(esCelular ? 16 : 22),
        decoration: BoxDecoration(
          color: ColoresApp.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
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

                      const SizedBox(height: 14),

                      _seccionProgramacion(),

                      if (_tipoPedido == TipoPedido.domicilio) ...[
                        const SizedBox(height: 14),
                        _seccionDelivery(),
                      ],

                      if (widget.esVentaPlataforma) ...[
                        const SizedBox(height: 14),
                        _seccionPlataforma(),
                      ],

                      const SizedBox(height: 14),
                    ],

                    _tarjetaTotales(),

                    if (!widget.soloCobro && !_esProgramado) ...[
                      const SizedBox(height: 14),

                      _seccionMomentoPago(),

                      if (_estadoCobro ==
                          EstadoCobroVenta.cobradoRepartidor) ...[
                        const SizedBox(height: 14),

                        _campoTexto(
                          controller: _responsableDineroController,
                          label: 'Quién tiene el dinero',
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
}
