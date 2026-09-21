part of '../dialogo_producto_venta.dart';

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
  }) : nombreController = TextEditingController(text: nombreInicial),
       cantidadController = TextEditingController(text: '$cantidadInicial'),
       opciones = List<_OpcionComboEditable>.from(opciones);

  factory _ComponenteComboEditable.desdeModelo(ComponenteCombo componente) {
    return _ComponenteComboEditable(
      id: componente.id,
      nombreInicial: componente.nombreComponente,
      productoPredeterminado: componente.productoPredeterminado,
      cantidadInicial: componente.cantidad,
      permiteSustitucion: componente.permiteSustitucion,
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
  }) : recargoController = TextEditingController(
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

class _DialogoNuevaSustitucion extends StatefulWidget {
  final List<ProductoVenta> productos;

  const _DialogoNuevaSustitucion({required this.productos});

  @override
  State<_DialogoNuevaSustitucion> createState() =>
      _DialogoNuevaSustitucionState();
}

class _DialogoNuevaSustitucionState extends State<_DialogoNuevaSustitucion> {
  late ProductoVenta _producto;
  final TextEditingController _recargoController = TextEditingController(
    text: '0.00',
  );

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
    final recargo =
        double.tryParse(_recargoController.text.trim().replaceAll(',', '.')) ??
        -1;

    if (recargo < 0) {
      return;
    }

    Navigator.pop(
      context,
      _ResultadoNuevaSustitucion(producto: _producto, recargo: recargo),
    );
  }

  void _actualizarEstado(VoidCallback accion) {
    if (!mounted) return;

    setState(accion);
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
              style: const TextStyle(color: ColoresApp.textoPrincipal),
              decoration: InputDecoration(
                labelText: 'Producto',
                labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
                filled: true,
                fillColor: ColoresApp.fondoSecundario,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: widget.productos.map((producto) {
                return DropdownMenuItem(
                  value: producto,
                  child: Text(
                    '${producto.nombre} · ${producto.categoria}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: ColoresApp.textoPrincipal),
              decoration: InputDecoration(
                labelText: 'Recargo',
                prefixText: '\$ ',
                labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
                prefixStyle: const TextStyle(color: ColoresApp.textoPrincipal),
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
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColoresApp.principal,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.w900),
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
