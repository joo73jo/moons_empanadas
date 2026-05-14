import '../../../../nucleo/constantes/supabase_cliente.dart';
import '../../../caja/presentacion/widgets/caja_supabase.dart';
import 'dialogo_cobro.dart';
import 'ventas_modelos.dart';

class VentasSupabase {
  static Future<void> guardarVenta({
    required String usuarioLogin,
    required ResultadoCobro resultadoCobro,
    required List<ItemPedido> items,
    required double subtotal,
  }) async {
    final cliente = SupabaseCliente.cliente;

    final usuarioDb = await cliente
        .from('usuarios')
        .select('id')
        .eq('usuario', usuarioLogin)
        .eq('activo', true)
        .single();

    final int usuarioId = usuarioDb['id'] as int;

    final cajaAbierta = await CajaSupabase.obtenerCajaAbierta();
    if (cajaAbierta == null) {
      throw Exception('Primero debes abrir caja.');
    }

    final int cajaId = cajaAbierta.id;

    await _validarStockAntesDeGuardar(items);

    final metodoVenta = resultadoCobro.esPagoMixto
        ? 'mixto'
        : _mapearMetodoPago(resultadoCobro.metodoPago);

    final ventaInsertada = await cliente
        .from('ventas')
        .insert({
          'caja_id': cajaId,
          'usuario_id': usuarioId,
          'metodo_pago': metodoVenta,
          'banco': resultadoCobro.esPagoMixto ? null : resultadoCobro.banco,
          'datofono':
              resultadoCobro.esPagoMixto ? null : resultadoCobro.datofono,
          'subtotal': subtotal,
          'total': resultadoCobro.total,
          'valor_recibido': resultadoCobro.valorRecibido,
          'cambio': resultadoCobro.cambio,
          'observacion': resultadoCobro.esPagoMixto
              ? _crearObservacionPagoMixto(resultadoCobro.pagos)
              : null,
          'estado': 'pagada',
          'estado_preparacion': 'pendiente',
        })
        .select('id')
        .single();

    final int ventaId = ventaInsertada['id'] as int;

    final detalles = items.map((item) {
      return {
        'venta_id': ventaId,
        'producto_id': item.producto.id,
        'nombre_producto': item.producto.nombre,
        'categoria_producto': item.producto.categoria,
        'precio_unitario': item.producto.precio,
        'cantidad': item.cantidad,
        'subtotal': item.subtotal,
        'sabores': item.sabores,
      };
    }).toList();

    await cliente.from('detalle_venta').insert(detalles);

    final pagosInsert = resultadoCobro.pagos.map((pago) {
      return {
        'venta_id': ventaId,
        'metodo_pago': _mapearMetodoPago(pago.metodoPago),
        'monto': pago.monto,
        'banco': pago.banco,
        'datofono': pago.datofono,
        'valor_recibido': pago.valorRecibido,
        'cambio': pago.cambio,
      };
    }).toList();

    await cliente.from('pagos_venta').insert(pagosInsert);

    await _descontarStockPorVenta(
      items: items,
      usuarioId: usuarioId,
      ventaId: ventaId,
    );

    await _actualizarTotalesCaja(
      cajaId: cajaId,
      pagos: resultadoCobro.pagos,
      totalVenta: resultadoCobro.total,
    );
  }

  static Future<List<PedidoPreparacion>> obtenerPedidosPreparacion() async {
  final cliente = SupabaseCliente.cliente;

  final ventasResponse = await cliente
      .from('ventas')
      .select('''
        id,
        created_at,
        estado_preparacion,
        usuario:usuarios!ventas_usuario_id_fkey(nombre)
      ''')
      .eq('estado', 'pagada')
      .eq('estado_preparacion', 'pendiente')
      .order('id', ascending: true)
      .limit(50);

  final ventas = ventasResponse
      .map<Map<String, dynamic>>(
        (item) => Map<String, dynamic>.from(item as Map),
      )
      .toList();

  if (ventas.isEmpty) return [];

  final idsVentas = ventas.map((v) => v['id'] as int).toList();

  final detallesResponse = await cliente
      .from('detalle_venta')
      .select('''
        venta_id,
        nombre_producto,
        categoria_producto,
        cantidad,
        sabores
      ''')
      .inFilter('venta_id', idsVentas)
      .order('id', ascending: true);

  final detalles = detallesResponse
      .map<Map<String, dynamic>>(
        (item) => Map<String, dynamic>.from(item as Map),
      )
      .toList();

  final Map<int, List<DetallePedidoPreparacion>> detallesPorVenta = {};

  for (final detalle in detalles) {
    final ventaId = detalle['venta_id'] as int;
    final saboresRaw = detalle['sabores'];
    final sabores = saboresRaw is List
        ? saboresRaw.map((e) => e.toString()).toList()
        : <String>[];

    detallesPorVenta.putIfAbsent(ventaId, () => []);
    detallesPorVenta[ventaId]!.add(
      DetallePedidoPreparacion(
        nombreProducto: (detalle['nombre_producto'] ?? '').toString(),
        categoriaProducto: (detalle['categoria_producto'] ?? '').toString(),
        cantidad: detalle['cantidad'] as int,
        sabores: sabores,
      ),
    );
  }

  return ventas.map((venta) {
    final usuario = venta['usuario'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(venta['usuario'] as Map);

    return PedidoPreparacion(
      id: venta['id'] as int,
      fecha: DateTime.parse(venta['created_at'] as String),
      vendedorNombre: (usuario['nombre'] ?? '').toString(),
      estadoPreparacion:
          (venta['estado_preparacion'] ?? 'pendiente').toString(),
      detalles: detallesPorVenta[venta['id'] as int] ?? [],
    );
  }).toList();
}

  static Future<void> marcarPedidoListo(int ventaId) async {
    await SupabaseCliente.cliente
        .from('ventas')
        .update({'estado_preparacion': 'listo'})
        .eq('id', ventaId);
  }

  static String _crearObservacionPagoMixto(List<PagoCobro> pagos) {
    final partes = pagos.map((pago) {
      final metodo = _mapearMetodoPago(pago.metodoPago);
      return '$metodo \$${pago.monto.toStringAsFixed(2)}';
    }).join(' + ');

    return 'Pago dividido: $partes';
  }

  static Future<void> _validarStockAntesDeGuardar(
    List<ItemPedido> items,
  ) async {
    final cliente = SupabaseCliente.cliente;

    final Map<int, double> descuentosDirectos = {};
    final Map<String, double> descuentosPorNombre = {};

    for (final item in items) {
      if (item.producto.controlaStock) {
        descuentosDirectos[item.producto.id] =
            (descuentosDirectos[item.producto.id] ?? 0) +
                item.cantidad.toDouble();
      }

      if (item.sabores.isNotEmpty) {
        for (final sabor in item.sabores) {
          descuentosPorNombre[sabor] =
              (descuentosPorNombre[sabor] ?? 0) + item.cantidad.toDouble();
        }
      }
    }

    if (descuentosDirectos.isNotEmpty) {
      final productos = await cliente
          .from('productos')
          .select('id, nombre, stock_actual')
          .inFilter('id', descuentosDirectos.keys.toList());

      for (final item in productos) {
        final mapa = Map<String, dynamic>.from(item as Map);
        final id = mapa['id'] as int;
        final nombre = (mapa['nombre'] ?? '').toString();
        final stockActual = (mapa['stock_actual'] as num).toDouble();
        final requerido = descuentosDirectos[id] ?? 0;

        if (requerido > stockActual) {
          throw Exception(
            'Stock insuficiente de $nombre. Necesitas ${requerido.toStringAsFixed(0)} y solo hay ${stockActual.toStringAsFixed(3)}.',
          );
        }
      }
    }

    if (descuentosPorNombre.isNotEmpty) {
      final productosSabores = await cliente
          .from('productos')
          .select('id, nombre, stock_actual, controla_stock, activo')
          .eq('activo', true)
          .eq('controla_stock', true);

      final Map<String, Map<String, dynamic>> porNombre = {
        for (final item in productosSabores)
          (Map<String, dynamic>.from(item as Map))['nombre'].toString():
              Map<String, dynamic>.from(item as Map),
      };

      for (final entry in descuentosPorNombre.entries) {
        final mapa = porNombre[entry.key];

        if (mapa == null) {
          throw Exception(
            'No existe producto terminado para el sabor "${entry.key}".',
          );
        }

        final stockActual = (mapa['stock_actual'] as num).toDouble();
        final requerido = entry.value;

        if (requerido > stockActual) {
          throw Exception(
            'Stock insuficiente de ${entry.key}. Necesitas ${requerido.toStringAsFixed(0)} y solo hay ${stockActual.toStringAsFixed(3)}.',
          );
        }
      }
    }
  }

  static Future<void> _descontarStockPorVenta({
    required List<ItemPedido> items,
    required int usuarioId,
    required int ventaId,
  }) async {
    final cliente = SupabaseCliente.cliente;

    for (final item in items) {
      if (item.producto.controlaStock) {
        final productoResponse = await cliente
            .from('productos')
            .select('id, nombre, stock_actual')
            .eq('id', item.producto.id)
            .single();

        final productoMapa = Map<String, dynamic>.from(productoResponse);
        final stockAnterior = (productoMapa['stock_actual'] as num).toDouble();
        final descuento = item.cantidad.toDouble();
        final stockNuevo = stockAnterior - descuento;

        await cliente
            .from('productos')
            .update({'stock_actual': stockNuevo})
            .eq('id', item.producto.id);

        await cliente.from('movimientos_stock').insert({
          'tipo_item': 'producto',
          'item_id': item.producto.id,
          'tipo_movimiento': 'venta_descuento',
          'cantidad': descuento,
          'unidad_medida': 'unidad',
          'stock_anterior': stockAnterior,
          'stock_nuevo': stockNuevo,
          'motivo': 'Venta #$ventaId - ${item.producto.nombre}',
          'referencia_tabla': 'ventas',
          'referencia_id': ventaId,
          'usuario_id': usuarioId,
        });
      }

      if (item.sabores.isNotEmpty) {
        for (final sabor in item.sabores) {
          final productoSaborResponse = await cliente
              .from('productos')
              .select('id, nombre, stock_actual')
              .eq('nombre', sabor)
              .eq('activo', true)
              .eq('controla_stock', true)
              .single();

          final productoSabor =
              Map<String, dynamic>.from(productoSaborResponse);
          final productoSaborId = productoSabor['id'] as int;
          final stockAnterior =
              (productoSabor['stock_actual'] as num).toDouble();
          final descuento = item.cantidad.toDouble();
          final stockNuevo = stockAnterior - descuento;

          await cliente
              .from('productos')
              .update({'stock_actual': stockNuevo})
              .eq('id', productoSaborId);

          await cliente.from('movimientos_stock').insert({
            'tipo_item': 'producto',
            'item_id': productoSaborId,
            'tipo_movimiento': 'venta_descuento',
            'cantidad': descuento,
            'unidad_medida': 'unidad',
            'stock_anterior': stockAnterior,
            'stock_nuevo': stockNuevo,
            'motivo':
                'Venta #$ventaId - sabor seleccionado en ${item.producto.nombre}',
            'referencia_tabla': 'ventas',
            'referencia_id': ventaId,
            'usuario_id': usuarioId,
          });
        }
      }
    }
  }

  static Future<void> _actualizarTotalesCaja({
    required int cajaId,
    required List<PagoCobro> pagos,
    required double totalVenta,
  }) async {
    final cliente = SupabaseCliente.cliente;

    final caja = await cliente
        .from('cajas')
        .select(
          'total_efectivo, total_transferencia, total_tarjeta, total_ventas',
        )
        .eq('id', cajaId)
        .single();

    double totalEfectivo =
        (caja['total_efectivo'] as num?)?.toDouble() ?? 0;
    double totalTransferencia =
        (caja['total_transferencia'] as num?)?.toDouble() ?? 0;
    double totalTarjeta = (caja['total_tarjeta'] as num?)?.toDouble() ?? 0;
    double totalVentas = (caja['total_ventas'] as num?)?.toDouble() ?? 0;

    for (final pago in pagos) {
      switch (pago.metodoPago) {
        case MetodoPago.efectivo:
          totalEfectivo += pago.monto;
          break;
        case MetodoPago.transferencia:
          totalTransferencia += pago.monto;
          break;
        case MetodoPago.tarjeta:
          totalTarjeta += pago.monto;
          break;
      }
    }

    totalVentas += totalVenta;

    await cliente.from('cajas').update({
      'total_efectivo': totalEfectivo,
      'total_transferencia': totalTransferencia,
      'total_tarjeta': totalTarjeta,
      'total_ventas': totalVentas,
    }).eq('id', cajaId);
  }

  static Future<bool> hayCajaAbierta() async {
    final cajaAbierta = await CajaSupabase.obtenerCajaAbierta();
    return cajaAbierta != null;
  }

  static String _mapearMetodoPago(MetodoPago metodoPago) {
    switch (metodoPago) {
      case MetodoPago.efectivo:
        return 'efectivo';
      case MetodoPago.transferencia:
        return 'transferencia';
      case MetodoPago.tarjeta:
        return 'tarjeta';
    }
  }
}