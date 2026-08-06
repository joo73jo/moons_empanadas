import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../nucleo/constantes/supabase_cliente.dart';
import 'ventas_modelos.dart';

class ProductosSupabase {
  static Future<List<ProductoVenta>>
      obtenerProductos() async {
    try {
      final cliente = SupabaseCliente.cliente;

      final productosResponse = await cliente
          .from('productos')
          .select()
          .eq('activo', true)
          .order('id');

      final productosMap = <int, ProductoVenta>{};

      for (final item in productosResponse) {
        final mapa = Map<String, dynamic>.from(
          item as Map,
        );

        final producto = _mapearProductoBase(mapa);

        productosMap[producto.id] = producto;
      }

      if (productosMap.isEmpty) {
        return [];
      }

      final componentesResponse = await cliente
          .from('combo_componentes')
          .select('''
            id,
            combo_id,
            nombre_componente,
            producto_predeterminado_id,
            cantidad,
            permite_sustitucion,
            obligatorio,
            orden,
            activo
          ''')
          .eq('activo', true)
          .order('combo_id')
          .order('orden');

      final componentesMap =
          <int, _ComponenteComboTemporal>{};

      for (final item in componentesResponse) {
        final mapa = Map<String, dynamic>.from(
          item as Map,
        );

        final id = (mapa['id'] as num).toInt();

        componentesMap[id] =
            _ComponenteComboTemporal(
          id: id,
          comboId:
              (mapa['combo_id'] as num).toInt(),
          nombreComponente:
              (mapa['nombre_componente'] ?? '')
                  .toString(),
          productoPredeterminadoId:
              (mapa['producto_predeterminado_id']
                      as num)
                  .toInt(),
          cantidad:
              (mapa['cantidad'] as num?)?.toInt() ??
                  1,
          permiteSustitucion:
              mapa['permite_sustitucion']
                      as bool? ??
                  true,
          obligatorio:
              mapa['obligatorio'] as bool? ?? true,
          orden:
              (mapa['orden'] as num?)?.toInt() ??
                  0,
          activo:
              mapa['activo'] as bool? ?? true,
        );
      }

      if (componentesMap.isNotEmpty) {
        final opcionesResponse = await cliente
            .from('combo_componente_opciones')
            .select('''
              id,
              componente_id,
              producto_id,
              recargo,
              activo,
              orden
            ''')
            .eq('activo', true)
            .inFilter(
              'componente_id',
              componentesMap.keys.toList(),
            )
            .order('componente_id')
            .order('orden');

        for (final item in opcionesResponse) {
          final mapa = Map<String, dynamic>.from(
            item as Map,
          );

          final componenteId =
              (mapa['componente_id'] as num)
                  .toInt();

          final temporal =
              componentesMap[componenteId];

          if (temporal == null) {
            continue;
          }

          temporal.opciones.add(
            _OpcionComboTemporal(
              id: (mapa['id'] as num).toInt(),
              componenteId: componenteId,
              productoId:
                  (mapa['producto_id'] as num)
                      .toInt(),
              recargo:
                  (mapa['recargo'] as num?)
                          ?.toDouble() ??
                      0,
              activo:
                  mapa['activo'] as bool? ?? true,
              orden:
                  (mapa['orden'] as num?)
                          ?.toInt() ??
                      0,
            ),
          );
        }
      }

      final componentesPorCombo =
          <int, List<ComponenteCombo>>{};

      for (final temporal
          in componentesMap.values) {
        final productoPredeterminado =
            productosMap[
                temporal.productoPredeterminadoId];

        if (productoPredeterminado == null) {
          continue;
        }

        final opciones = <OpcionComponenteCombo>[];

        for (final opcionTemporal
            in temporal.opciones) {
          final productoOpcion =
              productosMap[opcionTemporal.productoId];

          if (productoOpcion == null) {
            continue;
          }

          opciones.add(
            OpcionComponenteCombo(
              id: opcionTemporal.id,
              componenteId:
                  opcionTemporal.componenteId,
              producto: productoOpcion,
              recargo: opcionTemporal.recargo,
              activo: opcionTemporal.activo,
              orden: opcionTemporal.orden,
            ),
          );
        }

        opciones.sort(
          (a, b) {
            final comparacionOrden =
                a.orden.compareTo(b.orden);

            if (comparacionOrden != 0) {
              return comparacionOrden;
            }

            return a.producto.nombre
                .toLowerCase()
                .compareTo(
                  b.producto.nombre.toLowerCase(),
                );
          },
        );

        componentesPorCombo.putIfAbsent(
          temporal.comboId,
          () => [],
        );

        componentesPorCombo[temporal.comboId]!.add(
          ComponenteCombo(
            id: temporal.id,
            comboId: temporal.comboId,
            nombreComponente:
                temporal.nombreComponente,
            productoPredeterminado:
                productoPredeterminado,
            cantidad: temporal.cantidad,
            permiteSustitucion:
                temporal.permiteSustitucion,
            obligatorio: temporal.obligatorio,
            orden: temporal.orden,
            activo: temporal.activo,
            opciones: opciones,
          ),
        );
      }

      for (final componentes
          in componentesPorCombo.values) {
        componentes.sort(
          (a, b) {
            final comparacionOrden =
                a.orden.compareTo(b.orden);

            if (comparacionOrden != 0) {
              return comparacionOrden;
            }

            return a.nombreComponente
                .toLowerCase()
                .compareTo(
                  b.nombreComponente.toLowerCase(),
                );
          },
        );
      }

      final resultado = productosMap.values.map(
        (producto) {
          return producto.copyWith(
            componentesCombo:
                componentesPorCombo[producto.id] ??
                    const [],
          );
        },
      ).toList();

      resultado.sort(
        (a, b) => a.id.compareTo(b.id),
      );

      return resultado;
    } on PostgrestException catch (e) {
      throw Exception(
        'Supabase productos: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error cargando productos: $e',
      );
    }
  }

  static Future<ProductoVenta> crearProducto(
    ProductoVenta producto,
  ) async {
    try {
      final respuesta =
          await SupabaseCliente.cliente
              .from('productos')
              .insert({
                'nombre': producto.nombre.trim(),
                'categoria':
                    producto.categoria.trim(),
                'precio': producto.precio,
                'seccion': _mapearSeccionTexto(
                  producto.seccion,
                ),
                'requiere_sabores':
                    producto.requiereSabores,
                'cantidad_sabores':
                    producto.cantidadSabores,
                'controla_stock':
                    producto.controlaStock,
                'stock_actual':
                    producto.stockActual,
                'stock_minimo':
                    producto.stockMinimo,
                'stock_critico':
                    producto.stockCritico,
                'activo': true,
              })
              .select()
              .single();

      final creado = _mapearProductoBase(
        Map<String, dynamic>.from(respuesta),
      );

      if (producto.componentesCombo.isNotEmpty) {
        await guardarConfiguracionCombo(
          comboId: creado.id,
          componentes: producto.componentesCombo,
        );

        return creado.copyWith(
          componentesCombo:
              await obtenerComponentesCombo(
            creado.id,
          ),
        );
      }

      return creado;
    } on PostgrestException catch (e) {
      throw Exception(
        'Error creando producto: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error creando producto: $e',
      );
    }
  }

  static Future<ProductoVenta> actualizarProducto(
    ProductoVenta producto,
  ) async {
    try {
      final respuesta =
          await SupabaseCliente.cliente
              .from('productos')
              .update({
                'nombre': producto.nombre.trim(),
                'categoria':
                    producto.categoria.trim(),
                'precio': producto.precio,
                'seccion': _mapearSeccionTexto(
                  producto.seccion,
                ),
                'requiere_sabores':
                    producto.requiereSabores,
                'cantidad_sabores':
                    producto.cantidadSabores,
                'controla_stock':
                    producto.controlaStock,
                'stock_minimo':
                    producto.stockMinimo,
                'stock_critico':
                    producto.stockCritico,
              })
              .eq('id', producto.id)
              .select()
              .single();

      final actualizado = _mapearProductoBase(
        Map<String, dynamic>.from(respuesta),
      );

      if (producto.seccion ==
          SeccionVenta.combos) {
        await guardarConfiguracionCombo(
          comboId: producto.id,
          componentes: producto.componentesCombo,
        );
      } else {
        await eliminarConfiguracionCombo(
          producto.id,
        );
      }

      return actualizado.copyWith(
        componentesCombo:
            producto.seccion ==
                    SeccionVenta.combos
                ? await obtenerComponentesCombo(
                    producto.id,
                  )
                : const [],
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Error actualizando producto: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error actualizando producto: $e',
      );
    }
  }

  static Future<void> eliminarProducto(
    int id,
  ) async {
    try {
      await SupabaseCliente.cliente
          .from('productos')
          .update({
            'activo': false,
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error eliminando producto: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error eliminando producto: $e',
      );
    }
  }

  static Future<List<ComponenteCombo>>
      obtenerComponentesCombo(
    int comboId,
  ) async {
    try {
      final todosProductos =
          await SupabaseCliente.cliente
              .from('productos')
              .select()
              .eq('activo', true)
              .order('id');

      final productosMap =
          <int, ProductoVenta>{};

      for (final item in todosProductos) {
        final producto = _mapearProductoBase(
          Map<String, dynamic>.from(
            item as Map,
          ),
        );

        productosMap[producto.id] = producto;
      }

      final componentesResponse =
          await SupabaseCliente.cliente
              .from('combo_componentes')
              .select('''
                id,
                combo_id,
                nombre_componente,
                producto_predeterminado_id,
                cantidad,
                permite_sustitucion,
                obligatorio,
                orden,
                activo
              ''')
              .eq('combo_id', comboId)
              .eq('activo', true)
              .order('orden');

      if (componentesResponse.isEmpty) {
        return [];
      }

      final componentesTemporales =
          <int, _ComponenteComboTemporal>{};

      for (final item in componentesResponse) {
        final mapa = Map<String, dynamic>.from(
          item as Map,
        );

        final id = (mapa['id'] as num).toInt();

        componentesTemporales[id] =
            _ComponenteComboTemporal(
          id: id,
          comboId:
              (mapa['combo_id'] as num).toInt(),
          nombreComponente:
              (mapa['nombre_componente'] ?? '')
                  .toString(),
          productoPredeterminadoId:
              (mapa['producto_predeterminado_id']
                      as num)
                  .toInt(),
          cantidad:
              (mapa['cantidad'] as num?)
                      ?.toInt() ??
                  1,
          permiteSustitucion:
              mapa['permite_sustitucion']
                      as bool? ??
                  true,
          obligatorio:
              mapa['obligatorio'] as bool? ?? true,
          orden:
              (mapa['orden'] as num?)
                      ?.toInt() ??
                  0,
          activo:
              mapa['activo'] as bool? ?? true,
        );
      }

      final opcionesResponse =
          await SupabaseCliente.cliente
              .from('combo_componente_opciones')
              .select('''
                id,
                componente_id,
                producto_id,
                recargo,
                activo,
                orden
              ''')
              .eq('activo', true)
              .inFilter(
                'componente_id',
                componentesTemporales.keys
                    .toList(),
              )
              .order('componente_id')
              .order('orden');

      for (final item in opcionesResponse) {
        final mapa = Map<String, dynamic>.from(
          item as Map,
        );

        final componenteId =
            (mapa['componente_id'] as num)
                .toInt();

        componentesTemporales[componenteId]
            ?.opciones
            .add(
              _OpcionComboTemporal(
                id: (mapa['id'] as num).toInt(),
                componenteId: componenteId,
                productoId:
                    (mapa['producto_id'] as num)
                        .toInt(),
                recargo:
                    (mapa['recargo'] as num?)
                            ?.toDouble() ??
                        0,
                activo:
                    mapa['activo'] as bool? ??
                        true,
                orden:
                    (mapa['orden'] as num?)
                            ?.toInt() ??
                        0,
              ),
            );
      }

      final resultado = <ComponenteCombo>[];

      for (final temporal
          in componentesTemporales.values) {
        final predeterminado =
            productosMap[
                temporal.productoPredeterminadoId];

        if (predeterminado == null) {
          continue;
        }

        final opciones = <OpcionComponenteCombo>[];

        for (final opcionTemporal
            in temporal.opciones) {
          final producto =
              productosMap[opcionTemporal.productoId];

          if (producto == null) {
            continue;
          }

          opciones.add(
            OpcionComponenteCombo(
              id: opcionTemporal.id,
              componenteId:
                  opcionTemporal.componenteId,
              producto: producto,
              recargo: opcionTemporal.recargo,
              activo: opcionTemporal.activo,
              orden: opcionTemporal.orden,
            ),
          );
        }

        resultado.add(
          ComponenteCombo(
            id: temporal.id,
            comboId: temporal.comboId,
            nombreComponente:
                temporal.nombreComponente,
            productoPredeterminado:
                predeterminado,
            cantidad: temporal.cantidad,
            permiteSustitucion:
                temporal.permiteSustitucion,
            obligatorio: temporal.obligatorio,
            orden: temporal.orden,
            activo: temporal.activo,
            opciones: opciones,
          ),
        );
      }

      resultado.sort(
        (a, b) => a.orden.compareTo(b.orden),
      );

      return resultado;
    } on PostgrestException catch (e) {
      throw Exception(
        'Error cargando componentes: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error cargando componentes: $e',
      );
    }
  }

  static Future<void> guardarConfiguracionCombo({
    required int comboId,
    required List<ComponenteCombo> componentes,
  }) async {
    if (comboId <= 0) {
      throw Exception(
        'El combo debe estar guardado antes de configurar sus componentes.',
      );
    }

    final cliente = SupabaseCliente.cliente;

    try {
      final existentes = await cliente
          .from('combo_componentes')
          .select('id')
          .eq('combo_id', comboId);

      final idsExistentes = existentes
          .map<int>(
            (item) => ((item as Map)['id'] as num)
                .toInt(),
          )
          .toList();

      if (idsExistentes.isNotEmpty) {
        await cliente
            .from('combo_componente_opciones')
            .delete()
            .inFilter(
              'componente_id',
              idsExistentes,
            );
      }

      await cliente
          .from('combo_componentes')
          .delete()
          .eq('combo_id', comboId);

      if (componentes.isEmpty) {
        return;
      }

      final componentesOrdenados =
          List<ComponenteCombo>.from(componentes);

      componentesOrdenados.sort(
        (a, b) => a.orden.compareTo(b.orden),
      );

      for (int indice = 0;
          indice < componentesOrdenados.length;
          indice++) {
        final componente =
            componentesOrdenados[indice];

        if (componente.nombreComponente
            .trim()
            .isEmpty) {
          throw Exception(
            'Todos los componentes deben tener un nombre.',
          );
        }

        if (componente.cantidad <= 0) {
          throw Exception(
            'La cantidad del componente "${componente.nombreComponente}" debe ser mayor a cero.',
          );
        }

        if (componente.productoPredeterminado.id <=
            0) {
          throw Exception(
            'Debes elegir el producto predeterminado de "${componente.nombreComponente}".',
          );
        }

        if (componente.productoPredeterminado.id ==
            comboId) {
          throw Exception(
            'El combo no puede contenerse a sí mismo.',
          );
        }

        final componenteInsertado = await cliente
            .from('combo_componentes')
            .insert({
              'combo_id': comboId,
              'nombre_componente':
                  componente.nombreComponente.trim(),
              'producto_predeterminado_id':
                  componente
                      .productoPredeterminado.id,
              'cantidad': componente.cantidad,
              'permite_sustitucion':
                  componente.permiteSustitucion,
              'obligatorio':
                  componente.obligatorio,
              'orden': indice,
              'activo': true,
            })
            .select('id')
            .single();

        final componenteId =
            (componenteInsertado['id'] as num)
                .toInt();

        if (!componente.permiteSustitucion ||
            componente.opciones.isEmpty) {
          continue;
        }

        final opcionesUnicas =
            <int, OpcionComponenteCombo>{};

        for (final opcion in componente.opciones) {
          if (opcion.producto.id <= 0) {
            continue;
          }

          if (opcion.producto.id == comboId) {
            throw Exception(
              'El combo no puede ser una opción de sí mismo.',
            );
          }

          if (opcion.producto.id ==
              componente
                  .productoPredeterminado.id) {
            continue;
          }

          if (opcion.recargo < 0) {
            throw Exception(
              'El recargo de ${opcion.producto.nombre} no puede ser negativo.',
            );
          }

          opcionesUnicas[opcion.producto.id] =
              opcion;
        }

        final opcionesOrdenadas =
            opcionesUnicas.values.toList();

        opcionesOrdenadas.sort(
          (a, b) => a.orden.compareTo(b.orden),
        );

        if (opcionesOrdenadas.isNotEmpty) {
          final filas = <Map<String, dynamic>>[];

          for (int opcionIndice = 0;
              opcionIndice <
                  opcionesOrdenadas.length;
              opcionIndice++) {
            final opcion =
                opcionesOrdenadas[opcionIndice];

            filas.add({
              'componente_id': componenteId,
              'producto_id': opcion.producto.id,
              'recargo': opcion.recargo,
              'activo': true,
              'orden': opcionIndice,
            });
          }

          await cliente
              .from('combo_componente_opciones')
              .insert(filas);
        }
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Error guardando configuración del combo: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error guardando configuración del combo: $e',
      );
    }
  }

  static Future<void> eliminarConfiguracionCombo(
    int comboId,
  ) async {
    final cliente = SupabaseCliente.cliente;

    try {
      final componentes = await cliente
          .from('combo_componentes')
          .select('id')
          .eq('combo_id', comboId);

      final ids = componentes
          .map<int>(
            (item) => ((item as Map)['id'] as num)
                .toInt(),
          )
          .toList();

      if (ids.isNotEmpty) {
        await cliente
            .from('combo_componente_opciones')
            .delete()
            .inFilter(
              'componente_id',
              ids,
            );
      }

      await cliente
          .from('combo_componentes')
          .delete()
          .eq('combo_id', comboId);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error eliminando configuración del combo: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error eliminando configuración del combo: $e',
      );
    }
  }

  static ProductoVenta _mapearProductoBase(
    Map<String, dynamic> mapa,
  ) {
    return ProductoVenta(
      id: (mapa['id'] as num).toInt(),
      nombre:
          (mapa['nombre'] ?? '').toString(),
      categoria:
          (mapa['categoria'] ?? '').toString(),
      precio:
          (mapa['precio'] as num?)?.toDouble() ??
              0,
      seccion: _mapearSeccion(
        (mapa['seccion'] ?? '').toString(),
      ),
      requiereSabores:
          mapa['requiere_sabores'] as bool? ??
              false,
      cantidadSabores:
          (mapa['cantidad_sabores'] as num?)
                  ?.toInt() ??
              0,
      controlaStock:
          mapa['controla_stock'] as bool? ??
              true,
      stockActual:
          (mapa['stock_actual'] as num?)
                  ?.toDouble() ??
              0,
      stockMinimo:
          (mapa['stock_minimo'] as num?)
                  ?.toDouble() ??
              0,
      stockCritico:
          (mapa['stock_critico'] as num?)
                  ?.toDouble() ??
              0,
      componentesCombo: const [],
    );
  }

  static SeccionVenta _mapearSeccion(
    String valor,
  ) {
    switch (valor) {
      case 'individuales':
        return SeccionVenta.individuales;

      case 'combos':
        return SeccionVenta.combos;

      case 'uber':
        return SeccionVenta.uber;

      default:
        return SeccionVenta.individuales;
    }
  }

  static String _mapearSeccionTexto(
    SeccionVenta valor,
  ) {
    switch (valor) {
      case SeccionVenta.individuales:
        return 'individuales';

      case SeccionVenta.combos:
        return 'combos';

      case SeccionVenta.uber:
        return 'uber';
    }
  }
}

class _ComponenteComboTemporal {
  final int id;
  final int comboId;
  final String nombreComponente;
  final int productoPredeterminadoId;
  final int cantidad;
  final bool permiteSustitucion;
  final bool obligatorio;
  final int orden;
  final bool activo;

  final List<_OpcionComboTemporal> opciones = [];

  _ComponenteComboTemporal({
    required this.id,
    required this.comboId,
    required this.nombreComponente,
    required this.productoPredeterminadoId,
    required this.cantidad,
    required this.permiteSustitucion,
    required this.obligatorio,
    required this.orden,
    required this.activo,
  });
}

class _OpcionComboTemporal {
  final int id;
  final int componenteId;
  final int productoId;
  final double recargo;
  final bool activo;
  final int orden;

  const _OpcionComboTemporal({
    required this.id,
    required this.componenteId,
    required this.productoId,
    required this.recargo,
    required this.activo,
    required this.orden,
  });
}