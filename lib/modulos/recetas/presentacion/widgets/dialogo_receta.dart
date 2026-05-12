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
  }

  @override
  void dispose() {
    _nombreRecetaController.dispose();
    super.dispose();
  }

  Future<void> _agregarIngrediente() async {
    IngredienteRecetaDisponible? ingredienteSeleccionado;
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
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<IngredienteRecetaDisponible>(
                    value: ingredienteSeleccionado,
                    dropdownColor: ColoresApp.superficie,
                    style: const TextStyle(color: ColoresApp.textoPrincipal),
                    decoration: InputDecoration(
                      labelText: 'Ingrediente',
                      labelStyle:
                          const TextStyle(color: ColoresApp.textoSecundario),
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
                          '${ingrediente.nombre} • ${ingrediente.unidadMedida}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setLocalState(() {
                        ingredienteSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: ColoresApp.textoPrincipal),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      labelStyle:
                          const TextStyle(color: ColoresApp.textoSecundario),
                      filled: true,
                      fillColor: ColoresApp.fondoSecundario,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
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
                  final cantidad =
                      double.tryParse(cantidadController.text.trim());

                  if (ingredienteSeleccionado == null ||
                      cantidad == null ||
                      cantidad <= 0) {
                    return;
                  }

                  Navigator.pop(
                    context,
                    RecetaDetalleItem(
                      ingredienteId: ingredienteSeleccionado!.id,
                      ingredienteNombre: ingredienteSeleccionado!.nombre,
                      ingredienteCategoria: ingredienteSeleccionado!.categoria,
                      unidadMedida: ingredienteSeleccionado!.unidadMedida,
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

    if (resultado == null) return;

    final yaExiste = _detalles.any(
      (e) => e.ingredienteId == resultado.ingredienteId,
    );

    if (yaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ese ingrediente ya está en la receta.',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: ColoresApp.principal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _detalles.add(resultado);
    });
  }

  Future<void> _editarCantidad(int index) async {
    final actual = _detalles[index];
    final controller = TextEditingController(
      text: actual.cantidad.toStringAsFixed(3),
    );

    final cantidad = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: Text(
          'Editar ${actual.ingredienteNombre}',
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
              if (valor == null || valor <= 0) return;
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

    if (cantidad == null) return;

    setState(() {
      _detalles[index] = actual.copyWith(cantidad: cantidad);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 760),
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
                labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
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
                    'Ingredientes de la receta',
                    style: TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _agregarIngrediente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.principal,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Agregar ingrediente',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _detalles.isEmpty
                  ? const Center(
                      child: Text(
                        'Esta receta todavía no tiene ingredientes.',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _detalles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final detalle = _detalles[index];

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
                                    Text(
                                      detalle.ingredienteNombre,
                                      style: const TextStyle(
                                        color: ColoresApp.textoPrincipal,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      detalle.ingredienteCategoria,
                                      style: const TextStyle(
                                        color: ColoresApp.textoSecundario,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${detalle.cantidad.toStringAsFixed(3)} ${detalle.unidadMedida}',
                                    style: const TextStyle(
                                      color: ColoresApp.principal,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _editarCantidad(index),
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          color: ColoresApp.principal,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _detalles.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.textoPrincipal,
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
                        final nombre = _nombreRecetaController.text.trim();
                        if (nombre.isEmpty || _detalles.isEmpty) return;

                        Navigator.pop(
                          context,
                          {
                            'nombreReceta': nombre,
                            'detalles': _detalles,
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