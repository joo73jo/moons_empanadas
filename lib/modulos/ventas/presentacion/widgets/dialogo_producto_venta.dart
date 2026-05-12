import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

class DialogoProductoVenta extends StatefulWidget {
  final ProductoVenta? producto;

  const DialogoProductoVenta({
    super.key,
    this.producto,
  });

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

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.producto?.nombre ?? '');
    _categoriaController =
        TextEditingController(text: widget.producto?.categoria ?? '');
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
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    _cantidadSaboresController.dispose();
    super.dispose();
  }

  String _nombreSeccion(SeccionVenta seccion) {
    switch (seccion) {
      case SeccionVenta.individuales:
        return 'Individuales';
      case SeccionVenta.combos:
        return 'Combos';
      case SeccionVenta.uber:
        return 'Uber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColoresApp.superficie,
      title: Text(
        widget.producto == null ? 'Nuevo producto' : 'Editar producto',
        style: const TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(
                controller: _nombreController,
                etiqueta: 'Nombre',
              ),
              const SizedBox(height: 12),
              _campo(
                controller: _categoriaController,
                etiqueta: 'Categoría',
              ),
              const SizedBox(height: 12),
              _campo(
                controller: _precioController,
                etiqueta: 'Precio',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SeccionVenta>(
                value: _seccion,
                dropdownColor: ColoresApp.superficie,
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  labelText: 'Sección',
                  labelStyle:
                      const TextStyle(color: ColoresApp.textoSecundario),
                  filled: true,
                  fillColor: ColoresApp.fondoSecundario,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: SeccionVenta.values.map((seccion) {
                  return DropdownMenuItem(
                    value: seccion,
                    child: Text(_nombreSeccion(seccion)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _seccion = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _requiereSabores,
                activeColor: ColoresApp.principal,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text(
                  'Requiere sabores',
                  style: TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Actívalo para combos o productos con selección',
                  style: TextStyle(color: ColoresApp.textoSecundario),
                ),
                onChanged: (value) {
                  setState(() {
                    _requiereSabores = value;
                    if (!_requiereSabores) {
                      _cantidadSaboresController.text = '0';
                    }
                  });
                },
              ),
              if (_requiereSabores) ...[
                const SizedBox(height: 8),
                _campo(
                  controller: _cantidadSaboresController,
                  etiqueta: 'Cantidad de sabores',
                  keyboardType: TextInputType.number,
                ),
              ],
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
            final precio = double.tryParse(_precioController.text.trim());
            final cantidadSabores =
                int.tryParse(_cantidadSaboresController.text.trim()) ?? 0;

            if (nombre.isEmpty || categoria.isEmpty || precio == null || precio <= 0) {
              return;
            }

            if (_requiereSabores && cantidadSabores <= 0) {
              return;
            }

            Navigator.pop(
  context,
  ProductoVenta(
    id: widget.producto?.id ?? 0,
    nombre: nombre,
    categoria: categoria,
    precio: precio,
    seccion: _seccion,
    requiereSabores: _requiereSabores,
    cantidadSabores: _requiereSabores ? cantidadSabores : 0,
    controlaStock: _seccion == SeccionVenta.individuales,
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

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
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