import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../widgets/produccion_supabase.dart';

class PaginaProduccion extends StatefulWidget {
  final Usuario usuario;

  const PaginaProduccion({super.key, required this.usuario});

  @override
  State<PaginaProduccion> createState() => _PaginaProduccionState();
}

class _PaginaProduccionState extends State<PaginaProduccion> {
  List<ProductoProduccion> _productos = [];
  List<ProduccionHistorial> _producciones = [];

  bool _cargando = true;
  bool _procesando = false;

  String _busqueda = '';
  String _busquedaHistorial = '';

  int _ingredientesCriticos = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
      });
    }

    try {
      final resultados = await Future.wait<dynamic>([
        ProduccionSupabase.obtenerProductos(),
        ProduccionSupabase.obtenerTotalIngredientesCriticos(),
        ProduccionSupabase.obtenerProduccionesRecientes(),
      ]);

      if (!mounted) return;

      setState(() {
        _productos = resultados[0] as List<ProductoProduccion>;

        _ingredientesCriticos = resultados[1] as int;

        _producciones = resultados[2] as List<ProduccionHistorial>;

        _cargando = false;
        _procesando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _procesando = false;
      });

      _mostrarMensaje(
        'Error cargando producción: ${_limpiarError(e)}',
        esError: true,
      );
    }
  }

  List<ProductoProduccion> get _productosFiltrados {
    final texto = _busqueda.trim().toLowerCase();

    if (texto.isEmpty) {
      return _productos;
    }

    return _productos.where((producto) {
      return producto.nombre.toLowerCase().contains(texto) ||
          producto.categoria.toLowerCase().contains(texto);
    }).toList();
  }

  List<ProduccionHistorial> get _produccionesFiltradas {
    final texto = _busquedaHistorial.trim().toLowerCase();

    if (texto.isEmpty) {
      return _producciones;
    }

    return _producciones.where((produccion) {
      return produccion.productoNombre.toLowerCase().contains(texto) ||
          produccion.productoCategoria.toLowerCase().contains(texto) ||
          produccion.usuarioNombre.toLowerCase().contains(texto) ||
          produccion.id.toString().contains(texto);
    }).toList();
  }

  int get _productosBajos {
    return _productos
        .where((producto) => producto.stockActual <= producto.stockMinimo)
        .length;
  }

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
  }

  String _limpiarError(Object error) {
    var mensaje = error.toString();

    mensaje = mensaje.replaceFirst('Exception: ', '');

    return mensaje;
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(
            color: esError ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: esError ? Colors.redAccent : ColoresApp.principal,
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

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.roundToDouble()) {
      return cantidad.toStringAsFixed(0);
    }

    return cantidad.toStringAsFixed(3);
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  Future<void> _verReceta(ProductoProduccion producto) async {
    try {
      final receta = await ProduccionSupabase.obtenerRecetaProducto(
        producto.id,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          final esCelular = MediaQuery.of(context).size.width < 760;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: esCelular ? double.infinity : 760,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.86,
                maxWidth: MediaQuery.of(context).size.width * 0.94,
              ),
              padding: EdgeInsets.all(esCelular ? 16 : 20),
              decoration: BoxDecoration(
                color: ColoresApp.superficie,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                            separatorBuilder: (_, __) {
                              return const SizedBox(height: 12);
                            },
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
                                                  color: ColoresApp
                                                      .textoSecundario,
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
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error cargando receta: ${_limpiarError(e)}',
        esError: true,
      );
    }
  }

  Future<void> _producir(ProductoProduccion producto) async {
    try {
      final receta = await ProduccionSupabase.obtenerRecetaProducto(
        producto.id,
      );

      if (!mounted) return;

      if (receta.isEmpty) {
        _mostrarMensaje('Este producto no tiene receta.', esError: true);
        return;
      }

      final cantidadController = TextEditingController();

      final observacionController = TextEditingController();

      double cantidadActual = 0;

      final resultado = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              final ancho = MediaQuery.of(context).size.width;

              final alto = MediaQuery.of(context).size.height;

              final esCelular = ancho < 760;

              final existeStockInsuficiente = receta.any((insumo) {
                final consumo = insumo.consumoPara(cantidadActual);

                return consumo > insumo.stockActual;
              });

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
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                      const SizedBox(height: 14),
                      TextField(
                        controller: cantidadController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                        ),
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
                          final cantidad =
                              double.tryParse(
                                value.trim().replaceAll(',', '.'),
                              ) ??
                              0;

                          setLocalState(() {
                            cantidadActual = cantidad;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: observacionController,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                        ),
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
                          'Consumo estimado de materias primas',
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
                          separatorBuilder: (_, __) {
                            return const SizedBox(height: 12);
                          },
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
                      if (existeStockInsuficiente)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.35),
                            ),
                          ),
                          child: const Text(
                            'No existe suficiente stock para registrar esta producción.',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      _botonesDialogo(
                        esCelular: esCelular,
                        textoPrincipal: 'Registrar',
                        habilitado:
                            cantidadActual > 0 && !existeStockInsuficiente,
                        onCancelar: () {
                          Navigator.pop(context);
                        },
                        onAceptar: () {
                          final cantidad = double.tryParse(
                            cantidadController.text.trim().replaceAll(',', '.'),
                          );

                          if (cantidad == null || cantidad <= 0) {
                            return;
                          }

                          Navigator.pop(context, {
                            'cantidad': cantidad,
                            'observacion': observacionController.text.trim(),
                          });
                        },
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

      _mostrarMensaje(
        'Error registrando producción: ${_limpiarError(e)}',
        esError: true,
      );
    }
  }

  Future<void> _corregirProduccion(ProduccionHistorial produccion) async {
    final cantidadController = TextEditingController(
      text: _formatearCantidad(produccion.cantidadProducida),
    );

    final motivoController = TextEditingController();

    final observacionController = TextEditingController(
      text: produccion.observacion,
    );

    double cantidadNueva = produccion.cantidadProducida;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final ancho = MediaQuery.of(context).size.width;

            final esCelular = ancho < 760;

            final diferencia = cantidadNueva - produccion.cantidadProducida;

            final cantidadValida = cantidadNueva > 0 && diferencia != 0;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: esCelular ? ancho * 0.94 : 620,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.90,
                  maxWidth: ancho * 0.94,
                ),
                padding: EdgeInsets.all(esCelular ? 16 : 20),
                decoration: BoxDecoration(
                  color: ColoresApp.superficie,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Corregir producción #${produccion.id}',
                              style: TextStyle(
                                color: ColoresApp.textoPrincipal,
                                fontSize: esCelular ? 21 : 24,
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
                      ),
                      const SizedBox(height: 6),
                      Text(
                        produccion.productoNombre,
                        style: const TextStyle(
                          color: ColoresApp.principal,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ColoresApp.fondoSecundario,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 10,
                          children: [
                            _datoCorreccion(
                              'Cantidad actual',
                              _formatearCantidad(produccion.cantidadProducida),
                            ),
                            _datoCorreccion(
                              'Cantidad original',
                              _formatearCantidad(produccion.cantidadOriginal),
                            ),
                            _datoCorreccion(
                              'Registrado por',
                              produccion.usuarioNombre,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cantidadController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cantidad producida correcta',
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
                          final cantidad =
                              double.tryParse(
                                value.trim().replaceAll(',', '.'),
                              ) ??
                              0;

                          setLocalState(() {
                            cantidadNueva = cantidad;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (diferencia != 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: diferencia > 0
                                ? const Color(0xFF00A896).withOpacity(0.12)
                                : const Color(0xFFFFA726).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            diferencia > 0
                                ? 'Se agregarán ${_formatearCantidad(diferencia)} unidades al producto y se descontarán materias primas adicionales.'
                                : 'Se retirarán ${_formatearCantidad(diferencia.abs())} unidades del producto y se devolverán las materias primas correspondientes.',
                            style: TextStyle(
                              color: diferencia > 0
                                  ? const Color(0xFF00A896)
                                  : const Color(0xFFFFA726),
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: motivoController,
                        maxLines: 2,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Motivo de la corrección',
                          hintText:
                              'Ejemplo: se registró una cantidad incorrecta',
                          labelStyle: const TextStyle(
                            color: ColoresApp.textoSecundario,
                          ),
                          hintStyle: const TextStyle(
                            color: ColoresApp.textoSecundario,
                          ),
                          filled: true,
                          fillColor: ColoresApp.fondoSecundario,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: observacionController,
                        maxLines: 2,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Observación actualizada',
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
                      const SizedBox(height: 18),
                      _botonesDialogo(
                        esCelular: esCelular,
                        textoPrincipal: 'Guardar corrección',
                        habilitado: cantidadValida,
                        onCancelar: () {
                          Navigator.pop(context);
                        },
                        onAceptar: () {
                          final cantidad = double.tryParse(
                            cantidadController.text.trim().replaceAll(',', '.'),
                          );

                          if (cantidad == null ||
                              cantidad <= 0 ||
                              cantidad == produccion.cantidadProducida) {
                            return;
                          }

                          if (motivoController.text.trim().isEmpty) {
                            return;
                          }

                          Navigator.pop(context, {
                            'cantidad': cantidad,
                            'motivo': motivoController.text.trim(),
                            'observacion': observacionController.text.trim(),
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    cantidadController.dispose();
    motivoController.dispose();
    observacionController.dispose();

    if (resultado == null) return;

    final confirmado = await _confirmarCorreccion(
      produccion: produccion,
      cantidadNueva: resultado['cantidad'] as double,
    );

    if (!confirmado || !mounted) return;

    setState(() {
      _procesando = true;
    });

    try {
      await ProduccionSupabase.corregirProduccion(
        produccionId: produccion.id,
        cantidadNueva: resultado['cantidad'] as double,
        usuarioLogin: widget.usuario.usuario,
        motivo: resultado['motivo'] as String,
        observacionNueva: resultado['observacion'] as String,
      );

      if (!mounted) return;

      _mostrarMensaje('Producción corregida correctamente.');

      await _cargar();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _procesando = false;
      });

      _mostrarMensaje(
        'Error corrigiendo producción: ${_limpiarError(e)}',
        esError: true,
      );
    }
  }

  Future<bool> _confirmarCorreccion({
    required ProduccionHistorial produccion,
    required double cantidadNueva,
  }) async {
    final diferencia = cantidadNueva - produccion.cantidadProducida;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColoresApp.superficie,
          title: const Text(
            'Confirmar corrección',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            diferencia > 0
                ? 'La producción cambiará de ${_formatearCantidad(produccion.cantidadProducida)} a ${_formatearCantidad(cantidadNueva)}. Se descontarán materias primas adicionales.'
                : 'La producción cambiará de ${_formatearCantidad(produccion.cantidadProducida)} a ${_formatearCantidad(cantidadNueva)}. Se devolverán materias primas al inventario.',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: ColoresApp.textoSecundario),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.principal,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  Widget _botonesDialogo({
    required bool esCelular,
    required String textoPrincipal,
    required bool habilitado,
    required VoidCallback onCancelar,
    required VoidCallback onAceptar,
  }) {
    final cancelar = OutlinedButton(
      onPressed: onCancelar,
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text('Cancelar'),
    );

    final aceptar = ElevatedButton(
      onPressed: habilitado ? onAceptar : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        disabledBackgroundColor: ColoresApp.principal.withOpacity(0.25),
        disabledForegroundColor: Colors.black.withOpacity(0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        textoPrincipal,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );

    if (esCelular) {
      return Column(
        children: [
          SizedBox(width: double.infinity, height: 46, child: aceptar),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 44, child: cancelar),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: SizedBox(height: 46, child: cancelar)),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 46, child: aceptar)),
      ],
    );
  }

  Widget _datoCorreccion(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producción'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _procesando ? null : _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
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
                      productos: _productosFiltrados,
                      esCelular: esCelular,
                    ),
                    const SizedBox(height: 18),
                    _panelHistorial(
                      producciones: _produccionesFiltradas,
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
        final columnas = ancho < 430 ? 2 : 4;
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
              'Materias primas críticas',
              '$_ingredientesCriticos',
              Colors.redAccent,
            ),
            _tarjetaResumen(
              'Producciones recientes',
              '${_producciones.length}',
              const Color(0xFF00A896),
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
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
            'Cada producción descuenta materias primas y suma producto terminado.',
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
              hintStyle: const TextStyle(color: ColoresApp.textoSecundario),
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
                child: CircularProgressIndicator(color: ColoresApp.principal),
              ),
            )
          else if (productos.isEmpty)
            _mensajeVacio('No hay productos listos para producción.')
          else
            ListView.separated(
              itemCount: productos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                return _tarjetaProducto(productos[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _panelHistorial({
    required List<ProduccionHistorial> producciones,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 20),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Historial y correcciones',
                  style: TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: esCelular ? 24 : 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar historial',
                onPressed: _procesando ? null : _cargar,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: ColoresApp.principal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes corregir una producción registrada incorrectamente sin eliminar el historial.',
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
                _busquedaHistorial = value;
              });
            },
            style: const TextStyle(color: ColoresApp.textoPrincipal),
            decoration: InputDecoration(
              hintText: 'Buscar por producto, usuario o número...',
              hintStyle: const TextStyle(color: ColoresApp.textoSecundario),
              prefixIcon: const Icon(
                Icons.history_rounded,
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
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: ColoresApp.principal),
              ),
            )
          else if (producciones.isEmpty)
            _mensajeVacio('No existen producciones registradas.')
          else
            ListView.separated(
              itemCount: producciones.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                return _tarjetaHistorial(producciones[index]);
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

  Widget _tarjetaHistorial(ProduccionHistorial produccion) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 760;

        final contenido = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ColoresApp.principal.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: ColoresApp.principal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produccion.productoNombre,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${produccion.productoCategoria} • Producción #${produccion.id}',
                        style: const TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (produccion.corregida)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CORREGIDA',
                      style: TextStyle(
                        color: Color(0xFFFFA726),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chipDatoItem(
                  'Cantidad',
                  _formatearCantidad(produccion.cantidadProducida),
                ),
                if (produccion.fueModificada)
                  _chipDatoItem(
                    'Original',
                    _formatearCantidad(produccion.cantidadOriginal),
                  ),
                _chipDatoItem('Usuario', produccion.usuarioNombre),
                _chipDatoItem(
                  'Fecha',
                  _formatearFecha(produccion.fechaRegistro),
                ),
              ],
            ),
            if (produccion.observacion.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Observación: ${produccion.observacion}',
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
            if (produccion.fechaUltimaCorreccion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Última corrección: ${_formatearFecha(produccion.fechaUltimaCorreccion!)}'
                '${produccion.usuarioUltimaCorreccion.isEmpty ? '' : ' por ${produccion.usuarioUltimaCorreccion}'}',
                style: const TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );

        if (compacto) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColoresApp.fondoSecundario,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                contenido,
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: _botonCorregir(produccion),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSecundario,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(child: contenido),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                height: 42,
                child: _botonCorregir(produccion),
              ),
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
                colors: [ColoresApp.principalClaro, ColoresApp.principal],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bakery_dining_rounded, color: Colors.black),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        SizedBox(width: 150, height: 42, child: _botonProducir(producto)),
        const SizedBox(height: 8),
        SizedBox(width: 150, height: 42, child: _botonVerReceta(producto)),
      ],
    );
  }

  Widget _botonProducir(ProductoProduccion producto) {
    return ElevatedButton(
      onPressed: _procesando
          ? null
          : () {
              _producir(producto);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Producir',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _botonVerReceta(ProductoProduccion producto) {
    return OutlinedButton(
      onPressed: () {
        _verReceta(producto);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Ver receta',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _botonCorregir(ProduccionHistorial produccion) {
    return OutlinedButton.icon(
      onPressed: _procesando
          ? null
          : () {
              _corregirProduccion(produccion);
            },
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text(
        'Corregir',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.principal,
        side: BorderSide(color: ColoresApp.principal.withOpacity(0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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

  Widget _mensajeVacio(String mensaje) {
    return Container(
      width: double.infinity,
      height: 180,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 15),
      ),
    );
  }
}
