import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import 'inventario_supabase.dart';

class DialogoItemInventario extends StatefulWidget {
  final ItemInventario? item;

  const DialogoItemInventario({
    super.key,
    this.item,
  });

  @override
  State<DialogoItemInventario> createState() => _DialogoItemInventarioState();
}

class _DialogoItemInventarioState extends State<DialogoItemInventario> {
  late final TextEditingController _nombreController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _unidadController;
  late final TextEditingController _stockActualController;
  late final TextEditingController _stockMinimoController;
  late final TextEditingController _stockCriticoController;
  late final TextEditingController _costoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.item?.nombre ?? '');
    _categoriaController =
        TextEditingController(text: widget.item?.categoria ?? '');
    _unidadController =
        TextEditingController(text: widget.item?.unidadMedida ?? '');
    _stockActualController = TextEditingController(
      text: widget.item != null ? widget.item!.stockActual.toString() : '0',
    );
    _stockMinimoController = TextEditingController(
      text: widget.item != null ? widget.item!.stockMinimo.toString() : '0',
    );
    _stockCriticoController = TextEditingController(
      text: widget.item != null ? widget.item!.stockCritico.toString() : '0',
    );
    _costoController = TextEditingController(
      text: widget.item != null ? widget.item!.costoUnitario.toString() : '0',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _unidadController.dispose();
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    _stockCriticoController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.item == null;

    return AlertDialog(
      backgroundColor: ColoresApp.superficie,
      title: Text(
        esNuevo ? 'Nuevo ingrediente' : 'Editar ingrediente',
        style: const TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _campo(_nombreController, 'Nombre'),
              const SizedBox(height: 12),
              _campo(_categoriaController, 'Categoría'),
              const SizedBox(height: 12),
              _campo(_unidadController, 'Unidad medida'),
              const SizedBox(height: 12),
              if (esNuevo) ...[
                _campo(
                  _stockActualController,
                  'Stock actual',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
              ],
              _campo(
                _stockMinimoController,
                'Stock mínimo',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              _campo(
                _stockCriticoController,
                'Stock crítico',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              _campo(
                _costoController,
                'Costo unitario',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
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
            final nombre = _nombreController.text.trim();
            final categoria = _categoriaController.text.trim();
            final unidad = _unidadController.text.trim();
            final stockActual =
                double.tryParse(_stockActualController.text.trim()) ?? 0;
            final stockMinimo =
                double.tryParse(_stockMinimoController.text.trim()) ?? 0;
            final stockCritico =
                double.tryParse(_stockCriticoController.text.trim()) ?? 0;
            final costo = double.tryParse(_costoController.text.trim()) ?? 0;

            if (nombre.isEmpty || categoria.isEmpty || unidad.isEmpty) return;
            if (stockActual < 0 ||
                stockMinimo < 0 ||
                stockCritico < 0 ||
                costo < 0) {
              return;
            }

            Navigator.pop(
              context,
              ItemInventario(
                id: widget.item?.id ?? 0,
                nombre: nombre,
                categoria: categoria,
                unidadMedida: unidad,
                stockActual: esNuevo ? stockActual : (widget.item?.stockActual ?? 0),
                stockMinimo: stockMinimo,
                stockCritico: stockCritico,
                costoUnitario: costo,
                activo: true,
                createdAt: widget.item?.createdAt ?? DateTime.now(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.principal,
            foregroundColor: Colors.black,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        filled: true,
        fillColor: ColoresApp.fondoSecundario,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}