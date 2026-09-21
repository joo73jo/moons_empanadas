part of '../dialogo_cobro.dart';

extension _DialogoCobroPagoComensales on _DialogoCobroState {
  Widget _contenidoComensales() {
    return Column(
      children: [
        ListView.separated(
          itemCount: _comensales.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) {
            return const SizedBox(height: 14);
          },
          itemBuilder: (context, index) {
            return _tarjetaComensal(index);
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _agregarComensal,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: ColoresApp.principal,
            ),
            label: const Text(
              'Agregar otro comensal',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.textoPrincipal,
              side: BorderSide(color: ColoresApp.principal.withOpacity(0.40)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _resumenComensales(),
      ],
    );
  }

  Widget _tarjetaComensal(int index) {
    final comensal = _comensales[index];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comensal ${index + 1}',
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _eliminarComensal(index);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campoDinero(
            controller: comensal.montoController,
            label: 'Monto que paga',
            onChanged: (valor) {
              _actualizarEstado(() {
                if (comensal.metodoPago == MetodoPago.efectivo &&
                    comensal.recibidoController.text.trim().isEmpty) {
                  comensal.recibidoController.text = valor;
                }
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _usarRestante(index);
              },
              icon: const Icon(Icons.calculate_rounded, size: 18),
              label: const Text('Usar monto restante'),
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.principal,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MetodoPago.values.map((metodo) {
              final activo = comensal.metodoPago == metodo;

              return ChoiceChip(
                selected: activo,
                label: Text(_nombreMetodo(metodo)),
                avatar: Icon(
                  _iconoMetodo(metodo),
                  size: 18,
                  color: activo ? Colors.black : ColoresApp.textoSecundario,
                ),
                selectedColor: ColoresApp.principal,
                backgroundColor: Colors.black,
                labelStyle: TextStyle(
                  color: activo ? Colors.black : ColoresApp.textoPrincipal,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) {
                  _actualizarEstado(() {
                    comensal.metodoPago = metodo;

                    if (metodo == MetodoPago.efectivo &&
                        comensal.recibidoController.text.trim().isEmpty) {
                      comensal.recibidoController.text =
                          comensal.montoController.text;
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (comensal.metodoPago == MetodoPago.efectivo) ...[
            const SizedBox(height: 14),
            _campoDinero(
              controller: comensal.recibidoController,
              label: 'Entrega en efectivo',
              error: comensal.efectivoInsuficiente,
              onChanged: (_) {
                _actualizarEstado(() {});
              },
            ),
            const SizedBox(height: 10),
            _miniResumen(
              titulo: comensal.efectivoInsuficiente
                  ? 'Falta efectivo'
                  : 'Vuelto',
              valor: comensal.efectivoInsuficiente
                  ? '\$${(comensal.monto - comensal.recibido).toStringAsFixed(2)}'
                  : '\$${comensal.cambio.toStringAsFixed(2)}',
              color: comensal.efectivoInsuficiente
                  ? ColoresApp.error
                  : ColoresApp.principal,
            ),
          ],
          if (comensal.metodoPago == MetodoPago.transferencia) ...[
            const SizedBox(height: 14),
            _campoTexto(controller: comensal.bancoController, label: 'Banco'),
          ],
          if (comensal.metodoPago == MetodoPago.tarjeta) ...[
            const SizedBox(height: 14),
            _selectorDatofono(
              valor: comensal.datofono,
              onChanged: (valor) {
                _actualizarEstado(() {
                  comensal.datofono = valor ?? 'Bendo';
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _resumenComensales() {
    final completo = _cuentaCompleta;

    final excedente = _excedenteComensales;

    final Color color;

    if (completo) {
      color = ColoresApp.exito;
    } else if (excedente > 0) {
      color = ColoresApp.error;
    } else {
      color = ColoresApp.principal;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          _filaResumen(
            titulo: 'Total de la cuenta',
            valor: '\$${_totalFinal.toStringAsFixed(2)}',
            color: ColoresApp.textoPrincipal,
          ),
          const SizedBox(height: 9),
          _filaResumen(
            titulo: 'Total ingresado',
            valor: '\$${_totalComensales.toStringAsFixed(2)}',
            color: color,
          ),
          const SizedBox(height: 9),
          if (completo)
            _filaResumen(
              titulo: 'Estado',
              valor: 'Completo',
              color: ColoresApp.exito,
            )
          else if (excedente > 0)
            _filaResumen(
              titulo: 'Excedente',
              valor: '\$${excedente.toStringAsFixed(2)}',
              color: ColoresApp.error,
            )
          else
            _filaResumen(
              titulo: 'Falta por pagar',
              valor: '\$${_restanteComensales.toStringAsFixed(2)}',
              color: ColoresApp.principal,
            ),
        ],
      ),
    );
  }
}
