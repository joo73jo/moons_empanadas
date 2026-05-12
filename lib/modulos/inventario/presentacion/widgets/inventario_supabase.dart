import '../../../../nucleo/constantes/supabase_cliente.dart';

enum TipoMovimientoInventario {
  entrada,
  salida,
  ajuste,
}

class ItemInventario {
  final int id;
  final String nombre;
  final String categoria;
  final String unidadMedida;
  final double stockActual;
  final double stockMinimo;
  final double stockCritico;
  final double costoUnitario;
  final bool activo;
  final DateTime createdAt;

  const ItemInventario({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidadMedida,
    required this.stockActual,
    required this.stockMinimo,
    required this.stockCritico,
    required this.costoUnitario,
    required this.activo,
    required this.createdAt,
  });

  ItemInventario copyWith({
    int? id,
    String? nombre,
    String? categoria,
    String? unidadMedida,
    double? stockActual,
    double? stockMinimo,
    double? stockCritico,
    double? costoUnitario,
    bool? activo,
    DateTime? createdAt,
  }) {
    return ItemInventario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockCritico: stockCritico ?? this.stockCritico,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get nivelStock {
    if (stockActual <= stockCritico) return 'critico';
    if (stockActual <= stockMinimo) return 'minimo';
    return 'normal';
  }
}

class MovimientoInventario {
  final int id;
  final String tipoMovimiento;
  final double cantidad;
  final String unidadMedida;
  final double stockAnterior;
  final double stockNuevo;
  final String motivo;
  final DateTime createdAt;

  const MovimientoInventario({
    required this.id,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.unidadMedida,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.motivo,
    required this.createdAt,
  });
}

class InventarioSupabase {
  static Future<List<ItemInventario>> obtenerItems() async {
    final respuesta = await SupabaseCliente.cliente
        .from('ingredientes')
        .select()
        .eq('activo', true)
        .order('nombre');

    return respuesta.map<ItemInventario>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      return ItemInventario(
        id: mapa['id'] as int,
        nombre: (mapa['nombre'] ?? '').toString(),
        categoria: (mapa['categoria'] ?? '').toString(),
        unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
        stockActual: (mapa['stock_actual'] as num).toDouble(),
        stockMinimo: (mapa['stock_minimo'] as num).toDouble(),
        stockCritico: (mapa['stock_critico'] as num).toDouble(),
        costoUnitario: (mapa['costo_unitario'] as num).toDouble(),
        activo: mapa['activo'] as bool? ?? true,
        createdAt: DateTime.parse(mapa['created_at'] as String),
      );
    }).toList();
  }

  static Future<ItemInventario> crearItem(ItemInventario item) async {
    final respuesta = await SupabaseCliente.cliente
        .from('ingredientes')
        .insert({
          'nombre': item.nombre,
          'categoria': item.categoria,
          'unidad_medida': item.unidadMedida,
          'stock_actual': item.stockActual,
          'stock_minimo': item.stockMinimo,
          'stock_critico': item.stockCritico,
          'costo_unitario': item.costoUnitario,
          'activo': true,
        })
        .select()
        .single();

    final mapa = Map<String, dynamic>.from(respuesta);

    return ItemInventario(
      id: mapa['id'] as int,
      nombre: (mapa['nombre'] ?? '').toString(),
      categoria: (mapa['categoria'] ?? '').toString(),
      unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
      stockActual: (mapa['stock_actual'] as num).toDouble(),
      stockMinimo: (mapa['stock_minimo'] as num).toDouble(),
      stockCritico: (mapa['stock_critico'] as num).toDouble(),
      costoUnitario: (mapa['costo_unitario'] as num).toDouble(),
      activo: mapa['activo'] as bool? ?? true,
      createdAt: DateTime.parse(mapa['created_at'] as String),
    );
  }

  static Future<ItemInventario> actualizarItem(ItemInventario item) async {
    final respuesta = await SupabaseCliente.cliente
        .from('ingredientes')
        .update({
          'nombre': item.nombre,
          'categoria': item.categoria,
          'unidad_medida': item.unidadMedida,
          'stock_minimo': item.stockMinimo,
          'stock_critico': item.stockCritico,
          'costo_unitario': item.costoUnitario,
        })
        .eq('id', item.id)
        .select()
        .single();

    final mapa = Map<String, dynamic>.from(respuesta);

    return ItemInventario(
      id: mapa['id'] as int,
      nombre: (mapa['nombre'] ?? '').toString(),
      categoria: (mapa['categoria'] ?? '').toString(),
      unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
      stockActual: (mapa['stock_actual'] as num).toDouble(),
      stockMinimo: (mapa['stock_minimo'] as num).toDouble(),
      stockCritico: (mapa['stock_critico'] as num).toDouble(),
      costoUnitario: (mapa['costo_unitario'] as num).toDouble(),
      activo: mapa['activo'] as bool? ?? true,
      createdAt: DateTime.parse(mapa['created_at'] as String),
    );
  }

  static Future<void> desactivarItem(int id) async {
    await SupabaseCliente.cliente
        .from('ingredientes')
        .update({'activo': false})
        .eq('id', id);
  }

  static Future<List<MovimientoInventario>> obtenerMovimientosPorItem(
    int itemId,
  ) async {
    final respuesta = await SupabaseCliente.cliente
        .from('movimientos_stock')
        .select()
        .eq('tipo_item', 'ingrediente')
        .eq('item_id', itemId)
        .order('id', ascending: false)
        .limit(30);

    return respuesta.map<MovimientoInventario>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      return MovimientoInventario(
        id: mapa['id'] as int,
        tipoMovimiento: (mapa['tipo_movimiento'] ?? '').toString(),
        cantidad: (mapa['cantidad'] as num).toDouble(),
        unidadMedida: (mapa['unidad_medida'] ?? '').toString(),
        stockAnterior: (mapa['stock_anterior'] as num).toDouble(),
        stockNuevo: (mapa['stock_nuevo'] as num).toDouble(),
        motivo: (mapa['motivo'] ?? '').toString(),
        createdAt: DateTime.parse(mapa['created_at'] as String),
      );
    }).toList();
  }

  static Future<void> registrarMovimiento({
    required int itemId,
    required String usuarioLogin,
    required TipoMovimientoInventario tipo,
    required double valor,
    required String motivo,
  }) async {
    final usuario = await SupabaseCliente.cliente
        .from('usuarios')
        .select('id')
        .eq('usuario', usuarioLogin)
        .eq('activo', true)
        .single();

    final usuarioId = usuario['id'] as int;

    final item = await SupabaseCliente.cliente
        .from('ingredientes')
        .select()
        .eq('id', itemId)
        .single();

    final mapa = Map<String, dynamic>.from(item);
    final stockAnterior = (mapa['stock_actual'] as num).toDouble();
    final unidadMedida = (mapa['unidad_medida'] ?? '').toString();

    double cantidadMovimiento;
    double stockNuevo;
    String tipoMovimientoTexto;

    switch (tipo) {
      case TipoMovimientoInventario.entrada:
        cantidadMovimiento = valor;
        stockNuevo = stockAnterior + valor;
        tipoMovimientoTexto = 'entrada';
        break;
      case TipoMovimientoInventario.salida:
        if (valor > stockAnterior) {
          throw Exception('No hay suficiente stock para registrar la salida.');
        }
        cantidadMovimiento = valor;
        stockNuevo = stockAnterior - valor;
        tipoMovimientoTexto = 'salida';
        break;
      case TipoMovimientoInventario.ajuste:
        stockNuevo = valor;
        cantidadMovimiento = (stockNuevo - stockAnterior).abs();
        if (cantidadMovimiento == 0) {
          throw Exception('El ajuste no cambia el stock actual.');
        }
        tipoMovimientoTexto = 'ajuste';
        break;
    }

    await SupabaseCliente.cliente
        .from('ingredientes')
        .update({'stock_actual': stockNuevo})
        .eq('id', itemId);

    await SupabaseCliente.cliente.from('movimientos_stock').insert({
      'tipo_item': 'ingrediente',
      'item_id': itemId,
      'tipo_movimiento': tipoMovimientoTexto,
      'cantidad': cantidadMovimiento,
      'unidad_medida': unidadMedida,
      'stock_anterior': stockAnterior,
      'stock_nuevo': stockNuevo,
      'motivo': motivo,
      'referencia_tabla': 'ingredientes',
      'referencia_id': itemId,
      'usuario_id': usuarioId,
    });
  }
}