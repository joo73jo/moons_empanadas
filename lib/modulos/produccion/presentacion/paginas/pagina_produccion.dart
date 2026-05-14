import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../widgets/produccion_supabase.dart';

class PaginaProduccion extends StatefulWidget {
  final Usuario usuario;

  const PaginaProduccion({
    super.key,
    required this.usuario,
  });

  @override
  State<PaginaProduccion> createState() => _PaginaProduccionState();
}

class _PaginaProduccionState extends State<PaginaProduccion> {
  List<ProductoProduccion> _productos = [];
  bool _cargando = true;
  bool _procesando = false;
  String _busqueda = '';
  int _ingredientesCriticos = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
    });

    try {
      final productos = await ProduccionSupabase.obtenerProductos();
      final ingredientesCriticos =
          await ProduccionSupabase.obtenerTotalIngredientesCriticos();

      if (!mounted) return;

      setState(() {
        _productos = productos;
        _ingredientesCriticos = ingredientesCriticos;
        _cargando = false;
        _procesando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _procesando = false;
      });
      _mostrarMensaje('Error cargando producción: $e');
    }
  }

  List<ProductoProduccion> get _productosFiltrados {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _productos;

    return _productos.where((producto) {
      return producto.nombre.toLowerCase().contains(q) ||
          producto.categoria.toLowerCase().contains(q);
    }).toList();
  }

  int get _productosBajos {
    return _productos.where((p) => p.stockActual <= p.stockMinimo).length;
  }

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
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

  Color _colorNivelProducto(ProductoProduccion producto) {
    switch (producto.nivelStock) {
      case 'critico':
        return Colors.redAccent;
      case 'minimo':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF00A896);
    }
  }

  String _textoNivelProducto(ProductoProduccion producto) {
    switch (producto.nivelStock) {
      case 'critico':
        return 'Crítico';
      case 'minimo':
        return 'Mínimo';
      default:
        return 'Normal';
    }
  }

  Future<void> _verReceta(ProductoProduccion producto) async {
    try {
      final receta = await ProduccionSupabase.obtenerRecetaProducto(producto.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 760,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              maxWidth: MediaQuery.of(context).size.width * 0.94,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColoresApp.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Receta • ${producto.nombre}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
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
                const SizedBox(height: 14),
                Expanded(
                  child: receta.isEmpty
                      ? const Center(
                          child: Text(
                            'Este producto no tiene receta.',
                            style: TextStyle(
                              color: ColoresApp.textoSecundario,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: receta.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final insumo = receta[index];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ColoresApp.fondoSecundario,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final compacto = constraints.maxWidth < 430;

                                  if (compacto) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          insumo.ingredienteNombre,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: ColoresApp.textoPrincipal,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          insumo.ingredienteCategoria,
                                          style: const TextStyle(
                                            color: ColoresApp.textoSecundario,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${insumo.cantidadPorUnidad.toStringAsFixed(3)} ${insumo.unidadMedida}',
                                          style: const TextStyle(
                                            color: ColoresApp.principal,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stock: ${insumo.stockActual.toStringAsFixed(3)}',
                                          style: const TextStyle(
                                            color: ColoresApp.textoSecundario,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              insumo.ingredienteNombre,
                                              style: const TextStyle(
                                                color:
                                                    ColoresApp.textoPrincipal,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              insumo.ingredienteCategoria,
                                              style: const TextStyle(
                                                color:
                                                    ColoresApp.textoSecundario,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${insumo.cantidadPorUnidad.toStringAsFixed(3)} ${insumo.unidadMedida}',
                                            style: const TextStyle(
                                              color: ColoresApp.principal,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Stock: ${insumo.stockActual.toStringAsFixed(3)}',
                                            style: const TextStyle(
                                              color:
                                                  ColoresApp.textoSecundario,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _mostrarMensaje('Error cargando receta: $e');
    }
  }

  Future<void> _producir(ProductoProduccion producto) async {
    final receta = await ProduccionSupabase.obtenerRecetaProducto(producto.id);

    if (!mounted) return;

    if (receta.isEmpty) {
      _mostrarMensaje('Este producto no tiene receta.');
      return;
    }

    final cantidadController = TextEditingController();
    final observacionController = TextEditingController();

    double cantidadActual = 0;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final ancho = MediaQuery.of(context).size.width;
            final alto = MediaQuery.of(context).size.height;
            final esCelular = ancho < 760;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: esCelular ? ancho * 0.94 : 820,
                constraints: BoxConstraints(
                  maxHeight: alto * 0.88,
                  maxWidth: ancho * 0.94,
                ),
                padding: EdgeInsets.all(esCelular ? 16 : 20),
                decoration: BoxDecoration(
                  color: ColoresApp.superficie,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Registrar producción • ${producto.nombre}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColoresApp.textoPrincipal,
                              fontSize: esCelular ? 21 : 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
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
                    const SizedBox(height: 14),
                    TextField(
                      controller: cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: ColoresApp.textoPrincipal),
                      decoration: InputDecoration(
                        labelText: 'Cantidad producida',
                        labelStyle: const TextStyle(
                          color: ColoresApp.textoSecundario,
                        ),
                        filled: true,
                        fillColor: ColoresApp.fondoSecundario,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (value) {
                        final cantidad = double.tryParse(value.trim()) ?? 0;
                        setLocalState(() {
                          cantidadActual = cantidad;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: observacionController,
                      style: const TextStyle(color: ColoresApp.textoPrincipal),
                      decoration: InputDecoration(
                        labelText: 'Observación',
                        labelStyle: const TextStyle(
                          color: ColoresApp.textoSecundario,
                        ),
                        filled: true,
                        fillColor: ColoresApp.fondoSecundario,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Consumo estimado de ingredientes',
                        style: TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: receta.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final insumo = receta[index];
                          final consumo = insumo.consumoPara(cantidadActual);
                          final restante = insumo.stockActual - consumo;
                          final alcanza = restante >= 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ColoresApp.fondoSecundario,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compacto = constraints.maxWidth < 430;

                                if (compacto) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        insumo.ingredienteNombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: ColoresApp.textoPrincipal,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Disponible: ${insumo.stockActual.toStringAsFixed(3)} ${insumo.unidadMedida}',
                                        style: const TextStyle(
                                          color: ColoresApp.textoSecundario,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Consume: ${consumo.toStringAsFixed(3)} ${insumo.unidadMedida}',
                                        style: const TextStyle(
                                          color: ColoresApp.principal,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Resta: ${restante.toStringAsFixed(3)}',
                                        style: TextStyle(
                                          color: alcanza
                                              ? const Color(0xFF00A896)
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            insumo.ingredienteNombre,
                                            style: const TextStyle(
                                              color:
                                                  ColoresApp.textoPrincipal,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Disponible: ${insumo.stockActual.toStringAsFixed(3)} ${insumo.unidadMedida}',
                                            style: const TextStyle(
                                              color:
                                                  ColoresApp.textoSecundario,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Consume: ${consumo.toStringAsFixed(3)} ${insumo.unidadMedida}',
                                          style: const TextStyle(
                                            color: ColoresApp.principal,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Resta: ${restante.toStringAsFixed(3)}',
                                          style: TextStyle(
                                            color: alcanza
                                                ? const Color(0xFF00A896)
                                                : Colors.redAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    esCelular
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final cantidad = double.tryParse(
                                      cantidadController.text.trim(),
                                    );

                                    if (cantidad == null || cantidad <= 0) {
                                      return;
                                    }

                                    Navigator.pop(
                                      context,
                                      {
                                        'cantidad': cantidad,
                                        'observacion':
                                            observacionController.text.trim(),
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColoresApp.principal,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Registrar',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        ColoresApp.textoPrincipal,
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
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        ColoresApp.textoPrincipal,
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
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final cantidad = double.tryParse(
                                        cantidadController.text.trim(),
                                      );

                                      if (cantidad == null || cantidad <= 0) {
                                        return;
                                      }

                                      Navigator.pop(
                                        context,
                                        {
                                          'cantidad': cantidad,
                                          'observacion':
                                              observacionController.text.trim(),
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ColoresApp.principal,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Registrar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    cantidadController.dispose();
    observacionController.dispose();

    if (resultado == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await ProduccionSupabase.registrarProduccion(
        producto: producto,
        cantidadProducida: resultado['cantidad'] as double,
        usuarioLogin: widget.usuario.usuario,
        observacion: resultado['observacion'] as String,
      );

      if (!mounted) return;
      _mostrarMensaje('Producción registrada correctamente.');
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _procesando = false;
      });
      _mostrarMensaje('Error registrando producción: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = _productosFiltrados;
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producción'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: esCelular ? 10 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: esCelular ? 110 : 220),
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
        child: RefreshIndicator(
          color: ColoresApp.principal,
          backgroundColor: ColoresApp.superficie,
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(esCelular ? 14 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  children: [
                    _resumenSuperior(),
                    const SizedBox(height: 18),
                    _panelProduccion(
                      productos: productos,
                      esCelular: esCelular,
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

  Widget _resumenSuperior() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho < 430 ? 2 : 3;
        final alto = ancho < 430 ? 126.0 : 112.0;

        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: (ancho / columnas) / alto,
          children: [
            _tarjetaResumen(
              'Productos con receta',
              '${_productos.length}',
              ColoresApp.principal,
            ),
            _tarjetaResumen(
              'Stock bajo',
              '$_productosBajos',
              const Color(0xFFFFA726),
            ),
            _tarjetaResumen(
              'Ingredientes críticos',
              '$_ingredientesCriticos',
              Colors.redAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _panelProduccion({
    required List<ProductoProduccion> productos,
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
            'Producción de productos',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cada producción descuenta ingredientes y suma producto terminado',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                _busqueda = value;
              });
            },
            style: const TextStyle(color: ColoresApp.textoPrincipal),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: const TextStyle(
                color: ColoresApp.textoSecundario,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: ColoresApp.principal,
              ),
              filled: true,
              fillColor: ColoresApp.fondoSecundario,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_cargando)
            const SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(
                  color: ColoresApp.principal,
                ),
              ),
            )
          else if (productos.isEmpty)
            Container(
              width: double.infinity,
              height: 180,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No hay productos listos para producción.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 15,
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: productos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final producto = productos[index];
                return _tarjetaProducto(producto);
              },
            ),
        ],
      ),
    );
  }

  Widget _tarjetaProducto(ProductoProduccion producto) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSecundario,
            borderRadius: BorderRadius.circular(18),
          ),
          child: compacto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezadoProducto(producto),
                    const SizedBox(height: 12),
                    _datosProducto(producto),
                    const SizedBox(height: 14),
                    _accionesProducto(producto, compacto: true),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            ColoresApp.principalClaro,
                            ColoresApp.principal,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bakery_dining_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _encabezadoProducto(producto, conIcono: false),
                          const SizedBox(height: 8),
                          _datosProducto(producto),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _accionesProducto(producto, compacto: false),
                  ],
                ),
        );
      },
    );
  }

  Widget _encabezadoProducto(
    ProductoProduccion producto, {
    bool conIcono = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conIcono) ...[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ColoresApp.principalClaro,
                  ColoresApp.principal,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bakery_dining_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                producto.categoria,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _colorNivelProducto(producto).withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _textoNivelProducto(producto).toUpperCase(),
            style: TextStyle(
              color: _colorNivelProducto(producto),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datosProducto(ProductoProduccion producto) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chipDatoItem('Stock', producto.stockActual.toStringAsFixed(3)),
        _chipDatoItem('Mínimo', producto.stockMinimo.toStringAsFixed(3)),
        _chipDatoItem('Crítico', producto.stockCritico.toStringAsFixed(3)),
      ],
    );
  }

  Widget _accionesProducto(
    ProductoProduccion producto, {
    required bool compacto,
  }) {
    if (compacto) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _botonProducir(producto),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _botonVerReceta(producto),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 42,
          child: _botonProducir(producto),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          height: 42,
          child: _botonVerReceta(producto),
        ),
      ],
    );
  }

  Widget _botonProducir(ProductoProduccion producto) {
    return ElevatedButton(
      onPressed: _procesando ? null : () => _producir(producto),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Producir',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _botonVerReceta(ProductoProduccion producto) {
    return OutlinedButton(
      onPressed: () => _verReceta(producto),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Ver receta',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
              height: 1.15,
            ),
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipDatoItem(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: valor,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}