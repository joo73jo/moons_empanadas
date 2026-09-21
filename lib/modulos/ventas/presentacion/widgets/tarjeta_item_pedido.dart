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

  bool get _tieneConfiguracionCombo {
    return item.eleccionesCombo.isNotEmpty;
  }

  bool get _tieneConfiguracion {
    return _tieneConfiguracionCombo || item.sabores.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _tieneConfiguracionCombo && item.totalRecargoCombo > 0
              ? const Color(0xFFFFA726).withOpacity(0.28)
              : Colors.white.withOpacity(0.05),
        ),
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
              if (_tieneConfiguracion && onEditarSabores != null)
                IconButton(
                  onPressed: onEditarSabores,
                  tooltip: _tieneConfiguracionCombo
                      ? 'Editar combo'
                      : 'Editar sabores',
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: ColoresApp.principal,
                  ),
                ),
              IconButton(
                onPressed: onEliminar,
                tooltip: 'Eliminar',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _informacionPrecio(),
          if (_tieneConfiguracionCombo) ...[
            const SizedBox(height: 12),
            _configuracionCombo(),
          ] else if (item.sabores.isNotEmpty) ...[
            const SizedBox(height: 10),
            _configuracionSaboresAntigua(),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _BotonCantidad(icono: Icons.remove_rounded, onTap: onRestar),
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
              _BotonCantidad(icono: Icons.add_rounded, onTap: onSumar),
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

  Widget _informacionPrecio() {
    if (!_tieneConfiguracionCombo || item.recargoComboUnitario <= 0) {
      return Text(
        '\$${item.precioUnitarioFinal.toStringAsFixed(2)} c/u',
        style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 13),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _filaPrecio(titulo: 'Precio base', valor: item.producto.precio),
          const SizedBox(height: 5),
          _filaPrecio(
            titulo: 'Sustituciones',
            valor: item.recargoComboUnitario,
            resaltarRecargo: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 7),
            child: Divider(height: 1, color: Color(0x22FFFFFF)),
          ),
          _filaPrecio(
            titulo: 'Precio por combo',
            valor: item.precioUnitarioFinal,
            resaltarTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _filaPrecio({
    required String titulo,
    required double valor,
    bool resaltarRecargo = false,
    bool resaltarTotal = false,
  }) {
    final color = resaltarRecargo
        ? const Color(0xFFFFA726)
        : resaltarTotal
        ? ColoresApp.principal
        : ColoresApp.textoSecundario;

    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              color: resaltarTotal
                  ? ColoresApp.textoPrincipal
                  : ColoresApp.textoSecundario,
              fontSize: 12,
              fontWeight: resaltarTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: resaltarTotal ? 14 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _configuracionCombo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incluye',
          style: TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...item.eleccionesCombo.map((eleccion) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: eleccion.fueSustituido
                    ? const Color(0xFFFFA726).withOpacity(0.35)
                    : ColoresApp.principal.withOpacity(0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  eleccion.fueSustituido
                      ? Icons.swap_horiz_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: eleccion.fueSustituido
                      ? const Color(0xFFFFA726)
                      : ColoresApp.principal,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eleccion.nombreComponente,
                        style: const TextStyle(
                          color: ColoresApp.textoSecundario,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eleccion.descripcion,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (eleccion.fueSustituido) ...[
                        const SizedBox(height: 3),
                        const Text(
                          'Sustitución',
                          style: TextStyle(
                            color: Color(0xFFFFA726),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (eleccion.recargoTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '+\$${eleccion.recargoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFFFA726),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _configuracionSaboresAntigua() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonCantidad({required this.icono, required this.onTap});

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
        child: Icon(icono, color: ColoresApp.principal, size: 18),
      ),
    );
  }
}
