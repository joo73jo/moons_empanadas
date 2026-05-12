import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';

enum MetodoPago {
  efectivo,
  transferencia,
  tarjeta,
}

class ResultadoCobro {
  final MetodoPago metodoPago;
  final String? banco;
  final String? datofono;
  final double total;

  const ResultadoCobro({
    required this.metodoPago,
    required this.total,
    this.banco,
    this.datofono,
  });
}

class DialogoCobro extends StatefulWidget {
  final double total;

  const DialogoCobro({
    super.key,
    required this.total,
  });

  @override
  State<DialogoCobro> createState() => _DialogoCobroState();
}

class _DialogoCobroState extends State<DialogoCobro> {
  MetodoPago _metodoPago = MetodoPago.efectivo;
  final TextEditingController _bancoController = TextEditingController();
  String? _datofonoSeleccionado = 'Bendo';

  @override
  void dispose() {
    _bancoController.dispose();
    super.dispose();
  }

  String _nombreMetodo(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
    }
  }

  void _confirmar() {
    if (_metodoPago == MetodoPago.transferencia &&
        _bancoController.text.trim().isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      ResultadoCobro(
        metodoPago: _metodoPago,
        total: widget.total,
        banco: _metodoPago == MetodoPago.transferencia
            ? _bancoController.text.trim()
            : null,
        datofono:
            _metodoPago == MetodoPago.tarjeta ? _datofonoSeleccionado : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(22),
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
                const Expanded(
                  child: Text(
                    'Cobrar pedido',
                    style: TextStyle(
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
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total a cobrar',
                    style: TextStyle(
                      color: ColoresApp.textoSecundario,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: ColoresApp.principal,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Método de pago',
                style: TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: MetodoPago.values.map((metodo) {
                final activo = _metodoPago == metodo;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _metodoPago = metodo;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: activo
                            ? ColoresApp.principal.withOpacity(0.14)
                            : ColoresApp.fondoSecundario,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: activo
                              ? ColoresApp.principal
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _iconoMetodo(metodo),
                            color: activo
                                ? ColoresApp.principal
                                : ColoresApp.textoSecundario,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _nombreMetodo(metodo),
                            style: TextStyle(
                              color: ColoresApp.textoPrincipal,
                              fontWeight:
                                  activo ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_metodoPago == MetodoPago.transferencia) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _bancoController,
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  labelText: 'Banco',
                  labelStyle:
                      const TextStyle(color: ColoresApp.textoSecundario),
                  filled: true,
                  fillColor: ColoresApp.fondoSecundario,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
            if (_metodoPago == MetodoPago.tarjeta) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _datofonoSeleccionado,
                dropdownColor: ColoresApp.superficie,
                style: const TextStyle(color: ColoresApp.textoPrincipal),
                decoration: InputDecoration(
                  labelText: 'Datáfono',
                  labelStyle:
                      const TextStyle(color: ColoresApp.textoSecundario),
                  filled: true,
                  fillColor: ColoresApp.fondoSecundario,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Bendo',
                    child: Text('Bendo'),
                  ),
                  DropdownMenuItem(
                    value: 'Ya Ganaste',
                    child: Text('Ya Ganaste'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _datofonoSeleccionado = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
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
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresApp.principal,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirmar cobro',
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

  IconData _iconoMetodo(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return Icons.payments_rounded;
      case MetodoPago.transferencia:
        return Icons.account_balance_rounded;
      case MetodoPago.tarjeta:
        return Icons.credit_card_rounded;
    }
  }
}