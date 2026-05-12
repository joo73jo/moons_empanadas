import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import 'ventas_modelos.dart';

class TarjetaItemPedido extends StatelessWidget {
  final ItemPedido item;
  final VoidCallback onSumar;
  final VoidCallback onRestar;
  final VoidCallback onEliminar;
  final VoidCallback? onEditarSabores;

  const TarjetaItemPedido({
    super.key,
    required this.item,
    required this.onSumar,
    required this.onRestar,
    required this.onEliminar,
    this.onEditarSabores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.producto.nombre,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (item.sabores.isNotEmpty)
                IconButton(
                  onPressed: onEditarSabores,
                  tooltip: 'Editar sabores',
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: ColoresApp.principal,
                  ),
                ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${item.producto.precio.toStringAsFixed(2)} c/u',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          if (item.sabores.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Sabores',
              style: TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(item.sabores.length, (index) {
                final sabor = item.sabores[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColoresApp.principal.withOpacity(0.16),
                    ),
                  ),
                  child: Text(
                    '${index + 1}. $sabor',
                    style: const TextStyle(
                      color: ColoresApp.textoPrincipal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _BotonCantidad(
                icono: Icons.remove_rounded,
                onTap: onRestar,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '${item.cantidad}',
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _BotonCantidad(
                icono: Icons.add_rounded,
                onTap: onSumar,
              ),
              const Spacer(),
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: ColoresApp.principal,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonCantidad({
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icono,
          color: ColoresApp.principal,
          size: 18,
        ),
      ),
    );
  }
}