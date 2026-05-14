import '../../../../nucleo/constantes/supabase_cliente.dart';

class VentaHistorial {
  final int id;
  final DateTime fecha;
  final String metodoPago;
  final String? banco;
  final String? datofono;
  final double subtotal;
  final double total;
  final String vendedorNombre;
  final String vendedorLogin;
  final String estado;
  final String? motivoAnulacion;
  final DateTime? fechaAnulacion;
  final List<DetalleVentaHistorial> detalles;

  const VentaHistorial({
    required this.id,
    required this.fecha,
    required this.metodoPago,
    required this.banco,
    required this.datofono,
    required this.subtotal,
    required this.total,
    required this.vendedorNombre,
    required this.vendedorLogin,
    required this.estado,
    required this.motivoAnulacion,
    required this.fechaAnulacion,
    required this.detalles,
  });

  bool get estaAnulada => estado == 'anulada';
}

class DetalleVentaHistorial {
  final int id;
  final String nombreProducto;
  final String categoriaProducto;
  final double precioUnitario;
  final int cantidad;
  final double subtotal;
  final List<String> sabores;

  const DetalleVentaHistorial({
    required this.id,
    required this.nombreProducto,
    required this.categoriaProducto,
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
    required this.sabores,
  });
}

class VentasHistorialSupabase {
  static Future<List<VentaHistorial>> obtenerVentas({
    int limite = 100,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    dynamic query = SupabaseCliente.cliente.from('ventas').select('''
      id,
      created_at,
      metodo_pago,
      banco,
      datofono,
      subtotal,
      total,
      estado,
      motivo_anulacion,
      fecha_anulacion,
      usuario:usuarios!ventas_usuario_id_fkey(nombre, usuario)
    ''');

    if (fechaInicio != null) {
      query = query.gte('created_at', _fechaSql(fechaInicio));
    }

    if (fechaFin != null) {
      query = query.lte('created_at', _fechaSql(fechaFin));
    }

    final ventasResponse = await query.order('id', ascending: false).limit(limite);

    final List<Map<String, dynamic>> ventas = ventasResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    if (ventas.isEmpty) return [];

    final idsVentas = ventas.map((v) => v['id'] as int).toList();

    final detallesResponse = await SupabaseCliente.cliente
        .from('detalle_venta')
        .select('''
          id,
          venta_id,
          nombre_producto,
          categoria_producto,
          precio_unitario,
          cantidad,
          subtotal,
          sabores
        ''')
        .inFilter('venta_id', idsVentas)
        .order('id', ascending: true);

    final List<Map<String, dynamic>> detalles = detallesResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    final Map<int, List<DetalleVentaHistorial>> detallesPorVenta = {};

    for (final detalle in detalles) {
      final ventaId = detalle['venta_id'] as int;

      final saboresRaw = detalle['sabores'];
      final List<String> sabores = saboresRaw is List
          ? saboresRaw.map((e) => e.toString()).toList()
          : <String>[];

      final detalleMapeado = DetalleVentaHistorial(
        id: detalle['id'] as int,
        nombreProducto: (detalle['nombre_producto'] ?? '').toString(),
        categoriaProducto: (detalle['categoria_producto'] ?? '').toString(),
        precioUnitario: (detalle['precio_unitario'] as num).toDouble(),
        cantidad: detalle['cantidad'] as int,
        subtotal: (detalle['subtotal'] as num).toDouble(),
        sabores: sabores,
      );

      detallesPorVenta.putIfAbsent(ventaId, () => []);
      detallesPorVenta[ventaId]!.add(detalleMapeado);
    }

    return ventas.map((venta) {
      final usuario = venta['usuario'] == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(venta['usuario'] as Map);

      final fechaAnulacionRaw = venta['fecha_anulacion'];

      return VentaHistorial(
        id: venta['id'] as int,
        fecha: DateTime.parse(venta['created_at'] as String),
        metodoPago: (venta['metodo_pago'] ?? '').toString(),
        banco: venta['banco']?.toString(),
        datofono: venta['datofono']?.toString(),
        subtotal: (venta['subtotal'] as num).toDouble(),
        total: (venta['total'] as num).toDouble(),
        vendedorNombre: (usuario['nombre'] ?? '').toString(),
        vendedorLogin: (usuario['usuario'] ?? '').toString(),
        estado: (venta['estado'] ?? 'pagada').toString(),
        motivoAnulacion: venta['motivo_anulacion']?.toString(),
        fechaAnulacion: fechaAnulacionRaw == null
            ? null
            : DateTime.parse(fechaAnulacionRaw.toString()),
        detalles: detallesPorVenta[venta['id'] as int] ?? [],
      );
    }).toList();
  }

  static Future<void> anularVenta({
    required int ventaId,
    required String motivo,
  }) async {
    final cliente = SupabaseCliente.cliente;

    if (motivo.trim().isEmpty) {
      throw Exception('Debes escribir una razón para anular la venta.');
    }

    final ventaResponse = await cliente
        .from('ventas')
        .select('id, caja_id, estado, total')
        .eq('id', ventaId)
        .single();

    final venta = Map<String, dynamic>.from(ventaResponse);

    if ((venta['estado'] ?? '').toString() == 'anulada') {
      throw Exception('Esta venta ya está anulada.');
    }

    final int cajaId = venta['caja_id'] as int;
    final double totalVenta = (venta['total'] as num).toDouble();

    final pagosResponse = await cliente
        .from('pagos_venta')
        .select('metodo_pago, monto')
        .eq('venta_id', ventaId);

    final pagos = pagosResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    final cajaResponse = await cliente
        .from('cajas')
        .select(
          'total_efectivo, total_transferencia, total_tarjeta, total_ventas',
        )
        .eq('id', cajaId)
        .single();

    final caja = Map<String, dynamic>.from(cajaResponse);

    double totalEfectivo =
        (caja['total_efectivo'] as num?)?.toDouble() ?? 0;
    double totalTransferencia =
        (caja['total_transferencia'] as num?)?.toDouble() ?? 0;
    double totalTarjeta = (caja['total_tarjeta'] as num?)?.toDouble() ?? 0;
    double totalVentas = (caja['total_ventas'] as num?)?.toDouble() ?? 0;

    for (final pago in pagos) {
      final metodo = (pago['metodo_pago'] ?? '').toString();
      final monto = (pago['monto'] as num).toDouble();

      if (metodo == 'efectivo') {
        totalEfectivo -= monto;
      } else if (metodo == 'transferencia') {
        totalTransferencia -= monto;
      } else if (metodo == 'tarjeta') {
        totalTarjeta -= monto;
      }
    }

    totalVentas -= totalVenta;

    if (totalEfectivo < 0) totalEfectivo = 0;
    if (totalTransferencia < 0) totalTransferencia = 0;
    if (totalTarjeta < 0) totalTarjeta = 0;
    if (totalVentas < 0) totalVentas = 0;

    await cliente.from('cajas').update({
      'total_efectivo': totalEfectivo,
      'total_transferencia': totalTransferencia,
      'total_tarjeta': totalTarjeta,
      'total_ventas': totalVentas,
    }).eq('id', cajaId);

    final movimientosResponse = await cliente
        .from('movimientos_stock')
        .select('''
          tipo_item,
          item_id,
          cantidad,
          unidad_medida,
          stock_nuevo
        ''')
        .eq('referencia_tabla', 'ventas')
        .eq('referencia_id', ventaId);

    final movimientos = movimientosResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    for (final movimiento in movimientos) {
      final tipoItem = (movimiento['tipo_item'] ?? '').toString();

      if (tipoItem != 'producto') continue;

      final itemId = movimiento['item_id'] as int;
      final cantidad = (movimiento['cantidad'] as num).toDouble();
      final unidadMedida = (movimiento['unidad_medida'] ?? 'unidad').toString();

      final productoResponse = await cliente
          .from('productos')
          .select('id, nombre, stock_actual')
          .eq('id', itemId)
          .single();

      final producto = Map<String, dynamic>.from(productoResponse);
      final stockAnterior = (producto['stock_actual'] as num).toDouble();
      final stockNuevo = stockAnterior + cantidad;

      await cliente
          .from('productos')
          .update({'stock_actual': stockNuevo})
          .eq('id', itemId);

      await cliente.from('movimientos_stock').insert({
        'tipo_item': 'producto',
        'item_id': itemId,
        'tipo_movimiento': 'venta_anulacion',
        'cantidad': cantidad,
        'unidad_medida': unidadMedida,
        'stock_anterior': stockAnterior,
        'stock_nuevo': stockNuevo,
        'motivo': 'Anulación de venta #$ventaId: ${motivo.trim()}',
        'referencia_tabla': 'ventas',
        'referencia_id': ventaId,
        'usuario_id': null,
      });
    }

    await cliente.from('ventas').update({
      'estado': 'anulada',
      'estado_preparacion': 'anulada',
      'motivo_anulacion': motivo.trim(),
      'fecha_anulacion': DateTime.now().toIso8601String(),
    }).eq('id', ventaId);
  }

  static String _fechaSql(DateTime fecha) {
    final yyyy = fecha.year.toString().padLeft(4, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final dd = fecha.day.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    final ss = fecha.second.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd $hh:$min:$ss';
  }
}