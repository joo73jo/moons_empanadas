import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../widgets/caja_supabase.dart';

class PaginaCaja extends StatefulWidget {
  final Usuario usuario;

  const PaginaCaja({
    super.key,
    required this.usuario,
  });

  @override
  State<PaginaCaja> createState() => _PaginaCajaState();
}

class _PaginaCajaState extends State<PaginaCaja> {
  CajaResumen? _cajaAbierta;
  List<CajaResumen> _historial = [];
  bool _cargando = true;
  bool _procesando = false;

  bool get _esDueno => widget.usuario.rol == 'dueno';

  @override
  void initState() {
    super.initState();
    _cargarCaja();
  }

  Future<void> _cargarCaja() async {
    setState(() {
      _cargando = true;
    });

    try {
      final cajaAbierta = await CajaSupabase.obtenerCajaAbierta();
      final historial = await CajaSupabase.obtenerUltimasCajas();

      if (!mounted) return;

      setState(() {
        _cajaAbierta = cajaAbierta;
        _historial = historial;
        _cargando = false;
        _procesando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _procesando = false;
      });
      _mostrarMensaje('Error cargando caja: $e');
    }
  }

  Future<void> _abrirCaja() async {
    final controller = TextEditingController(text: '0');

    final monto = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: const Text(
          'Abrir caja',
          style: TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: ColoresApp.textoPrincipal),
          decoration: InputDecoration(
            labelText: 'Monto inicial',
            labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
            filled: true,
            fillColor: ColoresApp.fondoSecundario,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: ColoresApp.textoSecundario),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controller.text.trim());
              if (valor == null || valor < 0) return;
              Navigator.pop(context, valor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.principal,
              foregroundColor: Colors.black,
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (monto == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await CajaSupabase.abrirCaja(
        usuarioLogin: widget.usuario.usuario,
        montoInicial: monto,
      );

      if (!mounted) return;
      _mostrarMensaje('Caja abierta correctamente.');
      await _cargarCaja();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error abriendo caja: $e');
    }
  }

  Future<void> _editarMontoInicial() async {
    final caja = _cajaAbierta;
    if (caja == null) return;

    final controller = TextEditingController(
      text: caja.montoInicial.toStringAsFixed(2),
    );

    final monto = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: const Text(
          'Editar monto inicial',
          style: TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: ColoresApp.textoPrincipal),
          decoration: InputDecoration(
            labelText: 'Nuevo monto inicial',
            labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
            filled: true,
            fillColor: ColoresApp.fondoSecundario,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: ColoresApp.textoSecundario),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(controller.text.trim());
              if (valor == null || valor < 0) return;
              Navigator.pop(context, valor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.principal,
              foregroundColor: Colors.black,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (monto == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await CajaSupabase.actualizarMontoInicial(
        cajaId: caja.id,
        montoInicial: monto,
      );

      if (!mounted) return;
      _mostrarMensaje('Monto inicial actualizado.');
      await _cargarCaja();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error actualizando monto inicial: $e');
    }
  }

  Future<void> _cerrarCaja() async {
    final caja = _cajaAbierta;
    if (caja == null) return;

    final montoInicialController = TextEditingController(
      text: caja.montoInicial.toStringAsFixed(2),
    );
    final montoFinalController = TextEditingController(
      text: caja.esperadoEnCaja.toStringAsFixed(2),
    );

    double montoInicialManual = caja.montoInicial;
    double montoFinalManual = caja.esperadoEnCaja;

    final resultado = await showDialog<Map<String, double>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final esperado = montoInicialManual + caja.totalEfectivo;
            final diferencia = montoFinalManual - esperado;

            return AlertDialog(
              backgroundColor: ColoresApp.superficie,
              title: const Text(
                'Cerrar caja',
                style: TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: montoInicialController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: ColoresApp.textoPrincipal),
                    decoration: InputDecoration(
                      labelText: 'Monto inicial manual',
                      labelStyle:
                          const TextStyle(color: ColoresApp.textoSecundario),
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) return;
                      setLocalState(() {
                        montoInicialManual = parsed;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _filaResumenDialogo('Efectivo sistema', caja.totalEfectivo),
                  const SizedBox(height: 12),
                  _filaResumenDialogo('Esperado en caja', esperado),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoFinalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: ColoresApp.textoPrincipal),
                    decoration: InputDecoration(
                      labelText: 'Monto final contado',
                      labelStyle:
                          const TextStyle(color: ColoresApp.textoSecundario),
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) return;
                      setLocalState(() {
                        montoFinalManual = parsed;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _filaResumenDialogo('Diferencia', diferencia),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: ColoresApp.textoSecundario),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final montoInicial =
                        double.tryParse(montoInicialController.text.trim());
                    final montoFinal =
                        double.tryParse(montoFinalController.text.trim());

                    if (montoInicial == null ||
                        montoFinal == null ||
                        montoInicial < 0 ||
                        montoFinal < 0) {
                      return;
                    }

                    Navigator.pop(context, {
                      'montoInicial': montoInicial,
                      'montoFinal': montoFinal,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.principal,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await CajaSupabase.cerrarCaja(
        cajaId: caja.id,
        usuarioLogin: widget.usuario.usuario,
        montoInicialManual: resultado['montoInicial']!,
        montoFinalContado: resultado['montoFinal']!,
      );

      if (!mounted) return;
      _mostrarMensaje('Caja cerrada correctamente.');
      await _cargarCaja();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error cerrando caja: $e');
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
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColoresApp.principal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatearFechaHora(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final yyyy = fecha.year.toString();
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final caja = _cajaAbierta;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
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
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: ColoresApp.principal,
              ),
            )
          : Container(
              color: ColoresApp.fondoPrincipal,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
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
                            'Caja actual',
                            style: TextStyle(
                              color: ColoresApp.textoPrincipal,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            caja == null
                                ? 'No hay caja abierta'
                                : 'Caja #${caja.id} abierta',
                            style: const TextStyle(
                              color: ColoresApp.textoSecundario,
                              fontSize: 14,
                            ),
                          ),
                          if (caja != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Apertura: ${_formatearFechaHora(caja.fechaApertura)}',
                              style: const TextStyle(
                                color: ColoresApp.textoSecundario,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (caja == null)
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: 240,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _procesando
                                        ? null
                                        : (_esDueno ? _abrirCaja : null),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ColoresApp.principal,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _procesando
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            _esDueno
                                                ? 'Abrir caja'
                                                : 'Solo el dueño puede abrir caja',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _tarjetaMonto(
                                          titulo: 'Monto inicial',
                                          valor: caja.montoInicial,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _tarjetaMonto(
                                          titulo: 'Total ventas',
                                          valor: caja.totalVentas,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _tarjetaMonto(
                                          titulo: 'Efectivo',
                                          valor: caja.totalEfectivo,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _tarjetaMonto(
                                          titulo: 'Transferencia',
                                          valor: caja.totalTransferencia,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _tarjetaMonto(
                                          titulo: 'Tarjeta',
                                          valor: caja.totalTarjeta,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _tarjetaMonto(
                                          titulo: 'Esperado en caja',
                                          valor: caja.esperadoEnCaja,
                                          resaltar: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_esDueno)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: _procesando
                                            ? null
                                            : _editarMontoInicial,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              ColoresApp.textoPrincipal,
                                          side: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.12),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          color: ColoresApp.principal,
                                        ),
                                        label: const Text(
                                          'Editar monto inicial',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _procesando
                                          ? null
                                          : (_esDueno ? _cerrarCaja : null),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColoresApp.principal,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _procesando
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.black,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              _esDueno
                                                  ? 'Cerrar caja'
                                                  : 'Solo el dueño puede cerrar caja',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Container(
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
                            'Historial reciente',
                            style: TextStyle(
                              color: ColoresApp.textoPrincipal,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _historial.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay cajas registradas.',
                                      style: TextStyle(
                                        color: ColoresApp.textoSecundario,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _historial.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = _historial[index];

                                      return Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: ColoresApp.fondoSecundario,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Caja #${item.id}',
                                                    style: const TextStyle(
                                                      color: ColoresApp
                                                          .textoPrincipal,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
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
                                                    color: item.estado ==
                                                            'abierta'
                                                        ? const Color(
                                                            0x2200A896,
                                                          )
                                                        : const Color(
                                                            0x22D99A1B,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    item.estado.toUpperCase(),
                                                    style: TextStyle(
                                                      color: item.estado ==
                                                              'abierta'
                                                          ? const Color(
                                                              0xFF00A896,
                                                            )
                                                          : ColoresApp
                                                              .principal,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Apertura: ${_formatearFechaHora(item.fechaApertura)}',
                                              style: const TextStyle(
                                                color: ColoresApp
                                                    .textoSecundario,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.fechaCierre != null
                                                  ? 'Cierre: ${_formatearFechaHora(item.fechaCierre!)}'
                                                  : 'Cierre: pendiente',
                                              style: const TextStyle(
                                                color: ColoresApp
                                                    .textoSecundario,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _filaHistorial(
                                              'Monto inicial',
                                              item.montoInicial,
                                            ),
                                            _filaHistorial(
                                              'Ventas',
                                              item.totalVentas,
                                            ),
                                            _filaHistorial(
                                              'Efectivo',
                                              item.totalEfectivo,
                                            ),
                                            _filaHistorial(
                                              'Transferencia',
                                              item.totalTransferencia,
                                            ),
                                            _filaHistorial(
                                              'Tarjeta',
                                              item.totalTarjeta,
                                            ),
                                            _filaHistorial(
                                              'Diferencia',
                                              item.diferencia,
                                              resaltar: true,
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

  Widget _tarjetaMonto({
    required String titulo,
    required double valor,
    bool resaltar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
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
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color:
                  resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
              fontSize: resaltar ? 26 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaHistorial(String titulo, double valor, {bool resaltar = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color:
                  resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaResumenDialogo(String titulo, double valor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: const TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}