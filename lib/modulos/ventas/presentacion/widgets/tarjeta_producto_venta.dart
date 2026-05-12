import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

class TarjetaProductoVenta extends StatelessWidget {
  final ProductoVenta producto;
  final bool esDueno;
  final VoidCallback onAgregar;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const TarjetaProductoVenta({
    super.key,
    required this.producto,
    required this.esDueno,
    required this.onAgregar,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        ColoresApp.principalClaro,
                        ColoresApp.principal,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fastfood_rounded,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                if (esDueno)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    iconColor: ColoresApp.textoSecundario,
                    color: ColoresApp.superficie,
                    onSelected: (value) {
                      if (value == 'editar') onEditar?.call();
                      if (value == 'eliminar') onEliminar?.call();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              producto.categoria,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '\$${producto.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                color: ColoresApp.principal,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: onAgregar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Agregar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}