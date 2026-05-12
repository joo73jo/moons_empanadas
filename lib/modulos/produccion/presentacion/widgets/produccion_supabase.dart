import '../../../../nucleo/constantes/supabase_cliente.dart';

class ProductoProduccion {
  final int id;
  final String nombre;
  final String categoria;
  final double stockActual;
  final double stockMinimo;
  final double stockCritico;
  final bool controlaStock;

  const ProductoProduccion({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.stockActual,
    required this.stockMinimo,
    required this.stockCritico,
    required this.controlaStock,
  });

  String get nivelStock {
    if (stockActual <= stockCritico) return 'critico';
    if (stockActual <= stockMinimo) return 'minimo';
    return 'normal';
  }
}

class InsumoRecetaProduccion {
  final int ingredienteId;
  final String ingredienteNombre;
  final String ingredienteCategoria;
  final String unidadMedida;
  final double cantidadPorUnidad;
  final double stockActual;

  const InsumoRecetaProduccion({
    required this.ingredienteId,
    required this.ingredienteNombre,
    required this.ingredienteCategoria,
    required this.unidadMedida,
    required this.cantidadPorUnidad,
    required this.stockActual,
  });

  double consumoPara(double cantidadProducida) {
    return cantidadPorUnidad * cantidadProducida;
  }
}

class ProduccionSupabase {
  static Future<List<ProductoProduccion>> obtenerProductos() async {
    final productosResponse = await SupabaseCliente.cliente
        .from('productos')
        .select(
          'id, nombre, categoria, stock_actual, stock_minimo, stock_critico, controla_stock',
        )
        .eq('activo', true)
        .eq('controla_stock', true)
        .order('nombre');

    final recetasResponse = await SupabaseCliente.cliente
        .from('recetas')
        .select('producto_id')
        .eq('activo', true);

    final Set<int> productosConReceta = recetasResponse
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
        .map<int>((item) => item['producto_id'] as int)
        .toSet();

    return productosResponse
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
        .where((item) => productosConReceta.contains(item['id'] as int))
        .map<ProductoProduccion>((item) {
      return ProductoProduccion(
        id: item['id'] as int,
        nombre: (item['nombre'] ?? '').toString(),
        categoria: (item['categoria'] ?? '').toString(),
        stockActual: (item['stock_actual'] as num).toDouble(),
        stockMinimo: (item['stock_minimo'] as num).toDouble(),
        stockCritico: (item['stock_critico'] as num).toDouble(),
        controlaStock: item['controla_stock'] as bool? ?? true,
      );
    }).toList();
  }

  static Future<List<InsumoRecetaProduccion>> obtenerRecetaProducto(
    int productoId,
  ) async {
    final recetas = await SupabaseCliente.cliente
        .from('recetas')
        .select('id')
        .eq('producto_id', productoId)
        .eq('activo', true)
        .limit(1);

    if (recetas.isEmpty) return [];

    final recetaId = (recetas.first as Map<String, dynamic>)['id'] as int;

    final detallesResponse = await SupabaseCliente.cliente
        .from('receta_detalle')
        .select('''
          ingrediente_id,
          cantidad,
          unidad_medida,
          ingrediente:ingredientes(nombre, categoria, stock_actual, activo)
        ''')
        .eq('receta_id', recetaId)
        .order('id');

    return detallesResponse
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
        .where((item) {
      final ingrediente = Map<String, dynamic>.from(item['ingrediente'] as Map);
      return ingrediente['activo'] == true;
    }).map<InsumoRecetaProduccion>((item) {
      final ingrediente = Map<String, dynamic>.from(item['ingrediente'] as Map);

      return InsumoRecetaProduccion(
        ingredienteId: item['ingrediente_id'] as int,
        ingredienteNombre: (ingrediente['nombre'] ?? '').toString(),
        ingredienteCategoria: (ingrediente['categoria'] ?? '').toString(),
        unidadMedida: (item['unidad_medida'] ?? '').toString(),
        cantidadPorUnidad: (item['cantidad'] as num).toDouble(),
        stockActual: (ingrediente['stock_actual'] as num).toDouble(),
      );
    }).toList();
  }

  static Future<int> obtenerTotalIngredientesCriticos() async {
    final response = await SupabaseCliente.cliente
        .from('ingredientes')
        .select('id, stock_actual, stock_critico')
        .eq('activo', true);

    int total = 0;

    for (final item in response) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final stockActual = (mapa['stock_actual'] as num).toDouble();
      final stockCritico = (mapa['stock_critico'] as num).toDouble();

      if (stockActual <= stockCritico) {
        total++;
      }
    }

    return total;
  }

  static Future<int> _obtenerUsuarioId(String usuarioLogin) async {
    final response = await SupabaseCliente.cliente
        .from('usuarios')
        .select('id')
        .eq('usuario', usuarioLogin)
        .eq('activo', true)
        .single();

    return response['id'] as int;
  }

  static Future<void> registrarProduccion({
    required ProductoProduccion producto,
    required double cantidadProducida,
    required String usuarioLogin,
    required String observacion,
  }) async {
    if (cantidadProducida <= 0) {
      throw Exception('La cantidad producida debe ser mayor a cero.');
    }

    final usuarioId = await _obtenerUsuarioId(usuarioLogin);
    final receta = await obtenerRecetaProducto(producto.id);

    if (receta.isEmpty) {
      throw Exception('El producto no tiene receta configurada.');
    }

    for (final insumo in receta) {
      final consumo = insumo.consumoPara(cantidadProducida);
      if (consumo > insumo.stockActual) {
        throw Exception(
          'Stock insuficiente de ${insumo.ingredienteNombre}. Necesitas ${consumo.toStringAsFixed(3)} ${insumo.unidadMedida} y solo hay ${insumo.stockActual.toStringAsFixed(3)}.',
        );
      }
    }

    final productoActualResponse = await SupabaseCliente.cliente
        .from('productos')
        .select('id, nombre, stock_actual')
        .eq('id', producto.id)
        .single();

    final productoActual = Map<String, dynamic>.from(productoActualResponse);
    final stockProductoAnterior =
        (productoActual['stock_actual'] as num).toDouble();

    final produccionInsertada = await SupabaseCliente.cliente
        .from('producciones')
        .insert({
          'producto_id': producto.id,
          'usuario_id': usuarioId,
          'cantidad_producida': cantidadProducida,
          'observacion': observacion.trim().isEmpty ? null : observacion.trim(),
        })
        .select('id')
        .single();

    final produccionId = produccionInsertada['id'] as int;

    for (final insumo in receta) {
      final consumo = insumo.consumoPara(cantidadProducida);
      final stockNuevo = insumo.stockActual - consumo;

      await SupabaseCliente.cliente
          .from('ingredientes')
          .update({'stock_actual': stockNuevo})
          .eq('id', insumo.ingredienteId);

      await SupabaseCliente.cliente.from('movimientos_stock').insert({
        'tipo_item': 'ingrediente',
        'item_id': insumo.ingredienteId,
        'tipo_movimiento': 'produccion_consumo',
        'cantidad': consumo,
        'unidad_medida': insumo.unidadMedida,
        'stock_anterior': insumo.stockActual,
        'stock_nuevo': stockNuevo,
        'motivo':
            'Producción de ${producto.nombre} (${cantidadProducida.toStringAsFixed(3)})',
        'referencia_tabla': 'producciones',
        'referencia_id': produccionId,
        'usuario_id': usuarioId,
      });
    }

    final stockProductoNuevo = stockProductoAnterior + cantidadProducida;

    await SupabaseCliente.cliente
        .from('productos')
        .update({'stock_actual': stockProductoNuevo})
        .eq('id', producto.id);

    await SupabaseCliente.cliente.from('movimientos_stock').insert({
      'tipo_item': 'producto',
      'item_id': producto.id,
      'tipo_movimiento': 'produccion_ingreso',
      'cantidad': cantidadProducida,
      'unidad_medida': 'unidad',
      'stock_anterior': stockProductoAnterior,
      'stock_nuevo': stockProductoNuevo,
      'motivo': 'Producción registrada de ${producto.nombre}',
      'referencia_tabla': 'producciones',
      'referencia_id': produccionId,
      'usuario_id': usuarioId,
    });
  }
}