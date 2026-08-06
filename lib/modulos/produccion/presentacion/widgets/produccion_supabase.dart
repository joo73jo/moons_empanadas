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

class ProduccionHistorial {
  final int id;
  final int productoId;
  final String productoNombre;
  final String productoCategoria;
  final String usuarioNombre;
  final double cantidadOriginal;
  final double cantidadProducida;
  final String observacion;
  final bool corregida;
  final DateTime fechaRegistro;
  final DateTime? fechaUltimaCorreccion;
  final String usuarioUltimaCorreccion;

  const ProduccionHistorial({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.productoCategoria,
    required this.usuarioNombre,
    required this.cantidadOriginal,
    required this.cantidadProducida,
    required this.observacion,
    required this.corregida,
    required this.fechaRegistro,
    required this.fechaUltimaCorreccion,
    required this.usuarioUltimaCorreccion,
  });

  bool get fueModificada {
    return cantidadOriginal != cantidadProducida;
  }

  double get diferencia {
    return cantidadProducida - cantidadOriginal;
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
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .map<int>((item) => (item['producto_id'] as num).toInt())
        .toSet();

    return productosResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .where(
          (item) => productosConReceta.contains(
            (item['id'] as num).toInt(),
          ),
        )
        .map<ProductoProduccion>((item) {
          return ProductoProduccion(
            id: (item['id'] as num).toInt(),
            nombre: (item['nombre'] ?? '').toString(),
            categoria: (item['categoria'] ?? '').toString(),
            stockActual: (item['stock_actual'] as num?)?.toDouble() ?? 0,
            stockMinimo: (item['stock_minimo'] as num?)?.toDouble() ?? 0,
            stockCritico: (item['stock_critico'] as num?)?.toDouble() ?? 0,
            controlaStock: item['controla_stock'] as bool? ?? true,
          );
        })
        .toList();
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

    final receta = Map<String, dynamic>.from(recetas.first as Map);
    final recetaId = (receta['id'] as num).toInt();

    final detallesResponse = await SupabaseCliente.cliente
        .from('receta_detalle')
        .select('''
          ingrediente_id,
          cantidad,
          unidad_medida,
          ingrediente:ingredientes(
            nombre,
            categoria,
            stock_actual,
            activo
          )
        ''')
        .eq('receta_id', recetaId)
        .order('id');

    return detallesResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .where((item) {
          final ingredienteRaw = item['ingrediente'];

          if (ingredienteRaw == null) return false;

          final ingrediente = Map<String, dynamic>.from(
            ingredienteRaw as Map,
          );

          return ingrediente['activo'] == true;
        })
        .map<InsumoRecetaProduccion>((item) {
          final ingrediente = Map<String, dynamic>.from(
            item['ingrediente'] as Map,
          );

          return InsumoRecetaProduccion(
            ingredienteId: (item['ingrediente_id'] as num).toInt(),
            ingredienteNombre: (ingrediente['nombre'] ?? '').toString(),
            ingredienteCategoria:
                (ingrediente['categoria'] ?? '').toString(),
            unidadMedida: (item['unidad_medida'] ?? '').toString(),
            cantidadPorUnidad:
                (item['cantidad'] as num?)?.toDouble() ?? 0,
            stockActual:
                (ingrediente['stock_actual'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();
  }

  static Future<int> obtenerTotalIngredientesCriticos() async {
    final response = await SupabaseCliente.cliente
        .from('ingredientes')
        .select('id, stock_actual, stock_critico')
        .eq('activo', true);

    int total = 0;

    for (final item in response) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final stockActual =
          (mapa['stock_actual'] as num?)?.toDouble() ?? 0;

      final stockCritico =
          (mapa['stock_critico'] as num?)?.toDouble() ?? 0;

      if (stockActual <= stockCritico) {
        total++;
      }
    }

    return total;
  }

  static Future<List<ProduccionHistorial>> obtenerProduccionesRecientes({
    int limite = 50,
  }) async {
    final response = await SupabaseCliente.cliente
        .from('producciones')
        .select('''
          id,
          producto_id,
          cantidad_original,
          cantidad_producida,
          observacion,
          corregida,
          created_at,
          fecha_ultima_correccion,
          producto:productos(
            nombre,
            categoria
          ),
          usuario:usuarios!producciones_usuario_id_fkey(
            nombre
          ),
          usuario_correccion:usuarios!producciones_usuario_ultima_correccion_id_fkey(
            nombre
          )
        ''')
        .order('created_at', ascending: false)
        .limit(limite);

    return response.map<ProduccionHistorial>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final productoRaw = mapa['producto'];
      final usuarioRaw = mapa['usuario'];
      final usuarioCorreccionRaw = mapa['usuario_correccion'];

      final producto = productoRaw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(productoRaw as Map);

      final usuario = usuarioRaw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(usuarioRaw as Map);

      final usuarioCorreccion = usuarioCorreccionRaw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(usuarioCorreccionRaw as Map);

      final cantidadProducida =
          (mapa['cantidad_producida'] as num?)?.toDouble() ?? 0;

      final cantidadOriginal =
          (mapa['cantidad_original'] as num?)?.toDouble() ??
          cantidadProducida;

      return ProduccionHistorial(
        id: (mapa['id'] as num).toInt(),
        productoId: (mapa['producto_id'] as num).toInt(),
        productoNombre: (producto['nombre'] ?? 'Producto').toString(),
        productoCategoria: (producto['categoria'] ?? '').toString(),
        usuarioNombre: (usuario['nombre'] ?? 'Usuario').toString(),
        cantidadOriginal: cantidadOriginal,
        cantidadProducida: cantidadProducida,
        observacion: (mapa['observacion'] ?? '').toString(),
        corregida: mapa['corregida'] as bool? ?? false,
        fechaRegistro: _convertirFecha(mapa['created_at']),
        fechaUltimaCorreccion:
            mapa['fecha_ultima_correccion'] == null
            ? null
            : _convertirFecha(mapa['fecha_ultima_correccion']),
        usuarioUltimaCorreccion:
            (usuarioCorreccion['nombre'] ?? '').toString(),
      );
    }).toList();
  }

  static DateTime _convertirFecha(dynamic valor) {
    if (valor is DateTime) return valor;

    final texto = valor?.toString() ?? '';

    return DateTime.tryParse(texto) ?? DateTime.now();
  }

  static Future<int> registrarProduccion({
    required ProductoProduccion producto,
    required double cantidadProducida,
    required String usuarioLogin,
    required String observacion,
  }) async {
    if (cantidadProducida <= 0) {
      throw Exception(
        'La cantidad producida debe ser mayor a cero.',
      );
    }

    final resultado = await SupabaseCliente.cliente.rpc(
      'registrar_produccion',
      params: {
        'p_producto_id': producto.id,
        'p_cantidad_producida': cantidadProducida,
        'p_usuario_login': usuarioLogin.trim(),
        'p_observacion': observacion.trim().isEmpty
            ? null
            : observacion.trim(),
      },
    );

    if (resultado is int) {
      return resultado;
    }

    if (resultado is num) {
      return resultado.toInt();
    }

    return int.tryParse(resultado.toString()) ?? 0;
  }

  static Future<void> corregirProduccion({
    required int produccionId,
    required double cantidadNueva,
    required String usuarioLogin,
    required String motivo,
    required String observacionNueva,
  }) async {
    if (cantidadNueva <= 0) {
      throw Exception(
        'La nueva cantidad debe ser mayor a cero.',
      );
    }

    if (motivo.trim().isEmpty) {
      throw Exception(
        'Debes escribir el motivo de la corrección.',
      );
    }

    await SupabaseCliente.cliente.rpc(
      'corregir_produccion',
      params: {
        'p_produccion_id': produccionId,
        'p_cantidad_nueva': cantidadNueva,
        'p_usuario_login': usuarioLogin.trim(),
        'p_motivo': motivo.trim(),
        'p_observacion_nueva': observacionNueva.trim().isEmpty
            ? null
            : observacionNueva.trim(),
      },
    );
  }
}