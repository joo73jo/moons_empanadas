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

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
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
              content: SingleChildScrollView(
                child: Column(
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
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: esCelular ? 10 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: esCelular ? 120 : 220),
                child: Text(
                  widget.usuario.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: ColoresApp.fondoPrincipal,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(
                  color: ColoresApp.principal,
                ),
              )
            : RefreshIndicator(
                color: ColoresApp.principal,
                backgroundColor: ColoresApp.superficie,
                onRefresh: _cargarCaja,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(esCelular ? 14 : 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: esCelular
                          ? Column(
                              children: [
                                _panelCajaActual(caja, esCelular: true),
                                const SizedBox(height: 14),
                                _panelHistorial(esCelular: true),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _panelCajaActual(
                                    caja,
                                    esCelular: false,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: _panelHistorial(esCelular: false),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _panelCajaActual(
    CajaResumen? caja, {
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 20),
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
          Text(
            'Caja actual',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caja == null ? 'No hay caja abierta' : 'Caja #${caja.id} abierta',
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
            _estadoSinCaja(esCelular)
          else
            _contenidoCajaAbierta(caja, esCelular),
        ],
      ),
    );
  }

  Widget _estadoSinCaja(bool esCelular) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.point_of_sale_rounded,
            color: ColoresApp.principal,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay una caja abierta.',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _esDueno
                ? 'Abre una caja para empezar a vender.'
                : 'Solo el dueño puede abrir caja.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _procesando ? null : (_esDueno ? _abrirCaja : null),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black,
                        ),
                      ),
                    )
                  : Text(
                      _esDueno ? 'Abrir caja' : 'Acceso restringido',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoCajaAbierta(CajaResumen caja, bool esCelular) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            final columnas = ancho < 520 ? 2 : 3;
            final alto = ancho < 520 ? 126.0 : 124.0;

            return GridView.count(
              crossAxisCount: columnas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: (ancho / columnas) / alto,
              children: [
                _tarjetaMonto(
                  titulo: 'Monto inicial',
                  valor: caja.montoInicial,
                ),
                _tarjetaMonto(
                  titulo: 'Total ventas',
                  valor: caja.totalVentas,
                ),
                _tarjetaMonto(
                  titulo: 'Efectivo',
                  valor: caja.totalEfectivo,
                ),
                _tarjetaMonto(
                  titulo: 'Transferencia',
                  valor: caja.totalTransferencia,
                ),
                _tarjetaMonto(
                  titulo: 'Tarjeta',
                  valor: caja.totalTarjeta,
                ),
                _tarjetaMonto(
                  titulo: 'Esperado en caja',
                  valor: caja.esperadoEnCaja,
                  resaltar: true,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (_esDueno)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _procesando ? null : _editarMontoInicial,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColoresApp.textoPrincipal,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _procesando ? null : (_esDueno ? _cerrarCaja : null),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.black,
                      ),
                    ),
                  )
                : Text(
                    _esDueno ? 'Cerrar caja' : 'Solo el dueño puede cerrar caja',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _panelHistorial({required bool esCelular}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 20),
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
          Text(
            'Historial reciente',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (_historial.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No hay cajas registradas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: _historial.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _historial[index];
                return _tarjetaHistorial(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _tarjetaHistorial(CajaResumen item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Caja #${item.id}',
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.estado == 'abierta'
                      ? const Color(0x2200A896)
                      : const Color(0x22D99A1B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.estado.toUpperCase(),
                  style: TextStyle(
                    color: item.estado == 'abierta'
                        ? const Color(0xFF00A896)
                        : ColoresApp.principal,
                    fontWeight: FontWeight.w900,
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
              color: ColoresApp.textoSecundario,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.fechaCierre != null
                ? 'Cierre: ${_formatearFechaHora(item.fechaCierre!)}'
                : 'Cierre: pendiente',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _filaHistorial('Monto inicial', item.montoInicial),
          _filaHistorial('Ventas', item.totalVentas),
          _filaHistorial('Efectivo', item.totalEfectivo),
          _filaHistorial('Transferencia', item.totalTransferencia),
          _filaHistorial('Tarjeta', item.totalTarjeta),
          _filaHistorial('Diferencia', item.diferencia, resaltar: true),
        ],
      ),
    );
  }

  Widget _tarjetaMonto({
    required String titulo,
    required double valor,
    bool resaltar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: resaltar
              ? ColoresApp.principal.withOpacity(0.18)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            resaltar ? Icons.savings_rounded : Icons.payments_rounded,
            color: resaltar ? ColoresApp.principal : ColoresApp.textoSecundario,
            size: 22,
          ),
          const Spacer(),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              '\$${valor.toStringAsFixed(2)}',
              maxLines: 1,
              style: TextStyle(
                color:
                    resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
                fontSize: resaltar ? 24 : 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaHistorial(String titulo, double valor, {bool resaltar = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '\$${valor.toStringAsFixed(2)}',
              style: TextStyle(
                color:
                    resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w900,
              ),
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