import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import 'productos_supabase.dart';
import 'ventas_modelos.dart';

part 'dialogo_producto_venta/ui_dialogo_producto_venta.dart';
part 'dialogo_producto_venta/modelos_combo_dialogo_producto.dart';

class DialogoProductoVenta extends StatefulWidget {
  final ProductoVenta? producto;

  const DialogoProductoVenta({super.key, this.producto});

  @override
  State<DialogoProductoVenta> createState() => _DialogoProductoVentaState();
}

class _DialogoProductoVentaState extends State<DialogoProductoVenta> {
  late final TextEditingController _nombreController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _precioController;
  late final TextEditingController _cantidadSaboresController;

  late SeccionVenta _seccion;
  late bool _requiereSabores;

  bool _cargandoProductos = true;
  String? _errorProductos;

  List<ProductoVenta> _productosDisponibles = [];

  List<String> _categoriasDisponibles = [];

  String? _categoriaSeleccionada;

  bool _crearNuevaCategoria = false;

  final List<_ComponenteComboEditable> _componentesCombo = [];

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

    _cantidadSaboresController = TextEditingController(
      text: widget.producto != null
          ? '${widget.producto!.cantidadSabores}'
          : '0',
    );

    _seccion = widget.producto?.seccion ?? SeccionVenta.individuales;

    _requiereSabores = widget.producto?.requiereSabores ?? false;

    final categoriaInicial = widget.producto?.categoria.trim() ?? '';

    if (categoriaInicial.isNotEmpty) {
      _categoriaSeleccionada = categoriaInicial;
    }

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
    final componentes = widget.producto?.componentesCombo ?? const [];

    for (final componente in componentes) {
      _componentesCombo.add(_ComponenteComboEditable.desdeModelo(componente));
    }
  }

  Future<void> _cargarProductosDisponibles() async {
    try {
      final productos = await ProductosSupabase.obtenerProductos();

      final categorias = await ProductosSupabase.obtenerCategorias();

      if (!mounted) return;

      final productoActualId = widget.producto?.id ?? 0;

      final disponibles = productos.where((producto) {
        if (producto.id == productoActualId) {
          return false;
        }

        /*
         * Los combos anidados todavía no se permiten.
         * El inventario descuenta directamente los
         * productos reales elegidos en cada componente.
         */
        return producto.seccion != SeccionVenta.combos;
      }).toList();

      disponibles.sort((a, b) {
        final comparacionCategoria = a.categoria.toLowerCase().compareTo(
          b.categoria.toLowerCase(),
        );

        if (comparacionCategoria != 0) {
          return comparacionCategoria;
        }

        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });

      final categoriasFinales = List<String>.from(categorias);

      final actual = widget.producto?.categoria.trim() ?? '';

      if (actual.isNotEmpty &&
          !categoriasFinales.any(
            (categoria) => categoria.toLowerCase() == actual.toLowerCase(),
          )) {
        categoriasFinales.add(actual);
      }

      categoriasFinales.sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );

      setState(() {
        _productosDisponibles = disponibles;

        _categoriasDisponibles = categoriasFinales;

        _cargandoProductos = false;
        _errorProductos = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoProductos = false;
        _errorProductos = 'No se pudieron cargar los productos: $e';
      });
    }
  }

  String _nombreSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return 'Individuales';

      case SeccionVenta.combos:
        return 'Combos';

      case SeccionVenta.uber:
        return 'Plataformas';
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

  void _agregarComponente() {
    if (_productosDisponibles.isEmpty) {
      _mostrarMensaje(
        'No existen productos disponibles para configurar el combo.',
      );

      return;
    }

    final productoInicial = _productosDisponibles.first;

    setState(() {
      _componentesCombo.add(
        _ComponenteComboEditable(
          id: 0,
          nombreInicial: 'Componente ${_componentesCombo.length + 1}',
          productoPredeterminado: productoInicial,
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
      final componente = _componentesCombo.removeAt(index);

      componente.dispose();
    });
  }

  void _moverComponenteArriba(int index) {
    if (index <= 0) return;

    setState(() {
      final componente = _componentesCombo.removeAt(index);

      _componentesCombo.insert(index - 1, componente);
    });
  }

  void _moverComponenteAbajo(int index) {
    if (index < 0 || index >= _componentesCombo.length - 1) {
      return;
    }

    setState(() {
      final componente = _componentesCombo.removeAt(index);

      _componentesCombo.insert(index + 1, componente);
    });
  }

  Future<void> _agregarSustitucion(_ComponenteComboEditable componente) async {
    final productosNoAgregados = _productosDisponibles.where((producto) {
      if (producto.id == componente.productoPredeterminado.id) {
        return false;
      }

      return !componente.opciones.any(
        (opcion) => opcion.producto.id == producto.id,
      );
    }).toList();

    if (productosNoAgregados.isEmpty) {
      _mostrarMensaje(
        'No quedan productos disponibles para agregar como sustitución.',
      );

      return;
    }

    final resultado = await showDialog<_ResultadoNuevaSustitucion>(
      context: context,
      builder: (_) => _DialogoNuevaSustitucion(productos: productosNoAgregados),
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

  void _eliminarSustitucion(_ComponenteComboEditable componente, int index) {
    setState(() {
      final opcion = componente.opciones.removeAt(index);

      opcion.dispose();
    });
  }

  List<ComponenteCombo>? _crearComponentesParaGuardar() {
    final resultado = <ComponenteCombo>[];

    for (int index = 0; index < _componentesCombo.length; index++) {
      final editable = _componentesCombo[index];

      final nombre = editable.nombreController.text.trim();

      final cantidad =
          int.tryParse(editable.cantidadController.text.trim()) ?? 0;

      if (nombre.isEmpty) {
        _mostrarMensaje('El componente ${index + 1} debe tener un nombre.');

        return null;
      }

      if (cantidad <= 0) {
        _mostrarMensaje('La cantidad de "$nombre" debe ser mayor a cero.');

        return null;
      }

      final opciones = <OpcionComponenteCombo>[];
      final productosUsados = <int>{};

      for (
        int opcionIndex = 0;
        opcionIndex < editable.opciones.length;
        opcionIndex++
      ) {
        final opcionEditable = editable.opciones[opcionIndex];

        final recargo =
            double.tryParse(
              opcionEditable.recargoController.text.trim().replaceAll(',', '.'),
            ) ??
            -1;

        if (recargo < 0) {
          _mostrarMensaje(
            'El recargo de ${opcionEditable.producto.nombre} debe ser cero o mayor.',
          );

          return null;
        }

        if (productosUsados.contains(opcionEditable.producto.id)) {
          continue;
        }

        productosUsados.add(opcionEditable.producto.id);

        opciones.add(
          OpcionComponenteCombo(
            id: opcionEditable.id,
            componenteId: editable.id,
            producto: opcionEditable.producto,
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
          productoPredeterminado: editable.productoPredeterminado,
          cantidad: cantidad,
          permiteSustitucion: editable.permiteSustitucion,
          obligatorio: editable.obligatorio,
          orden: index,
          activo: true,
          opciones: editable.permiteSustitucion ? opciones : const [],
        ),
      );
    }

    return resultado;
  }

  void _guardar() {
    final nombre = _nombreController.text.trim();

    final categoriaIngresada = _categoriaController.text.trim();

    String categoriaNormalizada = categoriaIngresada;

    for (final existente in _categoriasDisponibles) {
      if (existente.trim().toLowerCase() == categoriaIngresada.toLowerCase()) {
        categoriaNormalizada = existente.trim();

        break;
      }
    }

    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    final cantidadSabores =
        int.tryParse(_cantidadSaboresController.text.trim()) ?? 0;

    if (nombre.isEmpty) {
      _mostrarMensaje('Debes ingresar el nombre del producto.');

      return;
    }

    if (categoriaNormalizada.isEmpty) {
      _mostrarMensaje('Debes ingresar la categoría.');

      return;
    }

    if (precio == null || precio <= 0) {
      _mostrarMensaje('El precio debe ser mayor a cero.');

      return;
    }

    if (_requiereSabores && cantidadSabores <= 0) {
      _mostrarMensaje('La cantidad de sabores debe ser mayor a cero.');

      return;
    }

    List<ComponenteCombo> componentes = const [];

    if (_esCombo) {
      final componentesResultado = _crearComponentesParaGuardar();

      if (componentesResultado == null) {
        return;
      }

      componentes = componentesResultado;

      if (componentes.isEmpty) {
        _mostrarMensaje('Debes agregar al menos un componente al combo.');

        return;
      }
    }

    Navigator.pop(
      context,
      ProductoVenta(
        id: widget.producto?.id ?? 0,
        nombre: nombre,
        categoria: categoriaNormalizada,
        precio: precio,
        seccion: _seccion,

        requiereSabores: _esCombo ? false : _requiereSabores,

        cantidadSabores: _esCombo || !_requiereSabores ? 0 : cantidadSabores,

        controlaStock: _seccion == SeccionVenta.individuales,

        stockActual: widget.producto?.stockActual ?? 0,

        stockMinimo: widget.producto?.stockMinimo ?? 0,

        stockCritico: widget.producto?.stockCritico ?? 0,

        componentesCombo: componentes,
      ),
    );
  }

  void _actualizarEstado(VoidCallback accion) {
    if (!mounted) return;

    setState(accion);
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
        width: _esCombo ? 920 : 480,
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(esCelular ? 16 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _datosPrincipales(esCelular),
                    if (_esCombo) ...[
                      const SizedBox(height: 22),
                      _configuracionCombo(esCelular),
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
}
