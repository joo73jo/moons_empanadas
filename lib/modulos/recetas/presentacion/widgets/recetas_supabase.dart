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

class RecetaCompleta {
  final int recetaId;
  final int productoId;
  final String nombreReceta;
  final List<RecetaDetalleItem> detalles;

  const RecetaCompleta({
    required this.recetaId,
    required this.productoId,
    required this.nombreReceta,
    required this.detalles,
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

  final List<Map<String, dynamic>> productos = productosResponse
      .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  final Set<int> productosConReceta = recetasResponse
      .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
      .map<int>((item) => item['producto_id'] as int)
      .toSet();

  return productos.map<ProductoReceta>((mapa) {
    final int productoId = mapa['id'] as int;

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
        id: mapa['id'] as int,
        nombre: (mapa['nombre'] ?? '').toString(),
        categoria: (mapa['categoria'] ?? '').toString(),
        unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
        stockActual: (mapa['stock_actual'] as num).toDouble(),
      );
    }).toList();
  }

  static Future<RecetaCompleta?> obtenerRecetaPorProducto(int productoId) async {
    final recetas = await SupabaseCliente.cliente
        .from('recetas')
        .select('id, producto_id, nombre')
        .eq('producto_id', productoId)
        .eq('activo', true)
        .limit(1);

    if (recetas.isEmpty) return null;

    final recetaMapa = Map<String, dynamic>.from(recetas.first as Map);
    final recetaId = recetaMapa['id'] as int;

    final detalles = await SupabaseCliente.cliente
        .from('receta_detalle')
        .select('''
          id,
          ingrediente_id,
          cantidad,
          unidad_medida,
          ingrediente:ingredientes(nombre, categoria)
        ''')
        .eq('receta_id', recetaId)
        .order('id');

    final listaDetalles = detalles.map<RecetaDetalleItem>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final ingrediente = Map<String, dynamic>.from(mapa['ingrediente'] as Map);

      return RecetaDetalleItem(
        id: mapa['id'] as int,
        ingredienteId: mapa['ingrediente_id'] as int,
        ingredienteNombre: (ingrediente['nombre'] ?? '').toString(),
        ingredienteCategoria: (ingrediente['categoria'] ?? '').toString(),
        unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
        cantidad: (mapa['cantidad'] as num).toDouble(),
      );
    }).toList();

    return RecetaCompleta(
      recetaId: recetaId,
      productoId: recetaMapa['producto_id'] as int,
      nombreReceta: (recetaMapa['nombre'] ?? '').toString(),
      detalles: listaDetalles,
    );
  }

  static Future<void> guardarReceta({
    required int productoId,
    required String nombreReceta,
    required List<RecetaDetalleItem> detalles,
  }) async {
    if (detalles.isEmpty) {
      throw Exception('La receta debe tener al menos un ingrediente.');
    }

    final recetaExistente = await obtenerRecetaPorProducto(productoId);

    int recetaId;

    if (recetaExistente == null) {
      final insertada = await SupabaseCliente.cliente
          .from('recetas')
          .insert({
            'producto_id': productoId,
            'nombre': nombreReceta,
            'activo': true,
          })
          .select('id')
          .single();

      recetaId = insertada['id'] as int;
    } else {
      recetaId = recetaExistente.recetaId;

      await SupabaseCliente.cliente
          .from('recetas')
          .update({
            'nombre': nombreReceta,
            'activo': true,
          })
          .eq('id', recetaId);

      await SupabaseCliente.cliente
          .from('receta_detalle')
          .delete()
          .eq('receta_id', recetaId);
    }

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

  static Future<void> eliminarReceta(int productoId) async {
    final receta = await obtenerRecetaPorProducto(productoId);
    if (receta == null) return;

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