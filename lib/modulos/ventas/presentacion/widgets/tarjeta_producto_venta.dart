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

  Color get _colorStock {
    switch (producto.nivelStock) {
      case 'critico':
        return Colors.redAccent;
      case 'minimo':
        return const Color(0xFFFFA726);
      case 'sin_control':
        return ColoresApp.textoSecundario;
      default:
        return const Color(0xFF00A896);
    }
  }

  String get _textoStock {
    if (!producto.controlaStock) return 'Sin stock';
    return '${producto.stockActual.toStringAsFixed(0)} disp.';
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esCelular = ancho < 760;

    return Container(
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(esCelular ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: esCelular ? 42 : 44,
                  height: esCelular ? 42 : 44,
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
                    size: 23,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: esCelular ? 34 : 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _colorStock.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _colorStock.withOpacity(0.45),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _textoStock,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _colorStock,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
            const SizedBox(height: 8),
            Text(
              producto.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontSize: esCelular ? 15 : 16,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              producto.categoria,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              '\$${producto.precio.toStringAsFixed(2)}',
              style: TextStyle(
                color: ColoresApp.principal,
                fontSize: esCelular ? 21 : 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: esCelular ? 34 : 38,
              child: ElevatedButton(
                onPressed: producto.controlaStock && producto.stockActual <= 0
                    ? null
                    : onAgregar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  disabledBackgroundColor: ColoresApp.superficie,
                  foregroundColor: Colors.black,
                  disabledForegroundColor: ColoresApp.textoSecundario,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  producto.controlaStock && producto.stockActual <= 0
                      ? 'Sin stock'
                      : 'Agregar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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