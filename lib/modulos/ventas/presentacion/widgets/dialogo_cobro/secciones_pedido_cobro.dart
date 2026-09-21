part of '../dialogo_cobro.dart';

extension _DialogoCobroSeccionesPedido on _DialogoCobroState {
  Widget _encabezado() {
    final titulo = widget.soloCobro
        ? 'Cobrar ${widget.nombrePedido?.trim().isNotEmpty == true ? widget.nombrePedido!.trim() : 'pedido'}'
        : 'Finalizar pedido';

    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close_rounded,
            color: ColoresApp.textoSecundario,
          ),
        ),
      ],
    );
  }

  Widget _seccionIdentificacion() {
    return _bloque(
      titulo: 'Identificación',
      icono: Icons.badge_rounded,
      child: _campoTexto(
        controller: _nombrePedidoController,
        label: 'Nombre del pedido',
        hint: 'Ejemplo: Juan, Mesa 4, Uber Ana',
      ),
    );
  }

  Widget _seccionTipoPedido() {
    return _bloque(
      titulo: 'Tipo de pedido',
      icono: Icons.shopping_bag_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: TipoPedido.values.map((tipo) {
          final activo = _tipoPedido == tipo;

          return ChoiceChip(
            selected: activo,
            label: Text(nombreTipoPedido(tipo)),
            selectedColor: ColoresApp.principal,
            backgroundColor: Colors.black,
            checkmarkColor: Colors.black,
            labelStyle: TextStyle(
              color: activo ? Colors.black : ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: activo
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.08),
            ),
            onSelected: (_) {
              _actualizarEstado(() {
                _tipoPedido = tipo;

                if (tipo != TipoPedido.domicilio) {
                  _barrioController.clear();
                  _valorDomicilioController.clear();
                  _usaIndrive = false;
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _seccionProgramacion() {
    final textoFecha = _fechaProgramada == null
        ? 'Seleccionar fecha y hora'
        : '${_fechaProgramada!.day.toString().padLeft(2, '0')}/'
              '${_fechaProgramada!.month.toString().padLeft(2, '0')}/'
              '${_fechaProgramada!.year} '
              '${_fechaProgramada!.hour.toString().padLeft(2, '0')}:'
              '${_fechaProgramada!.minute.toString().padLeft(2, '0')}';

    return _bloque(
      titulo: 'Programación',
      icono: Icons.event_rounded,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _esProgramado,
            title: const Text(
              'Pedido programado',
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: const Text(
              'El pago se registrará cuando se cobre el pedido.',
              style: TextStyle(color: ColoresApp.textoSecundario),
            ),
            onChanged: (valor) {
              _actualizarEstado(() {
                _esProgramado = valor;

                if (valor) {
                  _estadoCobro = EstadoCobroVenta.pendientePago;

                  _fechaProgramada ??= DateTime.now().add(
                    const Duration(days: 1),
                  );
                }
              });
            },
          ),

          if (_esProgramado) ...[
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _seleccionarFechaProgramada,
                icon: const Icon(
                  Icons.schedule_rounded,
                  color: ColoresApp.principal,
                ),
                label: Text(
                  textoFecha,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresApp.textoPrincipal,
                  side: BorderSide(
                    color: ColoresApp.principal.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _seleccionarFechaProgramada() async {
    final ahora = DateTime.now();

    final inicial = _fechaProgramada ?? ahora.add(const Duration(days: 1));

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: DateTime(ahora.year + 3, 12, 31),
    );

    if (fecha == null || !mounted) {
      return;
    }

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
    );

    if (hora == null || !mounted) {
      return;
    }

    _actualizarEstado(() {
      _fechaProgramada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Widget _seccionDelivery() {
    return _bloque(
      titulo: 'Delivery',
      icono: Icons.delivery_dining_rounded,
      child: Column(
        children: [
          _campoTexto(
            controller: _barrioController,
            label: 'Barrio del domicilio',
          ),

          const SizedBox(height: 12),

          _campoDinero(
            controller: _valorDomicilioController,
            label: 'Valor del domicilio',
            onChanged: (_) {
              _actualizarEstado(() {
                _actualizarMontosAlCambiarTotal();
              });
            },
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _usaIndrive,
            title: const Text(
              'Delivery con InDrive',
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: const Text(
              'Marca esta opción cuando el envío se realiza mediante InDrive.',
              style: TextStyle(color: ColoresApp.textoSecundario),
            ),
            onChanged: (valor) {
              _actualizarEstado(() {
                _usaIndrive = valor;
              });
            },
          ),
        ],
      ),
    );
  }

  void _seleccionarPlataforma(String nombre) {
    PlataformaConfiguracion? encontrada;

    for (final plataforma in widget.plataformasDisponibles) {
      if (plataforma.nombre == nombre) {
        encontrada = plataforma;
        break;
      }
    }

    _actualizarEstado(() {
      _plataformaSeleccionada = nombre;

      if (encontrada != null) {
        _porcentajePlataformaController.text = encontrada.porcentaje
            .toStringAsFixed(2);
      }
    });
  }

  Widget _seccionPlataforma() {
    return _bloque(
      titulo: 'Plataforma',
      icono: Icons.storefront_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _plataformaSeleccionada.isEmpty
                ? null
                : _plataformaSeleccionada,
            dropdownColor: ColoresApp.superficie,
            decoration: InputDecoration(
              labelText: 'Plataforma',
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
            items: widget.plataformasDisponibles
                .where((plataforma) => plataforma.activo)
                .map(
                  (plataforma) => DropdownMenuItem<String>(
                    value: plataforma.nombre,
                    child: Text(plataforma.nombre),
                  ),
                )
                .toList(),
            onChanged: (valor) {
              if (valor == null) {
                return;
              }

              _seleccionarPlataforma(valor);
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _porcentajePlataformaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              _actualizarEstado(() {});
            },
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              labelText: 'Porcentaje de plataforma',
              hintText: 'Ejemplo: 20',
              suffixText: '%',
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 10),

          _miniResumen(
            titulo: 'Descuento de plataforma',
            valor: '\$${_descuentoPlataforma.toStringAsFixed(2)}',
            color: ColoresApp.principal,
          ),
        ],
      ),
    );
  }

  Widget _seccionRecargo() {
    return _bloque(
      titulo: 'Recargo',
      icono: Icons.percent_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escribe el porcentaje que se aplicará únicamente a esta venta.',
            style: TextStyle(color: ColoresApp.textoSecundario, height: 1.3),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _porcentajeRecargoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              _actualizarEstado(() {
                _actualizarMontosAlCambiarTotal();
              });
            },
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              labelText: 'Porcentaje de recargo',
              hintText: 'Ejemplo: 10',
              suffixText: '%',
              suffixStyle: const TextStyle(
                color: ColoresApp.principal,
                fontWeight: FontWeight.w900,
              ),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _miniResumen(
            titulo: 'Valor del recargo',
            valor: '\$${_valorRecargo.toStringAsFixed(2)}',
            color: ColoresApp.principal,
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTotales() {
    final netoPlataforma = (_totalFinal - _descuentoPlataforma) < 0
        ? 0.0
        : (_totalFinal - _descuentoPlataforma);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColoresApp.principal.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          if (!widget.soloCobro) ...[
            _filaResumen(
              titulo: 'Consumo',
              valor: '\$${widget.subtotal.toStringAsFixed(2)}',
              color: ColoresApp.textoPrincipal,
            ),

            if (_tipoPedido == TipoPedido.domicilio && _valorDomicilio > 0) ...[
              const SizedBox(height: 9),

              _filaResumen(
                titulo: 'Domicilio',
                valor: '\$${_valorDomicilio.toStringAsFixed(2)}',
                color: ColoresApp.textoSecundario,
              ),
            ],

            const Divider(height: 22),
          ],

          _filaResumen(
            titulo: widget.soloCobro ? 'Total pendiente' : 'Total cliente',
            valor: '\$${_totalFinal.toStringAsFixed(2)}',
            color: ColoresApp.principal,
          ),

          if (widget.esVentaPlataforma) ...[
            const SizedBox(height: 9),

            _filaResumen(
              titulo: 'Comisión $_plataformaSeleccionada',
              valor: '- \$${_descuentoPlataforma.toStringAsFixed(2)}',
              color: ColoresApp.error,
            ),

            const SizedBox(height: 9),

            _filaResumen(
              titulo: 'Neto después de plataforma',
              valor: '\$${netoPlataforma.toStringAsFixed(2)}',
              color: ColoresApp.exito,
            ),
          ],

          if (_esProgramado) ...[
            const SizedBox(height: 12),

            const Text(
              'PROGRAMADO · No entra a caja hasta que se registre el cobro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColoresApp.principal,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seccionMomentoPago() {
    final estados = [
      EstadoCobroVenta.pagado,
      EstadoCobroVenta.pendientePago,
      EstadoCobroVenta.cobradoRepartidor,
    ];

    return _bloque(
      titulo: 'Momento del pago',
      icono: Icons.account_balance_wallet_rounded,
      child: Column(
        children: estados.map((estado) {
          final activo = _estadoCobro == estado;

          return RadioListTile<EstadoCobroVenta>(
            value: estado,
            groupValue: _estadoCobro,
            activeColor: ColoresApp.principal,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _nombreEstadoCobro(estado),
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: activo ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            subtitle: estado == EstadoCobroVenta.pendientePago
                ? const Text(
                    'El pedido se prepara ahora y aparecerá pendiente para cobrarlo después.',
                    style: TextStyle(color: ColoresApp.textoSecundario),
                  )
                : null,
            onChanged: (nuevoEstado) {
              if (nuevoEstado == null) {
                return;
              }

              _actualizarEstado(() {
                _estadoCobro = nuevoEstado;
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
