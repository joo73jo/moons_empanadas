import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import 'productos_supabase.dart';
import 'ventas_modelos.dart';

class DialogoProductoVenta extends StatefulWidget {
  final ProductoVenta? producto;

  const DialogoProductoVenta({
    super.key,
    this.producto,
  });

  @override
  State<DialogoProductoVenta> createState() =>
      _DialogoProductoVentaState();
}

class _DialogoProductoVentaState
    extends State<DialogoProductoVenta> {
  late final TextEditingController _nombreController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _precioController;
  late final TextEditingController
      _cantidadSaboresController;

  late SeccionVenta _seccion;
  late bool _requiereSabores;

  bool _cargandoProductos = true;
  String? _errorProductos;

  List<ProductoVenta> _productosDisponibles = [];

  final List<_ComponenteComboEditable>
      _componentesCombo = [];

  bool get _esCombo {
    return _seccion == SeccionVenta.combos;
  }

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.producto?.nombre ?? '',
    );

    _categoriaController = TextEditingController(
      text: widget.producto?.categoria ?? '',
    );

    _precioController = TextEditingController(
      text: widget.producto != null
          ? widget.producto!.precio.toStringAsFixed(2)
          : '',
    );

    _cantidadSaboresController =
        TextEditingController(
      text: widget.producto != null
          ? '${widget.producto!.cantidadSabores}'
          : '0',
    );

    _seccion = widget.producto?.seccion ??
        SeccionVenta.individuales;

    _requiereSabores =
        widget.producto?.requiereSabores ?? false;

    _copiarComponentesExistentes();
    _cargarProductosDisponibles();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _cantidadSaboresController.dispose();

    for (final componente in _componentesCombo) {
      componente.dispose();
    }

    super.dispose();
  }

  void _copiarComponentesExistentes() {
    final componentes =
        widget.producto?.componentesCombo ?? const [];

    for (final componente in componentes) {
      _componentesCombo.add(
        _ComponenteComboEditable.desdeModelo(
          componente,
        ),
      );
    }
  }

  Future<void> _cargarProductosDisponibles() async {
    try {
      final productos =
          await ProductosSupabase.obtenerProductos();

      if (!mounted) return;

      final productoActualId =
          widget.producto?.id ?? 0;

      final disponibles = productos.where((producto) {
        if (producto.id == productoActualId) {
          return false;
        }

        /*
         * Para evitar combos dentro de combos, solo
         * permitimos productos individuales o de Uber.
         */
        return producto.seccion !=
            SeccionVenta.combos;
      }).toList();

      disponibles.sort(
        (a, b) {
          final comparacionCategoria =
              a.categoria.toLowerCase().compareTo(
                    b.categoria.toLowerCase(),
                  );

          if (comparacionCategoria != 0) {
            return comparacionCategoria;
          }

          return a.nombre.toLowerCase().compareTo(
                b.nombre.toLowerCase(),
              );
        },
      );

      setState(() {
        _productosDisponibles = disponibles;
        _cargandoProductos = false;
        _errorProductos = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoProductos = false;
        _errorProductos =
            'No se pudieron cargar los productos: $e';
      });
    }
  }

  String _nombreSeccion(
    SeccionVenta seccion,
  ) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return 'Individuales';

      case SeccionVenta.combos:
        return 'Combos';

      case SeccionVenta.uber:
        return 'Uber';
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

  void _agregarComponente() {
    if (_productosDisponibles.isEmpty) {
      _mostrarMensaje(
        'No existen productos disponibles para configurar el combo.',
      );

      return;
    }

    final productoInicial =
        _productosDisponibles.first;

    setState(() {
      _componentesCombo.add(
        _ComponenteComboEditable(
          id: 0,
          nombreInicial:
              'Componente ${_componentesCombo.length + 1}',
          productoPredeterminado:
              productoInicial,
          cantidadInicial: 1,
          permiteSustitucion: true,
          obligatorio: true,
          opciones: const [],
        ),
      );
    });
  }

  void _eliminarComponente(int index) {
    setState(() {
      final componente =
          _componentesCombo.removeAt(index);

      componente.dispose();
    });
  }

  void _moverComponenteArriba(int index) {
    if (index <= 0) return;

    setState(() {
      final componente =
          _componentesCombo.removeAt(index);

      _componentesCombo.insert(
        index - 1,
        componente,
      );
    });
  }

  void _moverComponenteAbajo(int index) {
    if (index < 0 ||
        index >= _componentesCombo.length - 1) {
      return;
    }

    setState(() {
      final componente =
          _componentesCombo.removeAt(index);

      _componentesCombo.insert(
        index + 1,
        componente,
      );
    });
  }

  Future<void> _agregarSustitucion(
    _ComponenteComboEditable componente,
  ) async {
    final productosNoAgregados =
        _productosDisponibles.where((producto) {
      if (producto.id ==
          componente.productoPredeterminado.id) {
        return false;
      }

      return !componente.opciones.any(
        (opcion) =>
            opcion.producto.id == producto.id,
      );
    }).toList();

    if (productosNoAgregados.isEmpty) {
      _mostrarMensaje(
        'No quedan productos disponibles para agregar como sustitución.',
      );

      return;
    }

    final resultado =
        await showDialog<_ResultadoNuevaSustitucion>(
      context: context,
      builder: (_) => _DialogoNuevaSustitucion(
        productos: productosNoAgregados,
      ),
    );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() {
      componente.opciones.add(
        _OpcionComboEditable(
          id: 0,
          producto: resultado.producto,
          recargoInicial: resultado.recargo,
        ),
      );
    });
  }

  void _eliminarSustitucion(
    _ComponenteComboEditable componente,
    int index,
  ) {
    setState(() {
      final opcion =
          componente.opciones.removeAt(index);

      opcion.dispose();
    });
  }

  List<ComponenteCombo>?
      _crearComponentesParaGuardar() {
    final resultado = <ComponenteCombo>[];

    for (int index = 0;
        index < _componentesCombo.length;
        index++) {
      final editable = _componentesCombo[index];

      final nombre =
          editable.nombreController.text.trim();

      final cantidad = int.tryParse(
            editable.cantidadController.text.trim(),
          ) ??
          0;

      if (nombre.isEmpty) {
        _mostrarMensaje(
          'El componente ${index + 1} debe tener un nombre.',
        );

        return null;
      }

      if (cantidad <= 0) {
        _mostrarMensaje(
          'La cantidad de "$nombre" debe ser mayor a cero.',
        );

        return null;
      }

      final opciones = <OpcionComponenteCombo>[];
      final productosUsados = <int>{};

      for (int opcionIndex = 0;
          opcionIndex < editable.opciones.length;
          opcionIndex++) {
        final opcionEditable =
            editable.opciones[opcionIndex];

        final recargo = double.tryParse(
              opcionEditable.recargoController.text
                  .trim()
                  .replaceAll(',', '.'),
            ) ??
            -1;

        if (recargo < 0) {
          _mostrarMensaje(
            'El recargo de ${opcionEditable.producto.nombre} debe ser cero o mayor.',
          );

          return null;
        }

        if (productosUsados.contains(
          opcionEditable.producto.id,
        )) {
          continue;
        }

        productosUsados.add(
          opcionEditable.producto.id,
        );

        opciones.add(
          OpcionComponenteCombo(
            id: opcionEditable.id,
            componenteId: editable.id,
            producto:
                opcionEditable.producto,
            recargo: recargo,
            activo: true,
            orden: opcionIndex,
          ),
        );
      }

      resultado.add(
        ComponenteCombo(
          id: editable.id,
          comboId: widget.producto?.id ?? 0,
          nombreComponente: nombre,
          productoPredeterminado:
              editable.productoPredeterminado,
          cantidad: cantidad,
          permiteSustitucion:
              editable.permiteSustitucion,
          obligatorio: editable.obligatorio,
          orden: index,
          activo: true,
          opciones: editable.permiteSustitucion
              ? opciones
              : const [],
        ),
      );
    }

    return resultado;
  }

  void _guardar() {
    final nombre =
        _nombreController.text.trim();

    final categoria =
        _categoriaController.text.trim();

    final precio = double.tryParse(
      _precioController.text
          .trim()
          .replaceAll(',', '.'),
    );

    final cantidadSabores = int.tryParse(
          _cantidadSaboresController.text.trim(),
        ) ??
        0;

    if (nombre.isEmpty) {
      _mostrarMensaje(
        'Debes ingresar el nombre del producto.',
      );

      return;
    }

    if (categoria.isEmpty) {
      _mostrarMensaje(
        'Debes ingresar la categoría.',
      );

      return;
    }

    if (precio == null || precio <= 0) {
      _mostrarMensaje(
        'El precio debe ser mayor a cero.',
      );

      return;
    }

    if (_requiereSabores &&
        cantidadSabores <= 0) {
      _mostrarMensaje(
        'La cantidad de sabores debe ser mayor a cero.',
      );

      return;
    }

    List<ComponenteCombo> componentes =
        const [];

    if (_esCombo) {
      final componentesResultado =
          _crearComponentesParaGuardar();

      if (componentesResultado == null) {
        return;
      }

      componentes = componentesResultado;

      if (componentes.isEmpty) {
        _mostrarMensaje(
          'Debes agregar al menos un componente al combo.',
        );

        return;
      }
    }

    Navigator.pop(
      context,
      ProductoVenta(
        id: widget.producto?.id ?? 0,
        nombre: nombre,
        categoria: categoria,
        precio: precio,
        seccion: _seccion,

        /*
         * Los combos nuevos usan componentes por ID.
         * El selector antiguo de sabores queda reservado
         * para productos anteriores que todavía lo usen.
         */
        requiereSabores:
            _esCombo ? false : _requiereSabores,
        cantidadSabores:
            _esCombo || !_requiereSabores
                ? 0
                : cantidadSabores,

        /*
         * El combo no controla stock propio. Se descontarán
         * los productos elegidos en sus componentes.
         */
        controlaStock:
            _seccion ==
                SeccionVenta.individuales,

        stockActual:
            widget.producto?.stockActual ?? 0,
        stockMinimo:
            widget.producto?.stockMinimo ?? 0,
        stockCritico:
            widget.producto?.stockCritico ?? 0,
        componentesCombo: componentes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla =
        MediaQuery.of(context).size.width;

    final altoPantalla =
        MediaQuery.of(context).size.height;

    final esCelular = anchoPantalla < 760;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(
        esCelular ? 12 : 24,
      ),
      child: Container(
        width: _esCombo ? 920 : 480,
        constraints: BoxConstraints(
          maxWidth: anchoPantalla * 0.96,
          maxHeight: altoPantalla * 0.92,
        ),
        decoration: BoxDecoration(
          color: ColoresApp.superficie,
          borderRadius:
              BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          children: [
            _encabezado(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  esCelular ? 16 : 22,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _datosPrincipales(
                      esCelular,
                    ),
                    if (_esCombo) ...[
                      const SizedBox(height: 22),
                      _configuracionCombo(
                        esCelular,
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      _configuracionSabores(),
                    ],
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
      padding: const EdgeInsets.fromLTRB(
        22,
        18,
        14,
        18,
      ),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColoresApp.principal
                  .withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              _esCombo
                  ? Icons.local_offer_rounded
                  : Icons.fastfood_rounded,
              color: ColoresApp.principal,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto == null
                      ? 'Nuevo producto'
                      : 'Editar producto',
                  style: const TextStyle(
                    color:
                        ColoresApp.textoPrincipal,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _esCombo
                      ? 'Configura el combo y sus sustituciones'
                      : 'Información general del producto',
                  style: const TextStyle(
                    color:
                        ColoresApp.textoSecundario,
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

  Widget _datosPrincipales(bool esCelular) {
    final nombre = _campo(
      controller: _nombreController,
      etiqueta: 'Nombre',
    );

    final categoria = _campo(
      controller: _categoriaController,
      etiqueta: 'Categoría',
    );

    final precio = _campo(
      controller: _precioController,
      etiqueta: 'Precio',
      prefijo: '\$ ',
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
    );

    final seccion =
        DropdownButtonFormField<SeccionVenta>(
      value: _seccion,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      decoration: _decoracionCampo(
        'Sección',
      ),
      items: SeccionVenta.values.map((valor) {
        return DropdownMenuItem(
          value: valor,
          child: Text(
            _nombreSeccion(valor),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _seccion = value;

          if (_esCombo) {
            _requiereSabores = false;
            _cantidadSaboresController.text =
                '0';
          }
        });
      },
    );

    if (esCelular) {
      return Column(
        children: [
          nombre,
          const SizedBox(height: 12),
          categoria,
          const SizedBox(height: 12),
          precio,
          const SizedBox(height: 12),
          seccion,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: nombre),
            const SizedBox(width: 12),
            Expanded(child: categoria),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: precio),
            const SizedBox(width: 12),
            Expanded(child: seccion),
          ],
        ),
      ],
    );
  }

  Widget _configuracionSabores() {
    return Column(
      children: [
        SwitchListTile(
          value: _requiereSabores,
          activeColor: ColoresApp.principal,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          title: const Text(
            'Requiere sabores',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'Actívalo para productos anteriores con selección de sabores',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _requiereSabores = value;

              if (!value) {
                _cantidadSaboresController.text =
                    '0';
              }
            });
          },
        ),
        if (_requiereSabores) ...[
          const SizedBox(height: 8),
          _campo(
            controller:
                _cantidadSaboresController,
            etiqueta: 'Cantidad de sabores',
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _configuracionCombo(
    bool esCelular,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        esCelular ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: ColoresApp.principal
              .withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Componentes del combo',
                      style: TextStyle(
                        color:
                            ColoresApp.textoPrincipal,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'El inventario descontará los productos realmente seleccionados.',
                      style: TextStyle(
                        color:
                            ColoresApp.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _cargandoProductos
                    ? null
                    : _agregarComponente,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: const Text(
                  'Agregar componente',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      ColoresApp.principal,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cargandoProductos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(
                  color: ColoresApp.principal,
                ),
              ),
            )
          else if (_errorProductos != null)
            _mensajeErrorProductos()
          else if (_componentesCombo.isEmpty)
            _mensajeSinComponentes()
          else
            ...List.generate(
              _componentesCombo.length,
              (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index ==
                            _componentesCombo.length -
                                1
                        ? 0
                        : 14,
                  ),
                  child: _tarjetaComponente(
                    componente:
                        _componentesCombo[index],
                    index: index,
                    esCelular: esCelular,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _mensajeErrorProductos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.redAccent.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            _errorProductos!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                _cargarProductosDisponibles,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Reintentar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensajeSinComponentes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: ColoresApp.textoSecundario,
          ),
          SizedBox(height: 10),
          Text(
            'Todavía no hay componentes.',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Agrega los productos que incluye este combo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaComponente({
    required _ComponenteComboEditable componente,
    required int index,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius:
            BorderRadius.circular(18),
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
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColoresApp.principal
                      .withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  componente.nombreController.text
                          .trim()
                          .isEmpty
                      ? 'Componente ${index + 1}'
                      : componente
                          .nombreController.text
                          .trim(),
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Subir',
                onPressed: index > 0
                    ? () {
                        _moverComponenteArriba(
                          index,
                        );
                      }
                    : null,
                icon: const Icon(
                  Icons.arrow_upward_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Bajar',
                onPressed:
                    index <
                            _componentesCombo.length -
                                1
                        ? () {
                            _moverComponenteAbajo(
                              index,
                            );
                          }
                        : null,
                icon: const Icon(
                  Icons.arrow_downward_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar componente',
                onPressed: () {
                  _eliminarComponente(index);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (esCelular)
            Column(
              children: [
                _campo(
                  controller:
                      componente.nombreController,
                  etiqueta:
                      'Nombre del componente',
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                _selectorProductoPredeterminado(
                  componente,
                ),
                const SizedBox(height: 12),
                _campo(
                  controller:
                      componente.cantidadController,
                  etiqueta: 'Cantidad',
                  keyboardType:
                      TextInputType.number,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _campo(
                    controller: componente
                        .nombreController,
                    etiqueta:
                        'Nombre del componente',
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child:
                      _selectorProductoPredeterminado(
                    componente,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: _campo(
                    controller: componente
                        .cantidadController,
                    etiqueta: 'Cantidad',
                    keyboardType:
                        TextInputType.number,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          SwitchListTile(
            value:
                componente.permiteSustitucion,
            activeColor: ColoresApp.principal,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Permitir sustituciones',
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text(
              'El producto predeterminado tendrá recargo cero.',
              style: TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                componente.permiteSustitucion =
                    value;
              });
            },
          ),
          if (componente.permiteSustitucion) ...[
            const SizedBox(height: 8),
            _seccionSustituciones(
              componente,
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectorProductoPredeterminado(
    _ComponenteComboEditable componente,
  ) {
    ProductoVenta? valor =
        _productosDisponibles.where(
      (producto) {
        return producto.id ==
            componente.productoPredeterminado.id;
      },
    ).firstOrNull;

    valor ??= _productosDisponibles.isNotEmpty
        ? _productosDisponibles.first
        : null;

    if (valor != null &&
        valor.id !=
            componente.productoPredeterminado.id) {
      componente.productoPredeterminado =
          valor;
    }

    return DropdownButtonFormField<ProductoVenta>(
      value: valor,
      isExpanded: true,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      decoration: _decoracionCampo(
        'Producto predeterminado',
      ),
      items: _productosDisponibles.map(
        (producto) {
          return DropdownMenuItem(
            value: producto,
            child: Text(
              '${producto.nombre} · ${producto.categoria}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: (producto) {
        if (producto == null) return;

        setState(() {
          componente.productoPredeterminado =
              producto;

          final opcionesAEliminar =
              componente.opciones.where(
            (opcion) =>
                opcion.producto.id ==
                producto.id,
          ).toList();

          for (final opcion
              in opcionesAEliminar) {
            opcion.dispose();
          }

          componente.opciones.removeWhere(
            (opcion) =>
                opcion.producto.id ==
                producto.id,
          );
        });
      },
    );
  }

  Widget _seccionSustituciones(
    _ComponenteComboEditable componente,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sustituciones permitidas',
                  style: TextStyle(
                    color:
                        ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _agregarSustitucion(
                    componente,
                  );
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Agregar',
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      ColoresApp.principal,
                ),
              ),
            ],
          ),
          if (componente.opciones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10,
              ),
              child: Text(
                'No hay sustituciones configuradas.',
                style: TextStyle(
                  color:
                      ColoresApp.textoSecundario,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...List.generate(
              componente.opciones.length,
              (index) {
                final opcion =
                    componente.opciones[index];

                return Container(
                  margin: const EdgeInsets.only(
                    top: 9,
                  ),
                  padding:
                      const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: ColoresApp
                        .fondoSecundario,
                    borderRadius:
                        BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              opcion.producto.nombre,
                              style: const TextStyle(
                                color: ColoresApp
                                    .textoPrincipal,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opcion.producto
                                  .categoria,
                              style: const TextStyle(
                                color: ColoresApp
                                    .textoSecundario,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 125,
                        child: _campo(
                          controller: opcion
                              .recargoController,
                          etiqueta: 'Recargo',
                          prefijo: '\$ ',
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            'Eliminar sustitución',
                        onPressed: () {
                          _eliminarSustitucion(
                            componente,
                            index,
                          );
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _acciones() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius:
            const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  ColoresApp.textoPrincipal,
              side: BorderSide(
                color:
                    Colors.white.withOpacity(0.13),
              ),
            ),
            child: const Text(
              'Cancelar',
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed:
                _cargandoProductos && _esCombo
                    ? null
                    : _guardar,
            icon: const Icon(
              Icons.save_rounded,
            ),
            label: const Text(
              'Guardar',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  ColoresApp.principal,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracionCampo(
    String etiqueta, {
    String? prefijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      prefixText: prefijo,
      labelStyle: const TextStyle(
        color: ColoresApp.textoSecundario,
      ),
      prefixStyle: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      filled: true,
      fillColor: ColoresApp.fondoSecundario,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: ColoresApp.principal,
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    TextInputType? keyboardType,
    String? prefijo,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
      ),
      decoration: _decoracionCampo(
        etiqueta,
        prefijo: prefijo,
      ),
    );
  }
}

class _ComponenteComboEditable {
  final int id;
  final TextEditingController nombreController;
  final TextEditingController cantidadController;

  ProductoVenta productoPredeterminado;
  bool permiteSustitucion;
  bool obligatorio;

  final List<_OpcionComboEditable> opciones;

  _ComponenteComboEditable({
    required this.id,
    required String nombreInicial,
    required this.productoPredeterminado,
    required int cantidadInicial,
    required this.permiteSustitucion,
    required this.obligatorio,
    required List<_OpcionComboEditable> opciones,
  })  : nombreController = TextEditingController(
          text: nombreInicial,
        ),
        cantidadController =
            TextEditingController(
          text: '$cantidadInicial',
        ),
        opciones =
            List<_OpcionComboEditable>.from(
          opciones,
        );

  factory _ComponenteComboEditable.desdeModelo(
    ComponenteCombo componente,
  ) {
    return _ComponenteComboEditable(
      id: componente.id,
      nombreInicial:
          componente.nombreComponente,
      productoPredeterminado:
          componente.productoPredeterminado,
      cantidadInicial: componente.cantidad,
      permiteSustitucion:
          componente.permiteSustitucion,
      obligatorio: componente.obligatorio,
      opciones: componente.opciones
          .map(
            (opcion) => _OpcionComboEditable(
              id: opcion.id,
              producto: opcion.producto,
              recargoInicial: opcion.recargo,
            ),
          )
          .toList(),
    );
  }

  void dispose() {
    nombreController.dispose();
    cantidadController.dispose();

    for (final opcion in opciones) {
      opcion.dispose();
    }
  }
}

class _OpcionComboEditable {
  final int id;
  final ProductoVenta producto;
  final TextEditingController recargoController;

  _OpcionComboEditable({
    required this.id,
    required this.producto,
    required double recargoInicial,
  }) : recargoController =
            TextEditingController(
          text: recargoInicial.toStringAsFixed(2),
        );

  void dispose() {
    recargoController.dispose();
  }
}

class _ResultadoNuevaSustitucion {
  final ProductoVenta producto;
  final double recargo;

  const _ResultadoNuevaSustitucion({
    required this.producto,
    required this.recargo,
  });
}

class _DialogoNuevaSustitucion
    extends StatefulWidget {
  final List<ProductoVenta> productos;

  const _DialogoNuevaSustitucion({
    required this.productos,
  });

  @override
  State<_DialogoNuevaSustitucion> createState() =>
      _DialogoNuevaSustitucionState();
}

class _DialogoNuevaSustitucionState
    extends State<_DialogoNuevaSustitucion> {
  late ProductoVenta _producto;
  final TextEditingController
      _recargoController =
      TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    _producto = widget.productos.first;
  }

  @override
  void dispose() {
    _recargoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final recargo = double.tryParse(
          _recargoController.text
              .trim()
              .replaceAll(',', '.'),
        ) ??
        -1;

    if (recargo < 0) {
      return;
    }

    Navigator.pop(
      context,
      _ResultadoNuevaSustitucion(
        producto: _producto,
        recargo: recargo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColoresApp.superficie,
      title: const Text(
        'Nueva sustitución',
        style: TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProductoVenta>(
              value: _producto,
              isExpanded: true,
              dropdownColor: ColoresApp.superficie,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
              ),
              decoration: InputDecoration(
                labelText: 'Producto',
                labelStyle: const TextStyle(
                  color:
                      ColoresApp.textoSecundario,
                ),
                filled: true,
                fillColor:
                    ColoresApp.fondoSecundario,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              items: widget.productos.map(
                (producto) {
                  return DropdownMenuItem(
                    value: producto,
                    child: Text(
                      '${producto.nombre} · ${producto.categoria}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged: (producto) {
                if (producto == null) return;

                setState(() {
                  _producto = producto;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _recargoController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
              ),
              decoration: InputDecoration(
                labelText: 'Recargo',
                prefixText: '\$ ',
                labelStyle: const TextStyle(
                  color:
                      ColoresApp.textoSecundario,
                ),
                prefixStyle: const TextStyle(
                  color:
                      ColoresApp.textoPrincipal,
                ),
                filled: true,
                fillColor:
                    ColoresApp.fondoSecundario,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cancelar',
          ),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                ColoresApp.principal,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Agregar',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

extension _PrimerElementoONull<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}