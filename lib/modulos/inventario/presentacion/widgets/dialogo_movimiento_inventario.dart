import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import 'inventario_supabase.dart';

class ResultadoMovimientoInventario {
  final TipoMovimientoInventario tipo;
  final double valor;
  final String motivo;

  const ResultadoMovimientoInventario({
    required this.tipo,
    required this.valor,
    required this.motivo,
  });
}

class DialogoMovimientoInventario extends StatefulWidget {
  final ItemInventario item;

  const DialogoMovimientoInventario({
    super.key,
    required this.item,
  });

  @override
  State<DialogoMovimientoInventario> createState() =>
      _DialogoMovimientoInventarioState();
}

class _DialogoMovimientoInventarioState
    extends State<DialogoMovimientoInventario> {
  TipoMovimientoInventario _tipo = TipoMovimientoInventario.entrada;
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();

  @override
  void dispose() {
    _valorController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  String _nombreTipo(TipoMovimientoInventario tipo) {
    switch (tipo) {
      case TipoMovimientoInventario.entrada:
        return 'Entrada';
      case TipoMovimientoInventario.salida:
        return 'Salida';
      case TipoMovimientoInventario.ajuste:
        return 'Ajuste';
    }
  }

  String _labelValor() {
    switch (_tipo) {
      case TipoMovimientoInventario.entrada:
        return 'Cantidad que entra';
      case TipoMovimientoInventario.salida:
        return 'Cantidad que sale';
      case TipoMovimientoInventario.ajuste:
        return 'Nuevo stock real';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColoresApp.superficie,
      title: Text(
        'Movimiento • ${widget.item.nombre}',
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
              DropdownButtonFormField<TipoMovimientoInventario>(
                value: _tipo,
                dropdownColor: ColoresApp.superficie,
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  labelText: 'Tipo movimiento',
                  labelStyle: const TextStyle(
                    color: ColoresApp.textoSecundario,
                  ),
                  filled: true,
                  fillColor: ColoresApp.fondoSecundario,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: TipoMovimientoInventario.values.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(_nombreTipo(tipo)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _tipo = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  labelText: _labelValor(),
                  labelStyle:
                      const TextStyle(color: ColoresApp.textoSecundario),
                  filled: true,
                  fillColor: ColoresApp.fondoSecundario,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motivoController,
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  labelText: 'Motivo',
                  labelStyle:
                      const TextStyle(color: ColoresApp.textoSecundario),
                  filled: true,
                  fillColor: ColoresApp.fondoSecundario,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stock actual: ${widget.item.stockActual.toStringAsFixed(3)} ${widget.item.unidadMedida}',
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 13,
                  ),
                ),
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
            final valor = double.tryParse(_valorController.text.trim());
            final motivo = _motivoController.text.trim();

            if (valor == null || valor <= 0 || motivo.isEmpty) return;

            Navigator.pop(
              context,
              ResultadoMovimientoInventario(
                tipo: _tipo,
                valor: valor,
                motivo: motivo,
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
}