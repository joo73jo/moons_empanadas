import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

class DialogoComboSabores extends StatefulWidget {
  final ProductoVenta combo;
  final List<ProductoVenta> saboresDisponibles;

  const DialogoComboSabores({
    super.key,
    required this.combo,
    required this.saboresDisponibles,
  });

  @override
  State<DialogoComboSabores> createState() => _DialogoComboSaboresState();
}

class _DialogoComboSaboresState extends State<DialogoComboSabores> {
  final List<String> _seleccionados = [];

  bool get _completo => _seleccionados.length == widget.combo.cantidadSabores;

  void _agregarSabor(String nombre) {
    if (_seleccionados.length >= widget.combo.cantidadSabores) return;

    setState(() {
      _seleccionados.add(nombre);
    });
  }

  void _quitarSabor(int index) {
    setState(() {
      _seleccionados.removeAt(index);
    });
  }

  int _cantidadDe(String nombre) {
    return _seleccionados.where((e) => e == nombre).length;
  }

  @override
  Widget build(BuildContext context) {
    final faltan = widget.combo.cantidadSabores - _seleccionados.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.combo.nombre,
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
            const SizedBox(height: 6),
            Text(
              'Selecciona ${widget.combo.cantidadSabores} empanadas. Puedes repetir sabores.',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                faltan > 0
                    ? 'Faltan $faltan sabores por seleccionar'
                    : 'Selección completa',
                style: TextStyle(
                  color: faltan > 0
                      ? ColoresApp.textoPrincipal
                      : ColoresApp.principal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: widget.saboresDisponibles.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 145,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final producto = widget.saboresDisponibles[index];
                  final cantidad = _cantidadDe(producto.nombre);
                  final bloqueado = _completo;

                  return InkWell(
                    onTap: bloqueado ? null : () => _agregarSabor(producto.nombre),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: ColoresApp.fondoSecundario,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: cantidad > 0
                              ? ColoresApp.principal
                              : Colors.white.withOpacity(0.05),
                          width: cantidad > 0 ? 1.4 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        ColoresApp.principalClaro,
                                        ColoresApp.principal,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.fastfood_rounded,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                if (cantidad > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColoresApp.principal,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'x$cantidad',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: Text(
                                producto.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ColoresApp.textoPrincipal,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Tocar para agregar',
                              style: TextStyle(
                                color: ColoresApp.textoSecundario,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Selección actual',
                style: TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 70, maxHeight: 130),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _seleccionados.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Aún no has seleccionado sabores.',
                        style: TextStyle(
                          color: ColoresApp.textoSecundario,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_seleccionados.length, (index) {
                          final sabor = _seleccionados[index];

                          return Container(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 8,
                              top: 8,
                              bottom: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ColoresApp.principal.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${index + 1}. $sabor',
                                  style: const TextStyle(
                                    color: ColoresApp.textoPrincipal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _quitarSabor(index),
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
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
                      onPressed: _completo
                          ? () => Navigator.pop(context, List<String>.from(_seleccionados))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresApp.principal,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Agregar combo',
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