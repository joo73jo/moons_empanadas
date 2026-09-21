import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

class DialogoComboSabores extends StatefulWidget {
  final ProductoVenta combo;

  /*
   * Se mantiene este parámetro para no romper llamadas
   * antiguas mientras terminamos de actualizar pagina_ventas.
   */
  final List<ProductoVenta> saboresDisponibles;

  const DialogoComboSabores({
    super.key,
    required this.combo,
    this.saboresDisponibles = const [],
  });

  @override
  State<DialogoComboSabores> createState() => _DialogoComboSaboresState();
}

class _DialogoComboSaboresState extends State<DialogoComboSabores> {
  final Map<int, OpcionComponenteCombo> _opcionesSeleccionadas = {};

  List<ComponenteCombo> get _componentes {
    final lista = widget.combo.componentesCombo
        .where((componente) => componente.activo)
        .toList();

    lista.sort((a, b) {
      final comparacionOrden = a.orden.compareTo(b.orden);

      if (comparacionOrden != 0) {
        return comparacionOrden;
      }

      return a.nombreComponente.toLowerCase().compareTo(
        b.nombreComponente.toLowerCase(),
      );
    });

    return lista;
  }

  double get _recargoTotal {
    double total = 0;

    for (final componente in _componentes) {
      final opcion =
          _opcionesSeleccionadas[componente.id] ??
          componente.opcionPredeterminada;

      total += opcion.recargo * componente.cantidad;
    }

    return total;
  }

  double get _precioFinal {
    return widget.combo.precio + _recargoTotal;
  }

  bool get _configuracionCompleta {
    if (_componentes.isEmpty) {
      return false;
    }

    for (final componente in _componentes) {
      if (!_opcionesSeleccionadas.containsKey(componente.id)) {
        return false;
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();

    for (final componente in _componentes) {
      _opcionesSeleccionadas[componente.id] = componente.opcionPredeterminada;
    }
  }

  void _seleccionarOpcion(
    ComponenteCombo componente,
    OpcionComponenteCombo opcion,
  ) {
    setState(() {
      _opcionesSeleccionadas[componente.id] = opcion;
    });
  }

  void _confirmar() {
    if (!_configuracionCompleta) {
      _mostrarMensaje('Debes completar todos los componentes del combo.');

      return;
    }

    final elecciones = <EleccionComponenteCombo>[];

    for (final componente in _componentes) {
      final opcion = _opcionesSeleccionadas[componente.id];

      if (opcion == null) {
        continue;
      }

      final fueSustituido =
          opcion.producto.id != componente.productoPredeterminado.id;

      elecciones.add(
        EleccionComponenteCombo(
          componenteId: componente.id,
          nombreComponente: componente.nombreComponente,
          productoPredeterminadoId: componente.productoPredeterminado.id,
          productoElegido: opcion.producto,
          cantidad: componente.cantidad,
          recargoUnitario: opcion.recargo,
          fueSustituido: fueSustituido,
        ),
      );
    }

    Navigator.pop(context, ResultadoSeleccionCombo(elecciones: elecciones));
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

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;

    final altoPantalla = MediaQuery.of(context).size.height;

    final esCelular = anchoPantalla < 760;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(esCelular ? 12 : 24),
      child: Container(
        width: 820,
        constraints: BoxConstraints(
          maxWidth: anchoPantalla * 0.96,
          maxHeight: altoPantalla * 0.92,
        ),
        decoration: BoxDecoration(
          color: ColoresApp.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            _encabezado(),
            Expanded(
              child: _componentes.isEmpty
                  ? _mensajeSinConfiguracion()
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(esCelular ? 14 : 20),
                      child: Column(
                        children: [
                          _resumenPrecio(),
                          const SizedBox(height: 16),
                          ...List.generate(_componentes.length, (index) {
                            final componente = _componentes[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _componentes.length - 1
                                    ? 0
                                    : 14,
                              ),
                              child: _tarjetaComponente(
                                componente,
                                index,
                                esCelular,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
            _acciones(),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 17, 12, 17),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ColoresApp.principal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: ColoresApp.principal,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.combo.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Revisa los productos incluidos y realiza sustituciones',
                  style: TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
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
      ),
    );
  }

  Widget _resumenPrecio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColoresApp.principal.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          _filaPrecio(titulo: 'Precio del combo', valor: widget.combo.precio),
          if (_recargoTotal > 0) ...[
            const SizedBox(height: 9),
            _filaPrecio(
              titulo: 'Recargo por sustituciones',
              valor: _recargoTotal,
              color: const Color(0xFFFFA726),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0x22FFFFFF), height: 1),
          ),
          _filaPrecio(
            titulo: 'Precio final',
            valor: _precioFinal,
            resaltar: true,
          ),
        ],
      ),
    );
  }

  Widget _filaPrecio({
    required String titulo,
    required double valor,
    Color? color,
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
              fontSize: resaltar ? 17 : 14,
              fontWeight: resaltar ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color:
                color ??
                (resaltar ? ColoresApp.principal : ColoresApp.textoPrincipal),
            fontSize: resaltar ? 23 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaComponente(
    ComponenteCombo componente,
    int index,
    bool esCelular,
  ) {
    final opciones = componente.todasLasOpciones;

    final seleccion =
        _opcionesSeleccionadas[componente.id] ??
        componente.opcionPredeterminada;

    final esSustitucion =
        seleccion.producto.id != componente.productoPredeterminado.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esSustitucion
              ? const Color(0xFFFFA726).withOpacity(0.35)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColoresApp.principal.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      componente.nombreComponente,
                      style: const TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      componente.cantidad > 1
                          ? 'Incluye ${componente.cantidad} unidades'
                          : 'Incluye 1 unidad',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (esSustitucion)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sustituido',
                    style: TextStyle(
                      color: Color(0xFFFFA726),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<OpcionComponenteCombo>(
            value: _buscarOpcionSeleccionada(opciones, seleccion),
            isExpanded: true,
            dropdownColor: ColoresApp.superficie,
            style: const TextStyle(color: ColoresApp.textoPrincipal),
            decoration: InputDecoration(
              labelText: componente.permiteSustitucion
                  ? 'Producto elegido'
                  : 'Producto incluido',
              labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
              filled: true,
              fillColor: Colors.black.withOpacity(0.22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: ColoresApp.principal),
              ),
            ),
            items: opciones.map((opcion) {
              final esPredeterminada =
                  opcion.producto.id == componente.productoPredeterminado.id;

              final recargoTexto = opcion.recargo > 0
                  ? '  +\$${opcion.recargo.toStringAsFixed(2)}'
                  : '';

              return DropdownMenuItem(
                value: opcion,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opcion.producto.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      esPredeterminada
                          ? 'Incluido'
                          : recargoTexto.isEmpty
                          ? 'Sin recargo'
                          : recargoTexto,
                      style: TextStyle(
                        color: esPredeterminada
                            ? ColoresApp.principal
                            : opcion.recargo > 0
                            ? const Color(0xFFFFA726)
                            : ColoresApp.textoSecundario,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: componente.permiteSustitucion
                ? (opcion) {
                    if (opcion == null) {
                      return;
                    }

                    _seleccionarOpcion(componente, opcion);
                  }
                : null,
          ),
          const SizedBox(height: 11),
          _detalleSeleccion(componente, seleccion, esCelular),
        ],
      ),
    );
  }

  OpcionComponenteCombo? _buscarOpcionSeleccionada(
    List<OpcionComponenteCombo> opciones,
    OpcionComponenteCombo seleccion,
  ) {
    for (final opcion in opciones) {
      if (opcion.producto.id == seleccion.producto.id) {
        return opcion;
      }
    }

    if (opciones.isEmpty) {
      return null;
    }

    return opciones.first;
  }

  Widget _detalleSeleccion(
    ComponenteCombo componente,
    OpcionComponenteCombo seleccion,
    bool esCelular,
  ) {
    final cantidadTotal = componente.cantidad;

    final recargoTotal = seleccion.recargo * cantidadTotal;

    final esPredeterminado =
        seleccion.producto.id == componente.productoPredeterminado.id;

    final contenido = [
      _datoSeleccion(
        icono: Icons.inventory_2_rounded,
        titulo: 'Producto',
        valor: seleccion.producto.nombre,
      ),
      _datoSeleccion(
        icono: Icons.numbers_rounded,
        titulo: 'Cantidad',
        valor: '$cantidadTotal',
      ),
      _datoSeleccion(
        icono: Icons.add_card_rounded,
        titulo: 'Recargo',
        valor: recargoTotal > 0
            ? '\$${recargoTotal.toStringAsFixed(2)}'
            : '\$0.00',
        resaltar: recargoTotal > 0,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esPredeterminado
                ? 'Configuración predeterminada'
                : 'Sustitución seleccionada',
            style: TextStyle(
              color: esPredeterminado
                  ? ColoresApp.principal
                  : const Color(0xFFFFA726),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          if (esCelular)
            Column(
              children: contenido
                  .map(
                    (widget) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: widget,
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              children: List.generate(
                contenido.length,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == contenido.length - 1 ? 0 : 12,
                    ),
                    child: contenido[index],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _datoSeleccion({
    required IconData icono,
    required String titulo,
    required String valor,
    bool resaltar = false,
  }) {
    return Row(
      children: [
        Icon(
          icono,
          size: 18,
          color: resaltar ? const Color(0xFFFFA726) : ColoresApp.principal,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 10,
                ),
              ),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: resaltar
                      ? const Color(0xFFFFA726)
                      : ColoresApp.textoPrincipal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mensajeSinConfiguracion() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSecundario,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              SizedBox(height: 12),
              Text(
                'Este combo no tiene componentes configurados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Edita el producto y agrega los productos que incluye.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColoresApp.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acciones() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColoresApp.textoPrincipal,
                side: BorderSide(color: Colors.white.withOpacity(0.13)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _configuracionCompleta ? _confirmar : null,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(
                _recargoTotal > 0
                    ? 'Agregar por \$${_precioFinal.toStringAsFixed(2)}'
                    : 'Agregar combo',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.principal,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
