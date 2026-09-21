import '../../../../nucleo/constantes/supabase_cliente.dart';

class ProductoReceta {
  final int id;
  final String nombre;
  final String categoria;
  final bool tieneReceta;

  const ProductoReceta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.tieneReceta,
  });
}

class IngredienteRecetaDisponible {
  final int id;
  final String nombre;
  final String categoria;
  final String unidadMedida;
  final double stockActual;

  const IngredienteRecetaDisponible({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidadMedida,
    required this.stockActual,
  });
}

class RecetaReferenciaDisponible {
  final int recetaId;
  final int productoId;
  final String productoNombre;
  final String productoCategoria;
  final String recetaNombre;

  const RecetaReferenciaDisponible({
    required this.recetaId,
    required this.productoId,
    required this.productoNombre,
    required this.productoCategoria,
    required this.recetaNombre,
  });
}

class RecetaDetalleItem {
  final int? id;
  final int ingredienteId;
  final String ingredienteNombre;
  final String ingredienteCategoria;
  final String unidadMedida;
  final double cantidad;

  const RecetaDetalleItem({
    this.id,
    required this.ingredienteId,
    required this.ingredienteNombre,
    required this.ingredienteCategoria,
    required this.unidadMedida,
    required this.cantidad,
  });

  RecetaDetalleItem copyWith({
    int? id,
    int? ingredienteId,
    String? ingredienteNombre,
    String? ingredienteCategoria,
    String? unidadMedida,
    double? cantidad,
  }) {
    return RecetaDetalleItem(
      id: id ?? this.id,
      ingredienteId: ingredienteId ?? this.ingredienteId,
      ingredienteNombre: ingredienteNombre ?? this.ingredienteNombre,
      ingredienteCategoria: ingredienteCategoria ?? this.ingredienteCategoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}

class RecetaSubrecetaItem {
  final int? id;
  final int recetaHijaId;
  final int productoHijoId;
  final String productoNombre;
  final String productoCategoria;
  final String recetaNombre;
  final double cantidad;
  final String unidadMedida;

  const RecetaSubrecetaItem({
    this.id,
    required this.recetaHijaId,
    required this.productoHijoId,
    required this.productoNombre,
    required this.productoCategoria,
    required this.recetaNombre,
    required this.cantidad,
    this.unidadMedida = 'porcion',
  });

  RecetaSubrecetaItem copyWith({
    int? id,
    int? recetaHijaId,
    int? productoHijoId,
    String? productoNombre,
    String? productoCategoria,
    String? recetaNombre,
    double? cantidad,
    String? unidadMedida,
  }) {
    return RecetaSubrecetaItem(
      id: id ?? this.id,
      recetaHijaId: recetaHijaId ?? this.recetaHijaId,
      productoHijoId: productoHijoId ?? this.productoHijoId,
      productoNombre: productoNombre ?? this.productoNombre,
      productoCategoria: productoCategoria ?? this.productoCategoria,
      recetaNombre: recetaNombre ?? this.recetaNombre,
      cantidad: cantidad ?? this.cantidad,
      unidadMedida: unidadMedida ?? this.unidadMedida,
    );
  }
}

class RecetaCompleta {
  final int recetaId;
  final int productoId;
  final String nombreReceta;
  final List<RecetaDetalleItem> detalles;
  final List<RecetaSubrecetaItem> subrecetas;

  const RecetaCompleta({
    required this.recetaId,
    required this.productoId,
    required this.nombreReceta,
    required this.detalles,
    this.subrecetas = const [],
  });
}

class RecetasSupabase {
  static Future<List<ProductoReceta>> obtenerProductos() async {
    final productosResponse = await SupabaseCliente.cliente
        .from('productos')
        .select('id, nombre, categoria')
        .eq('activo', true)
        .order('nombre');

    final recetasResponse = await SupabaseCliente.cliente
        .from('recetas')
        .select('producto_id')
        .eq('activo', true);

    final productos = productosResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    final productosConReceta = recetasResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .map<int>((item) => (item['producto_id'] as num).toInt())
        .toSet();

    return productos.map<ProductoReceta>((mapa) {
      final productoId = (mapa['id'] as num).toInt();

      return ProductoReceta(
        id: productoId,
        nombre: (mapa['nombre'] ?? '').toString(),
        categoria: (mapa['categoria'] ?? '').toString(),
        tieneReceta: productosConReceta.contains(productoId),
      );
    }).toList();
  }

  static Future<List<IngredienteRecetaDisponible>> obtenerIngredientes() async {
    final respuesta = await SupabaseCliente.cliente
        .from('ingredientes')
        .select('id, nombre, categoria, unidad_medida, stock_actual')
        .eq('activo', true)
        .order('nombre');

    return respuesta.map<IngredienteRecetaDisponible>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      return IngredienteRecetaDisponible(
        id: (mapa['id'] as num).toInt(),
        nombre: (mapa['nombre'] ?? '').toString(),
        categoria: (mapa['categoria'] ?? '').toString(),
        unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
        stockActual: (mapa['stock_actual'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  static Future<List<RecetaReferenciaDisponible>> obtenerRecetasDisponibles({
    int? excluirProductoId,
  }) async {
    final recetas = await SupabaseCliente.cliente
        .from('recetas')
        .select('id, producto_id, nombre')
        .eq('activo', true);

    if (recetas.isEmpty) {
      return [];
    }

    final recetasMap = recetas
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .where(
          (item) =>
              excluirProductoId == null ||
              (item['producto_id'] as num).toInt() != excluirProductoId,
        )
        .toList();

    if (recetasMap.isEmpty) {
      return [];
    }

    final idsProductos = recetasMap
        .map<int>((item) => (item['producto_id'] as num).toInt())
        .toSet()
        .toList();

    final productos = await SupabaseCliente.cliente
        .from('productos')
        .select('id, nombre, categoria')
        .eq('activo', true)
        .inFilter('id', idsProductos);

    final productosPorId = <int, Map<String, dynamic>>{};

    for (final item in productos) {
      final mapa = Map<String, dynamic>.from(item as Map);

      productosPorId[(mapa['id'] as num).toInt()] = mapa;
    }

    final resultado = <RecetaReferenciaDisponible>[];

    for (final receta in recetasMap) {
      final productoId = (receta['producto_id'] as num).toInt();

      final producto = productosPorId[productoId];

      if (producto == null) {
        continue;
      }

      resultado.add(
        RecetaReferenciaDisponible(
          recetaId: (receta['id'] as num).toInt(),
          productoId: productoId,
          productoNombre: (producto['nombre'] ?? '').toString(),
          productoCategoria: (producto['categoria'] ?? '').toString(),
          recetaNombre: (receta['nombre'] ?? '').toString(),
        ),
      );
    }

    resultado.sort(
      (a, b) => a.productoNombre.toLowerCase().compareTo(
        b.productoNombre.toLowerCase(),
      ),
    );

    return resultado;
  }

  static Future<RecetaCompleta?> obtenerRecetaPorProducto(
    int productoId,
  ) async {
    final recetas = await SupabaseCliente.cliente
        .from('recetas')
        .select('id, producto_id, nombre')
        .eq('producto_id', productoId)
        .eq('activo', true)
        .limit(1);

    if (recetas.isEmpty) {
      return null;
    }

    final recetaMapa = Map<String, dynamic>.from(recetas.first as Map);

    final recetaId = (recetaMapa['id'] as num).toInt();

    final detalles = await SupabaseCliente.cliente
        .from('receta_detalle')
        .select('''
          id,
          ingrediente_id,
          cantidad,
          unidad_medida,
          ingrediente:ingredientes(
            nombre,
            categoria
          )
        ''')
        .eq('receta_id', recetaId)
        .order('id');

    final listaDetalles = detalles.map<RecetaDetalleItem>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final ingrediente = Map<String, dynamic>.from(mapa['ingrediente'] as Map);

      return RecetaDetalleItem(
        id: (mapa['id'] as num).toInt(),
        ingredienteId: (mapa['ingrediente_id'] as num).toInt(),
        ingredienteNombre: (ingrediente['nombre'] ?? '').toString(),
        ingredienteCategoria: (ingrediente['categoria'] ?? '').toString(),
        unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
        cantidad: (mapa['cantidad'] as num).toDouble(),
      );
    }).toList();

    final subResponse = await SupabaseCliente.cliente
        .from('receta_detalle_recetas')
        .select('id, receta_hija_id, cantidad, unidad_medida')
        .eq('receta_id', recetaId)
        .order('id');

    final subrecetas = <RecetaSubrecetaItem>[];

    if (subResponse.isNotEmpty) {
      final subMap = subResponse
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      final idsRecetas = subMap
          .map<int>((item) => (item['receta_hija_id'] as num).toInt())
          .toSet()
          .toList();

      final recetasHijas = await SupabaseCliente.cliente
          .from('recetas')
          .select('id, producto_id, nombre')
          .inFilter('id', idsRecetas);

      final recetasPorId = <int, Map<String, dynamic>>{};

      final idsProductos = <int>{};

      for (final item in recetasHijas) {
        final mapa = Map<String, dynamic>.from(item as Map);

        final id = (mapa['id'] as num).toInt();

        recetasPorId[id] = mapa;

        idsProductos.add((mapa['producto_id'] as num).toInt());
      }

      final productos = idsProductos.isEmpty
          ? <dynamic>[]
          : await SupabaseCliente.cliente
                .from('productos')
                .select('id, nombre, categoria')
                .inFilter('id', idsProductos.toList());

      final productosPorId = <int, Map<String, dynamic>>{};

      for (final item in productos) {
        final mapa = Map<String, dynamic>.from(item as Map);

        productosPorId[(mapa['id'] as num).toInt()] = mapa;
      }

      for (final item in subMap) {
        final recetaHijaId = (item['receta_hija_id'] as num).toInt();

        final recetaHija = recetasPorId[recetaHijaId];

        if (recetaHija == null) {
          continue;
        }

        final productoHijoId = (recetaHija['producto_id'] as num).toInt();

        final producto = productosPorId[productoHijoId];

        if (producto == null) {
          continue;
        }

        subrecetas.add(
          RecetaSubrecetaItem(
            id: (item['id'] as num).toInt(),
            recetaHijaId: recetaHijaId,
            productoHijoId: productoHijoId,
            productoNombre: (producto['nombre'] ?? '').toString(),
            productoCategoria: (producto['categoria'] ?? '').toString(),
            recetaNombre: (recetaHija['nombre'] ?? '').toString(),
            cantidad: (item['cantidad'] as num).toDouble(),
            unidadMedida: (item['unidad_medida'] ?? 'porcion').toString(),
          ),
        );
      }
    }

    return RecetaCompleta(
      recetaId: recetaId,
      productoId: (recetaMapa['producto_id'] as num).toInt(),
      nombreReceta: (recetaMapa['nombre'] ?? '').toString(),
      detalles: listaDetalles,
      subrecetas: subrecetas,
    );
  }

  static Future<void> guardarReceta({
    required int productoId,
    required String nombreReceta,
    required List<RecetaDetalleItem> detalles,
    List<RecetaSubrecetaItem> subrecetas = const [],
  }) async {
    if (detalles.isEmpty && subrecetas.isEmpty) {
      throw Exception(
        'La receta debe tener al menos un ingrediente o una receta.',
      );
    }

    for (final detalle in detalles) {
      if (detalle.cantidad <= 0) {
        throw Exception('Todas las cantidades deben ser mayores a cero.');
      }
    }

    for (final subreceta in subrecetas) {
      if (subreceta.cantidad <= 0) {
        throw Exception('Todas las cantidades deben ser mayores a cero.');
      }
    }

    final recetaExistente = await obtenerRecetaPorProducto(productoId);

    late int recetaId;
    bool creadaAhora = false;

    if (recetaExistente == null) {
      final insertada = await SupabaseCliente.cliente
          .from('recetas')
          .insert({
            'producto_id': productoId,
            'nombre': nombreReceta.trim(),
            'activo': true,
          })
          .select('id')
          .single();

      recetaId = (insertada['id'] as num).toInt();

      creadaAhora = true;
    } else {
      recetaId = recetaExistente.recetaId;
    }

    try {
      await _validarCiclos(recetaId: recetaId, subrecetas: subrecetas);
    } catch (e) {
      if (creadaAhora) {
        await SupabaseCliente.cliente
            .from('recetas')
            .delete()
            .eq('id', recetaId);
      }

      rethrow;
    }

    if (!creadaAhora) {
      await SupabaseCliente.cliente
          .from('recetas')
          .update({'nombre': nombreReceta.trim(), 'activo': true})
          .eq('id', recetaId);
    }

    await SupabaseCliente.cliente
        .from('receta_detalle')
        .delete()
        .eq('receta_id', recetaId);

    await SupabaseCliente.cliente
        .from('receta_detalle_recetas')
        .delete()
        .eq('receta_id', recetaId);

    if (detalles.isNotEmpty) {
      final inserts = detalles.map((detalle) {
        return {
          'receta_id': recetaId,
          'ingrediente_id': detalle.ingredienteId,
          'cantidad': detalle.cantidad,
          'unidad_medida': detalle.unidadMedida,
        };
      }).toList();

      await SupabaseCliente.cliente.from('receta_detalle').insert(inserts);
    }

    if (subrecetas.isNotEmpty) {
      final unicas = <int, RecetaSubrecetaItem>{};

      for (final subreceta in subrecetas) {
        unicas[subreceta.recetaHijaId] = subreceta;
      }

      final inserts = unicas.values.map((subreceta) {
        return {
          'receta_id': recetaId,
          'receta_hija_id': subreceta.recetaHijaId,
          'cantidad': subreceta.cantidad,
          'unidad_medida': subreceta.unidadMedida,
        };
      }).toList();

      await SupabaseCliente.cliente
          .from('receta_detalle_recetas')
          .insert(inserts);
    }
  }

  static Future<void> _validarCiclos({
    required int recetaId,
    required List<RecetaSubrecetaItem> subrecetas,
  }) async {
    final response = await SupabaseCliente.cliente
        .from('receta_detalle_recetas')
        .select('receta_id, receta_hija_id');

    final grafo = <int, Set<int>>{};

    for (final item in response) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final padre = (mapa['receta_id'] as num).toInt();

      final hija = (mapa['receta_hija_id'] as num).toInt();

      grafo.putIfAbsent(padre, () => <int>{});

      grafo[padre]!.add(hija);
    }

    grafo[recetaId] = subrecetas.map((item) => item.recetaHijaId).toSet();

    bool llegaA(int actual, int objetivo, Set<int> visitados) {
      if (actual == objetivo) {
        return true;
      }

      if (!visitados.add(actual)) {
        return false;
      }

      final siguientes = grafo[actual] ?? const <int>{};

      for (final siguiente in siguientes) {
        if (llegaA(siguiente, objetivo, visitados)) {
          return true;
        }
      }

      return false;
    }

    for (final subreceta in subrecetas) {
      if (subreceta.recetaHijaId == recetaId) {
        throw Exception('Una receta no puede utilizarse a sí misma.');
      }

      if (llegaA(subreceta.recetaHijaId, recetaId, <int>{})) {
        throw Exception(
          'No se puede agregar "${subreceta.productoNombre}" porque produciría un ciclo entre recetas.',
        );
      }
    }
  }

  static Future<List<RecetaDetalleItem>> resolverIngredientesFinales(
    int productoId,
  ) async {
    final recetasResponse = await SupabaseCliente.cliente
        .from('recetas')
        .select('id, producto_id')
        .eq('activo', true);

    final recetaPorProducto = <int, int>{};

    final idsRecetas = <int>[];

    for (final item in recetasResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final recetaId = (mapa['id'] as num).toInt();

      final producto = (mapa['producto_id'] as num).toInt();

      recetaPorProducto[producto] = recetaId;

      idsRecetas.add(recetaId);
    }

    final recetaInicial = recetaPorProducto[productoId];

    if (recetaInicial == null) {
      return [];
    }

    final detallesResponse = await SupabaseCliente.cliente
        .from('receta_detalle')
        .select('''
          receta_id,
          ingrediente_id,
          cantidad,
          unidad_medida,
          ingrediente:ingredientes(
            nombre,
            categoria
          )
        ''')
        .inFilter('receta_id', idsRecetas);

    final directos = <int, List<RecetaDetalleItem>>{};

    for (final item in detallesResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final recetaId = (mapa['receta_id'] as num).toInt();

      final ingrediente = Map<String, dynamic>.from(mapa['ingrediente'] as Map);

      directos.putIfAbsent(recetaId, () => []);

      directos[recetaId]!.add(
        RecetaDetalleItem(
          ingredienteId: (mapa['ingrediente_id'] as num).toInt(),
          ingredienteNombre: (ingrediente['nombre'] ?? '').toString(),
          ingredienteCategoria: (ingrediente['categoria'] ?? '').toString(),
          unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
          cantidad: (mapa['cantidad'] as num).toDouble(),
        ),
      );
    }

    final relacionesResponse = await SupabaseCliente.cliente
        .from('receta_detalle_recetas')
        .select('receta_id, receta_hija_id, cantidad');

    final hijos = <int, List<Map<String, dynamic>>>{};

    for (final item in relacionesResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final padre = (mapa['receta_id'] as num).toInt();

      hijos.putIfAbsent(padre, () => []);

      hijos[padre]!.add(mapa);
    }

    final acumulados = <String, RecetaDetalleItem>{};

    void expandir(int recetaId, double multiplicador, Set<int> ruta) {
      if (!ruta.add(recetaId)) {
        throw Exception('Se detectó un ciclo entre recetas.');
      }

      for (final detalle in directos[recetaId] ?? const <RecetaDetalleItem>[]) {
        final clave = '${detalle.ingredienteId}|${detalle.unidadMedida}';

        final cantidad = detalle.cantidad * multiplicador;

        final existente = acumulados[clave];

        if (existente == null) {
          acumulados[clave] = detalle.copyWith(cantidad: cantidad);
        } else {
          acumulados[clave] = existente.copyWith(
            cantidad: existente.cantidad + cantidad,
          );
        }
      }

      for (final relacion
          in hijos[recetaId] ?? const <Map<String, dynamic>>[]) {
        final hija = (relacion['receta_hija_id'] as num).toInt();

        final cantidad = (relacion['cantidad'] as num).toDouble();

        expandir(hija, multiplicador * cantidad, Set<int>.from(ruta));
      }
    }

    expandir(recetaInicial, 1, <int>{});

    final resultado = acumulados.values.toList();

    resultado.sort(
      (a, b) => a.ingredienteNombre.toLowerCase().compareTo(
        b.ingredienteNombre.toLowerCase(),
      ),
    );

    return resultado;
  }

  static Future<void> eliminarReceta(int productoId) async {
    final receta = await obtenerRecetaPorProducto(productoId);

    if (receta == null) {
      return;
    }

    final usos = await SupabaseCliente.cliente
        .from('receta_detalle_recetas')
        .select('id')
        .eq('receta_hija_id', receta.recetaId)
        .limit(1);

    if (usos.isNotEmpty) {
      throw Exception(
        'No puedes eliminar esta receta porque otra receta la está utilizando.',
      );
    }

    await SupabaseCliente.cliente
        .from('receta_detalle_recetas')
        .delete()
        .eq('receta_id', receta.recetaId);

    await SupabaseCliente.cliente
        .from('receta_detalle')
        .delete()
        .eq('receta_id', receta.recetaId);

    await SupabaseCliente.cliente
        .from('recetas')
        .delete()
        .eq('id', receta.recetaId);
  }
}
