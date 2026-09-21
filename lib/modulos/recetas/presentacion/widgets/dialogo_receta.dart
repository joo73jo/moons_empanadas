import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import 'recetas_supabase.dart';

class DialogoReceta extends StatefulWidget {
  final ProductoReceta producto;
  final List<IngredienteRecetaDisponible> ingredientesDisponibles;
  final RecetaCompleta? recetaExistente;

  const DialogoReceta({
    super.key,
    required this.producto,
    required this.ingredientesDisponibles,
    required this.recetaExistente,
  });

  @override
  State<DialogoReceta> createState() => _DialogoRecetaState();
}

class _DialogoRecetaState extends State<DialogoReceta> {
  late final TextEditingController _nombreRecetaController;

  late List<RecetaDetalleItem> _detalles;

  late List<RecetaSubrecetaItem> _subrecetas;

  List<RecetaReferenciaDisponible> _recetasDisponibles = [];

  bool _cargandoRecetas = true;

  @override
  void initState() {
    super.initState();

    _nombreRecetaController = TextEditingController(
      text: widget.recetaExistente?.nombreReceta.isNotEmpty == true
          ? widget.recetaExistente!.nombreReceta
          : widget.producto.nombre,
    );

    _detalles = List<RecetaDetalleItem>.from(
      widget.recetaExistente?.detalles ?? const [],
    );

    _subrecetas = List<RecetaSubrecetaItem>.from(
      widget.recetaExistente?.subrecetas ?? const [],
    );

    _cargarRecetas();
  }

  Future<void> _cargarRecetas() async {
    try {
      final resultado = await RecetasSupabase.obtenerRecetasDisponibles(
        excluirProductoId: widget.producto.id,
      );

      if (!mounted) return;

      setState(() {
        _recetasDisponibles = resultado;

        _cargandoRecetas = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoRecetas = false;
      });

      _mensaje('No se pudieron cargar las recetas disponibles: $e');
    }
  }

  @override
  void dispose() {
    _nombreRecetaController.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
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

  Future<double?> _pedirCantidad({
    required String titulo,
    double? cantidadInicial,
  }) async {
    final controller = TextEditingController(
      text: cantidadInicial == null ? '' : cantidadInicial.toStringAsFixed(3),
    );

    final resultado = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: Text(
          titulo,
          style: const TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: ColoresApp.textoPrincipal),
          decoration: InputDecoration(
            labelText: 'Cantidad',
            filled: true,
            fillColor: ColoresApp.fondoSecundario,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );

              if (valor == null || valor <= 0) {
                return;
              }

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

    controller.dispose();

    return resultado;
  }

  Future<void> _agregarIngrediente() async {
    IngredienteRecetaDisponible? seleccionado;

    final cantidadController = TextEditingController();

    final resultado = await showDialog<RecetaDetalleItem>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            backgroundColor: ColoresApp.superficie,
            title: const Text(
              'Agregar ingrediente',
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<IngredienteRecetaDisponible>(
                    value: seleccionado,
                    isExpanded: true,
                    dropdownColor: ColoresApp.superficie,
                    decoration: InputDecoration(
                      labelText: 'Ingrediente',
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: widget.ingredientesDisponibles.map((ingrediente) {
                      return DropdownMenuItem(
                        value: ingrediente,
                        child: Text(
                          '${ingrediente.nombre} · ${ingrediente.unidadMedida}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setLocalState(() {
                        seleccionado = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    style: const TextStyle(color: ColoresApp.textoPrincipal),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final cantidad = double.tryParse(
                    cantidadController.text.trim().replaceAll(',', '.'),
                  );

                  if (seleccionado == null ||
                      cantidad == null ||
                      cantidad <= 0) {
                    return;
                  }

                  Navigator.pop(
                    context,
                    RecetaDetalleItem(
                      ingredienteId: seleccionado!.id,
                      ingredienteNombre: seleccionado!.nombre,
                      ingredienteCategoria: seleccionado!.categoria,
                      unidadMedida: seleccionado!.unidadMedida,
                      cantidad: cantidad,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    cantidadController.dispose();

    if (resultado == null || !mounted) {
      return;
    }

    if (_detalles.any(
      (item) => item.ingredienteId == resultado.ingredienteId,
    )) {
      _mensaje('Ese ingrediente ya está en la receta.');
      return;
    }

    setState(() {
      _detalles.add(resultado);
    });
  }

  Future<void> _agregarReceta() async {
    if (_cargandoRecetas) {
      return;
    }

    if (_recetasDisponibles.isEmpty) {
      _mensaje('No existen otras recetas disponibles.');
      return;
    }

    RecetaReferenciaDisponible? seleccionada = _recetasDisponibles.first;

    final cantidadController = TextEditingController(text: '1');

    final resultado = await showDialog<RecetaSubrecetaItem>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            backgroundColor: ColoresApp.superficie,
            title: const Text(
              'Agregar receta',
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<RecetaReferenciaDisponible>(
                    value: seleccionada,
                    isExpanded: true,
                    dropdownColor: ColoresApp.superficie,
                    decoration: InputDecoration(
                      labelText: 'Receta',
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: _recetasDisponibles.map((receta) {
                      return DropdownMenuItem(
                        value: receta,
                        child: Text(
                          '${receta.productoNombre} · ${receta.recetaNombre}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setLocalState(() {
                        seleccionada = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Cantidad de receta',
                      suffixText: 'porciones',
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    style: const TextStyle(color: ColoresApp.textoPrincipal),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final cantidad = double.tryParse(
                    cantidadController.text.trim().replaceAll(',', '.'),
                  );

                  if (seleccionada == null ||
                      cantidad == null ||
                      cantidad <= 0) {
                    return;
                  }

                  final receta = seleccionada!;

                  Navigator.pop(
                    context,
                    RecetaSubrecetaItem(
                      recetaHijaId: receta.recetaId,
                      productoHijoId: receta.productoId,
                      productoNombre: receta.productoNombre,
                      productoCategoria: receta.productoCategoria,
                      recetaNombre: receta.recetaNombre,
                      cantidad: cantidad,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    cantidadController.dispose();

    if (resultado == null || !mounted) {
      return;
    }

    if (_subrecetas.any(
      (item) => item.recetaHijaId == resultado.recetaHijaId,
    )) {
      _mensaje('Esa receta ya está incluida.');
      return;
    }

    setState(() {
      _subrecetas.add(resultado);
    });
  }

  Future<void> _editarIngrediente(int index) async {
    final actual = _detalles[index];

    final cantidad = await _pedirCantidad(
      titulo: 'Editar ${actual.ingredienteNombre}',
      cantidadInicial: actual.cantidad,
    );

    if (cantidad == null || !mounted) {
      return;
    }

    setState(() {
      _detalles[index] = actual.copyWith(cantidad: cantidad);
    });
  }

  Future<void> _editarSubreceta(int index) async {
    final actual = _subrecetas[index];

    final cantidad = await _pedirCantidad(
      titulo: 'Editar ${actual.productoNombre}',
      cantidadInicial: actual.cantidad,
    );

    if (cantidad == null || !mounted) {
      return;
    }

    setState(() {
      _subrecetas[index] = actual.copyWith(cantidad: cantidad);
    });
  }

  Widget _tarjetaComponente({
    required String nombre,
    required String categoria,
    required String tipo,
    required String cantidad,
    required VoidCallback editar,
    required VoidCallback eliminar,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColoresApp.principal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tipo,
                        style: const TextStyle(
                          color: ColoresApp.principal,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nombre,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoria,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            cantidad,
            style: const TextStyle(
              color: ColoresApp.principal,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: editar,
            icon: const Icon(Icons.edit_rounded, color: ColoresApp.principal),
          ),
          IconButton(
            onPressed: eliminar,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaComponentes() {
    if (_detalles.isEmpty && _subrecetas.isEmpty) {
      return const Center(
        child: Text(
          'Esta receta todavía no tiene componentes.',
          style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 15),
        ),
      );
    }

    return ListView(
      children: [
        if (_detalles.isNotEmpty) ...[
          const Text(
            'Ingredientes',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ..._detalles.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _tarjetaComponente(
                nombre: entry.value.ingredienteNombre,
                categoria: entry.value.ingredienteCategoria,
                tipo: 'INGREDIENTE',
                cantidad:
                    '${entry.value.cantidad.toStringAsFixed(3)} ${entry.value.unidadMedida}',
                editar: () => _editarIngrediente(entry.key),
                eliminar: () {
                  setState(() {
                    _detalles.removeAt(entry.key);
                  });
                },
              ),
            ),
          ),
        ],

        if (_subrecetas.isNotEmpty) ...[
          if (_detalles.isNotEmpty) const SizedBox(height: 12),
          const Text(
            'Recetas utilizadas',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ..._subrecetas.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _tarjetaComponente(
                nombre: entry.value.productoNombre,
                categoria: 'Receta: ${entry.value.recetaNombre}',
                tipo: 'RECETA',
                cantidad:
                    '${entry.value.cantidad.toStringAsFixed(3)} porciones',
                editar: () => _editarSubreceta(entry.key),
                eliminar: () {
                  setState(() {
                    _subrecetas.removeAt(entry.key);
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 780),
        padding: const EdgeInsets.all(20),
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
                    'Receta • ${widget.producto.nombre}',
                    style: const TextStyle(
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

            const SizedBox(height: 14),

            TextField(
              controller: _nombreRecetaController,
              style: const TextStyle(color: ColoresApp.textoPrincipal),
              decoration: InputDecoration(
                labelText: 'Nombre de receta',
                filled: true,
                fillColor: ColoresApp.fondoSecundario,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Componentes de la receta',
                    style: TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _agregarIngrediente,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ingrediente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.principal,
                    foregroundColor: Colors.black,
                  ),
                ),

                const SizedBox(width: 8),

                OutlinedButton.icon(
                  onPressed: _cargandoRecetas ? null : _agregarReceta,
                  icon: const Icon(Icons.account_tree_rounded),
                  label: const Text('Receta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColoresApp.principal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(child: _listaComponentes()),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        final nombre = _nombreRecetaController.text.trim();

                        if (nombre.isEmpty ||
                            (_detalles.isEmpty && _subrecetas.isEmpty)) {
                          return;
                        }

                        Navigator.pop(context, {
                          'nombreReceta': nombre,
                          'detalles': _detalles,
                          'subrecetas': _subrecetas,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresApp.principal,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'Guardar receta',
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
    );
  }
}
