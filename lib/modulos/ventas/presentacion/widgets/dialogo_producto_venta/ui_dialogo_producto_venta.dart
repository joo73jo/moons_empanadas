part of '../dialogo_producto_venta.dart';

extension _DialogoProductoVentaUI on _DialogoProductoVentaState {
  Widget _encabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColoresApp.principal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _esCombo ? Icons.local_offer_rounded : Icons.fastfood_rounded,
              color: ColoresApp.principal,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto == null
                      ? 'Nuevo producto'
                      : 'Editar producto',
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _esCombo
                      ? 'Configura el combo y sus sustituciones'
                      : 'Información general del producto',
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
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
      ),
    );
  }

  Widget _selectorCategoria() {
    const nuevaCategoria = '__nueva_categoria__';

    final categorias = List<String>.from(_categoriasDisponibles);

    final seleccionada = _categoriaSeleccionada;

    if (seleccionada != null &&
        seleccionada.trim().isNotEmpty &&
        !categorias.any(
          (categoria) => categoria.toLowerCase() == seleccionada.toLowerCase(),
        )) {
      categorias.add(seleccionada);
    }

    categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final valorActual =
        !_crearNuevaCategoria &&
            seleccionada != null &&
            categorias.contains(seleccionada)
        ? seleccionada
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: valorActual,
          isExpanded: true,
          dropdownColor: ColoresApp.superficie,
          decoration: _decoracionCampo('Categoría'),
          hint: const Text(
            'Selecciona una categoría',
            style: TextStyle(color: ColoresApp.textoSecundario),
          ),
          items: [
            ...categorias.map(
              (categoria) => DropdownMenuItem<String>(
                value: categoria,
                child: Text(categoria, overflow: TextOverflow.ellipsis),
              ),
            ),
            const DropdownMenuItem<String>(
              value: nuevaCategoria,
              child: Text(
                '+ Crear nueva categoría',
                style: TextStyle(
                  color: ColoresApp.principal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          onChanged: (valor) {
            if (valor == null) {
              return;
            }

            _actualizarEstado(() {
              if (valor == nuevaCategoria) {
                _crearNuevaCategoria = true;

                _categoriaSeleccionada = null;

                _categoriaController.clear();
              } else {
                _crearNuevaCategoria = false;

                _categoriaSeleccionada = valor;

                _categoriaController.text = valor;
              }
            });
          },
        ),

        if (_crearNuevaCategoria) ...[
          const SizedBox(height: 10),

          _campo(
            controller: _categoriaController,
            etiqueta: 'Nueva categoría',
            onChanged: (valor) {
              final limpio = valor.trim();

              _categoriaSeleccionada = limpio.isEmpty ? null : limpio;
            },
          ),
        ],
      ],
    );
  }

  Widget _datosPrincipales(bool esCelular) {
    final nombre = _campo(controller: _nombreController, etiqueta: 'Nombre');

    final categoria = _campo(
      controller: _categoriaController,
      etiqueta: 'Categoría',
    );

    final precio = _campo(
      controller: _precioController,
      etiqueta: 'Precio',
      prefijo: '\$ ',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );

    final seccion = DropdownButtonFormField<SeccionVenta>(
      value: _seccion,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: _decoracionCampo('Sección'),
      items: SeccionVenta.values.map((valor) {
        return DropdownMenuItem(
          value: valor,
          child: Text(_nombreSeccion(valor)),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        _actualizarEstado(() {
          _seccion = value;

          if (_esCombo) {
            _requiereSabores = false;
            _cantidadSaboresController.text = '0';
          }
        });
      },
    );

    if (esCelular) {
      return Column(
        children: [
          nombre,
          const SizedBox(height: 12),
          categoria,
          const SizedBox(height: 12),
          precio,
          const SizedBox(height: 12),
          seccion,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: nombre),
            const SizedBox(width: 12),
            Expanded(child: categoria),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: precio),
            const SizedBox(width: 12),
            Expanded(child: seccion),
          ],
        ),
      ],
    );
  }

  Widget _configuracionSabores() {
    return Column(
      children: [
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
            'Actívalo para productos anteriores con selección de sabores',
            style: TextStyle(color: ColoresApp.textoSecundario),
          ),
          onChanged: (value) {
            _actualizarEstado(() {
              _requiereSabores = value;

              if (!value) {
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
    );
  }

  Widget _configuracionCombo(bool esCelular) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 14 : 18),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresApp.principal.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Componentes del combo',
                      style: TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'El inventario descontará los productos realmente seleccionados.',
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _cargandoProductos ? null : _agregarComponente,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Agregar componente',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cargandoProductos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: ColoresApp.principal),
              ),
            )
          else if (_errorProductos != null)
            _mensajeErrorProductos()
          else if (_componentesCombo.isEmpty)
            _mensajeSinComponentes()
          else
            ...List.generate(_componentesCombo.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _componentesCombo.length - 1 ? 0 : 14,
                ),
                child: _tarjetaComponente(
                  componente: _componentesCombo[index],
                  index: index,
                  esCelular: esCelular,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _mensajeErrorProductos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            _errorProductos!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _cargarProductosDisponibles,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _mensajeSinComponentes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: ColoresApp.textoSecundario,
          ),
          SizedBox(height: 10),
          Text(
            'Todavía no hay componentes.',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Agrega los productos que incluye este combo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaComponente({
    required _ComponenteComboEditable componente,
    required int index,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColoresApp.principal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: ColoresApp.principal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  componente.nombreController.text.trim().isEmpty
                      ? 'Componente ${index + 1}'
                      : componente.nombreController.text.trim(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Subir',
                onPressed: index > 0
                    ? () {
                        _moverComponenteArriba(index);
                      }
                    : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                tooltip: 'Bajar',
                onPressed: index < _componentesCombo.length - 1
                    ? () {
                        _moverComponenteAbajo(index);
                      }
                    : null,
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
              IconButton(
                tooltip: 'Eliminar componente',
                onPressed: () {
                  _eliminarComponente(index);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (esCelular)
            Column(
              children: [
                _campo(
                  controller: componente.nombreController,
                  etiqueta: 'Nombre del componente',
                  onChanged: (_) {
                    _actualizarEstado(() {});
                  },
                ),
                const SizedBox(height: 12),
                _selectorProductoPredeterminado(componente),
                const SizedBox(height: 12),
                _campo(
                  controller: componente.cantidadController,
                  etiqueta: 'Cantidad',
                  keyboardType: TextInputType.number,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _campo(
                    controller: componente.nombreController,
                    etiqueta: 'Nombre del componente',
                    onChanged: (_) {
                      _actualizarEstado(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _selectorProductoPredeterminado(componente),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: _campo(
                    controller: componente.cantidadController,
                    etiqueta: 'Cantidad',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: componente.permiteSustitucion,
            activeColor: ColoresApp.principal,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Permitir sustituciones',
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text(
              'El producto predeterminado tendrá recargo cero.',
              style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 12),
            ),
            onChanged: (value) {
              _actualizarEstado(() {
                componente.permiteSustitucion = value;
              });
            },
          ),
          if (componente.permiteSustitucion) ...[
            const SizedBox(height: 8),
            _seccionSustituciones(componente),
          ],
        ],
      ),
    );
  }

  Widget _selectorProductoPredeterminado(_ComponenteComboEditable componente) {
    ProductoVenta? valor = _productosDisponibles.where((producto) {
      return producto.id == componente.productoPredeterminado.id;
    }).firstOrNull;

    valor ??= _productosDisponibles.isNotEmpty
        ? _productosDisponibles.first
        : null;

    if (valor != null && valor.id != componente.productoPredeterminado.id) {
      componente.productoPredeterminado = valor;
    }

    return DropdownButtonFormField<ProductoVenta>(
      value: valor,
      isExpanded: true,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: _decoracionCampo('Producto predeterminado'),
      items: _productosDisponibles.map((producto) {
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

        _actualizarEstado(() {
          componente.productoPredeterminado = producto;

          final opcionesAEliminar = componente.opciones
              .where((opcion) => opcion.producto.id == producto.id)
              .toList();

          for (final opcion in opcionesAEliminar) {
            opcion.dispose();
          }

          componente.opciones.removeWhere(
            (opcion) => opcion.producto.id == producto.id,
          );
        });
      },
    );
  }

  Widget _seccionSustituciones(_ComponenteComboEditable componente) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sustituciones permitidas',
                  style: TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _agregarSustitucion(componente);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(
                  foregroundColor: ColoresApp.principal,
                ),
              ),
            ],
          ),
          if (componente.opciones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No hay sustituciones configuradas.',
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...List.generate(componente.opciones.length, (index) {
              final opcion = componente.opciones[index];

              return Container(
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: ColoresApp.fondoSecundario,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opcion.producto.nombre,
                            style: const TextStyle(
                              color: ColoresApp.textoPrincipal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opcion.producto.categoria,
                            style: const TextStyle(
                              color: ColoresApp.textoSecundario,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 125,
                      child: _campo(
                        controller: opcion.recargoController,
                        etiqueta: 'Recargo',
                        prefijo: '\$ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar sustitución',
                      onPressed: () {
                        _eliminarSustitucion(componente, index);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _acciones() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.textoPrincipal,
              side: BorderSide(color: Colors.white.withOpacity(0.13)),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _cargandoProductos && _esCombo ? null : _guardar,
            icon: const Icon(Icons.save_rounded),
            label: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresApp.principal,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracionCampo(String etiqueta, {String? prefijo}) {
    return InputDecoration(
      labelText: etiqueta,
      prefixText: prefijo,
      labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
      prefixStyle: const TextStyle(color: ColoresApp.textoPrincipal),
      filled: true,
      fillColor: ColoresApp.fondoSecundario,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ColoresApp.principal),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    TextInputType? keyboardType,
    String? prefijo,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: _decoracionCampo(etiqueta, prefijo: prefijo),
    );
  }
}
