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
    await guardarPedido(
      usuarioLogin: usuarioLogin,
      resultadoCobro: resultadoCobro,
      items: items,
      subtotal: subtotal,
      datosPedido: DatosPedidoVenta(
        nombrePedido: '',
        tipoPedido: TipoPedido.local,
        barrio: '',
        estadoCobro: EstadoCobroVenta.pagado,
        responsableDinero: '',
        enviarPreparacion: true,
        recargos: const [],
      ),
    );
  }

  static Future<int> guardarPedido({
    required String usuarioLogin,
    required ResultadoCobro? resultadoCobro,
    required List<ItemPedido> items,
    required double subtotal,
    required DatosPedidoVenta datosPedido,
  }) async {
    if (items.isEmpty) {
      throw Exception('El pedido no tiene productos.');
    }

    if (subtotal <= 0) {
      throw Exception('El subtotal debe ser mayor a cero.');
    }

    if (datosPedido.nombrePedido.trim().isEmpty) {
      throw Exception('Debes ingresar el nombre del pedido.');
    }

    if (datosPedido.tipoPedido == TipoPedido.domicilio &&
        datosPedido.barrio.trim().isEmpty) {
      throw Exception('Debes ingresar el barrio del domicilio.');
    }

    if (datosPedido.estadoCobro == EstadoCobroVenta.cobradoRepartidor &&
        datosPedido.responsableDinero.trim().isEmpty) {
      throw Exception('Debes indicar quién tiene pendiente el dinero.');
    }

    if (datosPedido.requiereCobroInmediato && resultadoCobro == null) {
      throw Exception(
        'La venta está marcada como pagada, pero no se registró el cobro.',
      );
    }

    final cliente = SupabaseCliente.cliente;

    final usuarioId = await _obtenerUsuarioId(usuarioLogin);

    final cajaAbierta = await CajaSupabase.obtenerCajaAbierta();

    if (cajaAbierta == null) {
      throw Exception('Primero debes abrir caja.');
    }

    await _validarStockAntesDeGuardar(items);

    final totalRecargos = datosPedido.totalRecargos();

    final totalVenta = subtotal + totalRecargos + datosPedido.valorDomicilio;

    if (resultadoCobro != null &&
        (resultadoCobro.total - totalVenta).abs() > 0.01) {
      throw Exception(
        'El total del cobro no coincide con el total del pedido.',
      );
    }

    final bool estaPagado =
        !datosPedido.esProgramado &&
        (datosPedido.estadoCobro == EstadoCobroVenta.pagado ||
            datosPedido.estadoCobro == EstadoCobroVenta.entregado);

    final String metodoVenta;

    if (resultadoCobro == null) {
      metodoVenta = 'mixto';
    } else {
      metodoVenta = resultadoCobro.esPagoMixto
          ? 'mixto'
          : _mapearMetodoPago(resultadoCobro.metodoPago);
    }

    final ventaInsertada = await cliente
        .from('ventas')
        .insert({
          'caja_id': cajaAbierta.id,
          'usuario_id': usuarioId,
          'nombre_pedido': datosPedido.nombrePedido.trim(),
          'tipo_pedido': tipoPedidoBaseDatos(datosPedido.tipoPedido),
          'barrio': datosPedido.tipoPedido == TipoPedido.domicilio
              ? datosPedido.barrio.trim()
              : null,
          'valor_domicilio': datosPedido.tipoPedido == TipoPedido.domicilio
              ? datosPedido.valorDomicilio
              : 0,

          'usa_indrive': datosPedido.tipoPedido == TipoPedido.domicilio
              ? datosPedido.usaIndrive
              : false,

          'plataforma': datosPedido.plataforma.trim().isEmpty
              ? null
              : datosPedido.plataforma.trim(),

          'porcentaje_plataforma': datosPedido.porcentajePlataforma,

          'descuento_plataforma': datosPedido.descuentoPlataforma,

          'es_programado': datosPedido.esProgramado,

          'fecha_programada': datosPedido.fechaProgramada?.toIso8601String(),

          'fecha_contable':
              (datosPedido.esProgramado && datosPedido.fechaProgramada != null
                      ? datosPedido.fechaProgramada!
                      : DateTime.now())
                  .toIso8601String()
                  .substring(0, 10),
          'metodo_pago': metodoVenta,
          'banco': resultadoCobro == null || resultadoCobro.esPagoMixto
              ? null
              : resultadoCobro.banco,
          'datofono': resultadoCobro == null || resultadoCobro.esPagoMixto
              ? null
              : resultadoCobro.datofono,
          'subtotal': subtotal,
          'total_recargos': totalRecargos,
          'total': totalVenta,
          'valor_recibido': resultadoCobro?.valorRecibido,
          'cambio': resultadoCobro?.cambio ?? 0,
          'observacion': resultadoCobro != null && resultadoCobro.esPagoMixto
              ? _crearObservacionPagoMixto(resultadoCobro.pagos)
              : null,
          'estado': estaPagado ? 'pagada' : 'pendiente',
          'estado_cobro': estadoCobroBaseDatos(datosPedido.estadoCobro),
          'responsable_dinero': datosPedido.responsableDinero.trim().isEmpty
              ? null
              : datosPedido.responsableDinero.trim(),
          'fecha_cobro': estaPagado ? DateTime.now().toIso8601String() : null,
          'enviado_preparacion': datosPedido.enviarPreparacion,
          'estado_preparacion': datosPedido.enviarPreparacion
              ? 'pendiente'
              : 'no_enviado',
          'fecha_envio_preparacion': datosPedido.enviarPreparacion
              ? DateTime.now().toIso8601String()
              : null,
        })
        .select('id')
        .single();

    final ventaId = (ventaInsertada['id'] as num).toInt();

    for (final item in items) {
      final detalleInsertado = await cliente
          .from('detalle_venta')
          .insert({
            'venta_id': ventaId,
            'producto_id': item.producto.id,
            'nombre_producto': item.producto.nombre,
            'categoria_producto': item.producto.categoria,
            'precio_unitario': item.precioUnitarioFinal,
            'cantidad': item.cantidad,
            'subtotal': item.subtotal,
            'sabores': item.eleccionesCombo.isEmpty ? item.sabores : <String>[],
          })
          .select('id')
          .single();

      final detalleVentaId = (detalleInsertado['id'] as num).toInt();

      if (item.eleccionesCombo.isNotEmpty) {
        final eleccionesInsert = item.eleccionesCombo.map((eleccion) {
          return {
            'detalle_venta_id': detalleVentaId,
            'combo_id': item.producto.id,
            'componente_id': eleccion.componenteId,
            'nombre_componente': eleccion.nombreComponente,
            'producto_predeterminado_id': eleccion.productoPredeterminadoId,
            'producto_elegido_id': eleccion.productoElegido.id,
            'nombre_producto_elegido': eleccion.productoElegido.nombre,
            'cantidad': eleccion.cantidad,
            'recargo_unitario': eleccion.recargoUnitario,
            'recargo_total': eleccion.recargoTotal,
            'fue_sustituido': eleccion.fueSustituido,
          };
        }).toList();

        await cliente
            .from('detalle_venta_combo_elecciones')
            .insert(eleccionesInsert);
      }
    }

    if (datosPedido.recargos.isNotEmpty) {
      final recargosInsert = datosPedido.recargos.map((recargo) {
        return {
          'venta_id': ventaId,
          'recargo_configuracion_id': recargo.configuracionId,
          'nombre_recargo': recargo.nombre,
          'porcentaje': recargo.porcentaje,
          'valor': recargo.valor,
        };
      }).toList();

      await cliente.from('venta_recargos').insert(recargosInsert);
    }

    if (resultadoCobro != null) {
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
    }

    await _descontarStockPorVenta(
      items: items,
      usuarioId: usuarioId,
      ventaId: ventaId,
    );

    if (resultadoCobro != null) {
      await _actualizarTotalesCaja(
        cajaId: cajaAbierta.id,
        pagos: resultadoCobro.pagos,
        totalVenta: totalVenta,
      );
    }

    return ventaId;
  }

  static Future<void> cobrarVentaPendiente({
    required int ventaId,
    required ResultadoCobro resultadoCobro,
  }) async {
    final cliente = SupabaseCliente.cliente;

    final cajaAbierta = await CajaSupabase.obtenerCajaAbierta();

    if (cajaAbierta == null) {
      throw Exception('Primero debes abrir caja.');
    }

    final ventaResponse = await cliente
        .from('ventas')
        .select(
          'id, total, estado, estado_cobro, caja_id, es_programado, fecha_programada',
        )
        .eq('id', ventaId)
        .single();

    final venta = Map<String, dynamic>.from(ventaResponse);

    final total = (venta['total'] as num?)?.toDouble() ?? 0;

    final estadoCobro = (venta['estado_cobro'] ?? '').toString();

    if (estadoCobro == 'pagado' || estadoCobro == 'entregado') {
      throw Exception('Este pedido ya fue cobrado.');
    }

    if ((resultadoCobro.total - total).abs() > 0.01) {
      throw Exception('El total del cobro no coincide con el pedido.');
    }

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

    final metodoVenta = resultadoCobro.esPagoMixto
        ? 'mixto'
        : _mapearMetodoPago(resultadoCobro.metodoPago);

    final ahora = DateTime.now();

    final fechaContable = _fechaContableVenta(venta, ahora);

    await cliente
        .from('ventas')
        .update({
          'metodo_pago': metodoVenta,
          'banco': resultadoCobro.esPagoMixto ? null : resultadoCobro.banco,
          'datofono': resultadoCobro.esPagoMixto
              ? null
              : resultadoCobro.datofono,
          'valor_recibido': resultadoCobro.valorRecibido,
          'cambio': resultadoCobro.cambio,
          'observacion': resultadoCobro.esPagoMixto
              ? _crearObservacionPagoMixto(resultadoCobro.pagos)
              : null,

          'fecha_contable': fechaContable,

          'caja_liquidacion_id': cajaAbierta.id,

          'estado': 'pagada',
          'estado_cobro': 'pagado',

          'fecha_cobro': ahora.toIso8601String(),
        })
        .eq('id', ventaId);

    await _actualizarTotalesCaja(
      cajaId: cajaAbierta.id,
      pagos: resultadoCobro.pagos,
      totalVenta: total,
    );
  }

  static Future<List<PlataformaConfiguracion>> obtenerPlataformasConfiguracion({
    bool soloActivas = true,
  }) async {
    var consulta = SupabaseCliente.cliente
        .from('plataformas_configuracion')
        .select('id, nombre, porcentaje, activo, orden');

    if (soloActivas) {
      consulta = consulta.eq('activo', true);
    }

    final response = await consulta.order('orden', ascending: true);

    return response.map<PlataformaConfiguracion>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      return PlataformaConfiguracion(
        id: (mapa['id'] as num).toInt(),
        nombre: (mapa['nombre'] ?? '').toString(),
        porcentaje: (mapa['porcentaje'] as num?)?.toDouble() ?? 0,
        activo: mapa['activo'] as bool? ?? true,
        orden: (mapa['orden'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static Future<List<RecargoConfiguracion>> obtenerRecargosConfiguracion({
    bool soloActivos = true,
  }) async {
    var consulta = SupabaseCliente.cliente
        .from('recargos_configuracion')
        .select('id, nombre, porcentaje, activo, orden');

    if (soloActivos) {
      consulta = consulta.eq('activo', true);
    }

    final response = await consulta.order('orden', ascending: true);

    return response.map<RecargoConfiguracion>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);

      return RecargoConfiguracion(
        id: (mapa['id'] as num).toInt(),
        nombre: (mapa['nombre'] ?? '').toString(),
        porcentaje: (mapa['porcentaje'] as num?)?.toDouble() ?? 0,
        activo: mapa['activo'] as bool? ?? true,
        orden: (mapa['orden'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static Future<RecargoConfiguracion> actualizarRecargoConfiguracion({
    required int recargoId,
    required String nombre,
    required double porcentaje,
    required bool activo,
    required int orden,
  }) async {
    if (nombre.trim().isEmpty) {
      throw Exception('El nombre del recargo es obligatorio.');
    }

    if (porcentaje < 0 || porcentaje > 100) {
      throw Exception('El porcentaje debe estar entre 0 y 100.');
    }

    final response = await SupabaseCliente.cliente
        .from('recargos_configuracion')
        .update({
          'nombre': nombre.trim(),
          'porcentaje': porcentaje,
          'activo': activo,
          'orden': orden,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recargoId)
        .select('id, nombre, porcentaje, activo, orden')
        .single();

    final mapa = Map<String, dynamic>.from(response);

    return RecargoConfiguracion(
      id: (mapa['id'] as num).toInt(),
      nombre: (mapa['nombre'] ?? '').toString(),
      porcentaje: (mapa['porcentaje'] as num?)?.toDouble() ?? 0,
      activo: mapa['activo'] as bool? ?? true,
      orden: (mapa['orden'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<List<PedidoPreparacion>> obtenerPedidosPreparacion() async {
    final cliente = SupabaseCliente.cliente;

    final ventasResponse = await cliente
        .from('ventas')
        .select('''
          id,
          created_at,
          nombre_pedido,
          tipo_pedido,
          barrio,
          estado_cobro,
          responsable_dinero,
          enviado_preparacion,
          estado_preparacion,
          subtotal,
          total_recargos,
          total,
          usuario:usuarios!ventas_usuario_id_fkey(
            nombre
          )
        ''')
        .eq('enviado_preparacion', true)
        .or(
          'estado_preparacion.eq.pendiente,and(estado_preparacion.eq.listo,estado_cobro.in.(pendiente_pago,cobrado_repartidor))',
        )
        .neq('estado', 'anulada')
        .order('id', ascending: true)
        .limit(50);

    final ventas = ventasResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    if (ventas.isEmpty) {
      return [];
    }

    final idsVentas = ventas
        .map<int>((venta) => (venta['id'] as num).toInt())
        .toList();

    final detallesResponse = await cliente
        .from('detalle_venta')
        .select('''
          id,
          venta_id,
          nombre_producto,
          categoria_producto,
          cantidad,
          precio_unitario,
          subtotal,
          sabores
        ''')
        .inFilter('venta_id', idsVentas)
        .order('id', ascending: true);

    final detalles = detallesResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    final eleccionesPorDetalle = await _obtenerEleccionesComboPorDetalle(
      detalles.map<int>((detalle) => (detalle['id'] as num).toInt()).toList(),
    );

    final Map<int, List<DetallePedidoPreparacion>> detallesPorVenta = {};

    for (final detalle in detalles) {
      final ventaId = (detalle['venta_id'] as num).toInt();

      final detalleId = (detalle['id'] as num).toInt();

      final saboresRaw = detalle['sabores'];

      final sabores = saboresRaw is List
          ? saboresRaw.map((item) => item.toString()).toList()
          : <String>[];

      detallesPorVenta.putIfAbsent(ventaId, () => []);

      detallesPorVenta[ventaId]!.add(
        DetallePedidoPreparacion(
          nombreProducto: (detalle['nombre_producto'] ?? '').toString(),
          categoriaProducto: (detalle['categoria_producto'] ?? '').toString(),
          cantidad: (detalle['cantidad'] as num).toInt(),
          precioUnitario: (detalle['precio_unitario'] as num?)?.toDouble() ?? 0,
          subtotal: (detalle['subtotal'] as num?)?.toDouble() ?? 0,
          sabores: sabores,
          eleccionesCombo: eleccionesPorDetalle[detalleId] ?? const [],
        ),
      );
    }

    return ventas.map((venta) {
      final usuarioRaw = venta['usuario'];

      final usuario = usuarioRaw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(usuarioRaw as Map);

      final ventaId = (venta['id'] as num).toInt();

      return PedidoPreparacion(
        id: ventaId,
        fecha: DateTime.parse(venta['created_at'].toString()),
        nombrePedido: (venta['nombre_pedido'] ?? 'Pedido $ventaId').toString(),
        vendedorNombre: (usuario['nombre'] ?? '').toString(),
        estadoPreparacion: (venta['estado_preparacion'] ?? 'pendiente')
            .toString(),
        tipoPedido: tipoPedidoDesdeBaseDatos(venta['tipo_pedido']),
        barrio: (venta['barrio'] ?? '').toString(),
        estadoCobro: estadoCobroDesdeBaseDatos(venta['estado_cobro']),
        responsableDinero: (venta['responsable_dinero'] ?? '').toString(),
        enviadoPreparacion: venta['enviado_preparacion'] as bool? ?? true,
        subtotal: (venta['subtotal'] as num?)?.toDouble() ?? 0,
        totalRecargos: (venta['total_recargos'] as num?)?.toDouble() ?? 0,
        total: (venta['total'] as num?)?.toDouble() ?? 0,
        detalles: detallesPorVenta[ventaId] ?? [],
      );
    }).toList();
  }

  static Future<List<PedidoPreparacion>> obtenerPedidosNoEnviados() async {
    final cliente = SupabaseCliente.cliente;

    final ventasResponse = await cliente
        .from('ventas')
        .select('''
          id,
          created_at,
          nombre_pedido,
          tipo_pedido,
          barrio,
          estado_cobro,
          responsable_dinero,
          enviado_preparacion,
          estado_preparacion,
          subtotal,
          total_recargos,
          total,
          usuario:usuarios!ventas_usuario_id_fkey(
            nombre
          )
        ''')
        .eq('enviado_preparacion', false)
        .neq('estado', 'anulada')
        .order('id', ascending: true);

    final ventas = ventasResponse
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    if (ventas.isEmpty) {
      return [];
    }

    final idsVentas = ventas
        .map<int>((venta) => (venta['id'] as num).toInt())
        .toList();

    final detallesResponse = await cliente
        .from('detalle_venta')
        .select('''
          id,
          venta_id,
          nombre_producto,
          categoria_producto,
          cantidad,
          precio_unitario,
          subtotal,
          sabores
        ''')
        .inFilter('venta_id', idsVentas)
        .order('id', ascending: true);

    final eleccionesPorDetalle = await _obtenerEleccionesComboPorDetalle(
      detallesResponse
          .map<int>(
            (item) =>
                (Map<String, dynamic>.from(item as Map)['id'] as num).toInt(),
          )
          .toList(),
    );

    final Map<int, List<DetallePedidoPreparacion>> detallesPorVenta = {};

    for (final item in detallesResponse) {
      final detalle = Map<String, dynamic>.from(item as Map);

      final ventaId = (detalle['venta_id'] as num).toInt();

      final detalleId = (detalle['id'] as num).toInt();

      final saboresRaw = detalle['sabores'];

      final sabores = saboresRaw is List
          ? saboresRaw.map((item) => item.toString()).toList()
          : <String>[];

      detallesPorVenta.putIfAbsent(ventaId, () => []);

      detallesPorVenta[ventaId]!.add(
        DetallePedidoPreparacion(
          nombreProducto: (detalle['nombre_producto'] ?? '').toString(),
          categoriaProducto: (detalle['categoria_producto'] ?? '').toString(),
          cantidad: (detalle['cantidad'] as num).toInt(),
          precioUnitario: (detalle['precio_unitario'] as num?)?.toDouble() ?? 0,
          subtotal: (detalle['subtotal'] as num?)?.toDouble() ?? 0,
          sabores: sabores,
          eleccionesCombo: eleccionesPorDetalle[detalleId] ?? const [],
        ),
      );
    }

    return ventas.map((venta) {
      final usuarioRaw = venta['usuario'];

      final usuario = usuarioRaw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(usuarioRaw as Map);

      final ventaId = (venta['id'] as num).toInt();

      return PedidoPreparacion(
        id: ventaId,
        fecha: DateTime.parse(venta['created_at'].toString()),
        nombrePedido: (venta['nombre_pedido'] ?? 'Pedido $ventaId').toString(),
        vendedorNombre: (usuario['nombre'] ?? '').toString(),
        estadoPreparacion: (venta['estado_preparacion'] ?? 'no_enviado')
            .toString(),
        tipoPedido: tipoPedidoDesdeBaseDatos(venta['tipo_pedido']),
        barrio: (venta['barrio'] ?? '').toString(),
        estadoCobro: estadoCobroDesdeBaseDatos(venta['estado_cobro']),
        responsableDinero: (venta['responsable_dinero'] ?? '').toString(),
        enviadoPreparacion: venta['enviado_preparacion'] as bool? ?? false,
        subtotal: (venta['subtotal'] as num?)?.toDouble() ?? 0,
        totalRecargos: (venta['total_recargos'] as num?)?.toDouble() ?? 0,
        total: (venta['total'] as num?)?.toDouble() ?? 0,
        detalles: detallesPorVenta[ventaId] ?? [],
      );
    }).toList();
  }

  static Future<Map<int, List<DetalleEleccionComboPreparacion>>>
  _obtenerEleccionesComboPorDetalle(List<int> idsDetalles) async {
    final resultado = <int, List<DetalleEleccionComboPreparacion>>{};

    if (idsDetalles.isEmpty) {
      return resultado;
    }

    final response = await SupabaseCliente.cliente
        .from('detalle_venta_combo_elecciones')
        .select('''
          detalle_venta_id,
          nombre_componente,
          nombre_producto_elegido,
          cantidad,
          recargo_unitario,
          recargo_total,
          fue_sustituido
        ''')
        .inFilter('detalle_venta_id', idsDetalles)
        .order('id', ascending: true);

    for (final item in response) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final detalleId = (mapa['detalle_venta_id'] as num).toInt();

      resultado.putIfAbsent(detalleId, () => []);

      resultado[detalleId]!.add(
        DetalleEleccionComboPreparacion(
          nombreComponente: (mapa['nombre_componente'] ?? '').toString(),
          nombreProductoElegido: (mapa['nombre_producto_elegido'] ?? '')
              .toString(),
          cantidad: (mapa['cantidad'] as num?)?.toInt() ?? 1,
          recargoUnitario: (mapa['recargo_unitario'] as num?)?.toDouble() ?? 0,
          recargoTotal: (mapa['recargo_total'] as num?)?.toDouble() ?? 0,
          fueSustituido: mapa['fue_sustituido'] as bool? ?? false,
        ),
      );
    }

    return resultado;
  }

  static Future<void> marcarPedidoListo(int ventaId) async {
    await SupabaseCliente.cliente
        .from('ventas')
        .update({'estado_preparacion': 'listo'})
        .eq('id', ventaId);
  }

  static Future<void> enviarPedidoPreparacion(int ventaId) async {
    await SupabaseCliente.cliente.rpc(
      'enviar_venta_preparacion',
      params: {'p_venta_id': ventaId},
    );
  }

  static Future<void> marcarDineroEntregado(int ventaId) async {
    final cliente = SupabaseCliente.cliente;

    final cajaAbierta = await CajaSupabase.obtenerCajaAbierta();

    if (cajaAbierta == null) {
      throw Exception('Primero debes abrir caja para recibir el dinero.');
    }

    final ventaResponse = await cliente
        .from('ventas')
        .select(
          'id, total, estado_cobro, responsable_dinero, es_programado, fecha_programada',
        )
        .eq('id', ventaId)
        .single();

    final venta = Map<String, dynamic>.from(ventaResponse);

    final estadoCobro = (venta['estado_cobro'] ?? '').toString();

    if (estadoCobro != 'cobrado_repartidor') {
      throw Exception(
        'Esta venta no tiene dinero pendiente con un repartidor.',
      );
    }

    final total = (venta['total'] as num?)?.toDouble() ?? 0;

    if (total <= 0) {
      throw Exception('El total de la venta no es válido.');
    }

    final ahora = DateTime.now();

    final fechaContable = _fechaContableVenta(venta, ahora);

    await cliente.from('pagos_venta').insert({
      'venta_id': ventaId,
      'metodo_pago': 'efectivo',
      'monto': total,
      'banco': null,
      'datofono': null,
      'valor_recibido': total,
      'cambio': 0,
    });

    await cliente
        .from('ventas')
        .update({
          'estado': 'pagada',
          'estado_cobro': 'entregado',

          'fecha_cobro': ahora.toIso8601String(),

          'fecha_entrega_dinero': ahora.toIso8601String(),

          'caja_liquidacion_id': cajaAbierta.id,

          'fecha_contable': fechaContable,
        })
        .eq('id', ventaId);

    final pago = PagoCobro(
      metodoPago: MetodoPago.efectivo,
      monto: total,
      valorRecibido: total,
      cambio: 0,
    );

    await _actualizarTotalesCaja(
      cajaId: cajaAbierta.id,
      pagos: [pago],
      totalVenta: total,
    );
  }

  static String _fechaContableVenta(
    Map<String, dynamic> venta,
    DateTime ahora,
  ) {
    final esProgramado = venta['es_programado'] as bool? ?? false;

    final fechaProgramadaRaw = venta['fecha_programada'];

    if (esProgramado && fechaProgramadaRaw != null) {
      final fechaProgramada = DateTime.tryParse(fechaProgramadaRaw.toString());

      if (fechaProgramada != null) {
        final local = fechaProgramada.toLocal();

        final yyyy = local.year.toString().padLeft(4, '0');

        final mm = local.month.toString().padLeft(2, '0');

        final dd = local.day.toString().padLeft(2, '0');

        return '$yyyy-$mm-$dd';
      }
    }

    final yyyy = ahora.year.toString().padLeft(4, '0');

    final mm = ahora.month.toString().padLeft(2, '0');

    final dd = ahora.day.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd';
  }

  static Future<int> _obtenerUsuarioId(String usuarioLogin) async {
    final usuarioDb = await SupabaseCliente.cliente
        .from('usuarios')
        .select('id')
        .eq('usuario', usuarioLogin.trim())
        .eq('activo', true)
        .single();

    return (usuarioDb['id'] as num).toInt();
  }

  static String _crearObservacionPagoMixto(List<PagoCobro> pagos) {
    final partes = pagos
        .map((pago) {
          final metodo = _mapearMetodoPago(pago.metodoPago);

          return '$metodo \$${pago.monto.toStringAsFixed(2)}';
        })
        .join(' + ');

    return 'Pago dividido: $partes';
  }

  static Future<void> _validarStockAntesDeGuardar(
    List<ItemPedido> items,
  ) async {
    final cliente = SupabaseCliente.cliente;

    final descuentosPorId = <int, double>{};

    final descuentosPorNombre = <String, double>{};

    _acumularDescuentosStock(
      items: items,
      descuentosPorId: descuentosPorId,
      descuentosPorNombre: descuentosPorNombre,
    );

    if (descuentosPorId.isNotEmpty) {
      final productos = await cliente
          .from('productos')
          .select('id, nombre, stock_actual, controla_stock, activo')
          .inFilter('id', descuentosPorId.keys.toList());

      final encontrados = <int>{};

      for (final item in productos) {
        final mapa = Map<String, dynamic>.from(item as Map);

        final id = (mapa['id'] as num).toInt();

        encontrados.add(id);

        final activo = mapa['activo'] as bool? ?? true;

        if (!activo) {
          throw Exception(
            'El producto ${(mapa['nombre'] ?? '').toString()} está inactivo.',
          );
        }

        final controlaStock = mapa['controla_stock'] as bool? ?? true;

        if (!controlaStock) {
          continue;
        }

        final stockActual = (mapa['stock_actual'] as num?)?.toDouble() ?? 0;

        final requerido = descuentosPorId[id] ?? 0;

        if (requerido > stockActual + 0.000001) {
          throw Exception(
            'Stock insuficiente de ${(mapa['nombre'] ?? '').toString()}. Necesitas ${requerido.toStringAsFixed(0)} y solo hay ${stockActual.toStringAsFixed(3)}.',
          );
        }
      }

      final faltantes = descuentosPorId.keys
          .where((id) => !encontrados.contains(id))
          .toList();

      if (faltantes.isNotEmpty) {
        throw Exception('Uno de los productos seleccionados ya no existe.');
      }
    }

    if (descuentosPorNombre.isNotEmpty) {
      final productos = await cliente
          .from('productos')
          .select('id, nombre, stock_actual, controla_stock, activo')
          .eq('activo', true)
          .eq('controla_stock', true);

      final porNombre = <String, Map<String, dynamic>>{};

      for (final item in productos) {
        final mapa = Map<String, dynamic>.from(item as Map);

        porNombre[(mapa['nombre'] ?? '').toString()] = mapa;
      }

      for (final entry in descuentosPorNombre.entries) {
        final producto = porNombre[entry.key];

        if (producto == null) {
          throw Exception(
            'No existe producto terminado para el sabor "${entry.key}".',
          );
        }

        final stockActual = (producto['stock_actual'] as num?)?.toDouble() ?? 0;

        if (entry.value > stockActual + 0.000001) {
          throw Exception(
            'Stock insuficiente de ${entry.key}. Necesitas ${entry.value.toStringAsFixed(0)} y solo hay ${stockActual.toStringAsFixed(3)}.',
          );
        }
      }
    }
  }

  static void _acumularDescuentosStock({
    required List<ItemPedido> items,
    required Map<int, double> descuentosPorId,
    required Map<String, double> descuentosPorNombre,
  }) {
    for (final item in items) {
      if (item.eleccionesCombo.isNotEmpty) {
        for (final eleccion in item.eleccionesCombo) {
          final cantidad = eleccion.cantidad.toDouble() * item.cantidad;

          descuentosPorId[eleccion.productoElegido.id] =
              (descuentosPorId[eleccion.productoElegido.id] ?? 0) + cantidad;
        }

        continue;
      }

      if (item.producto.controlaStock) {
        descuentosPorId[item.producto.id] =
            (descuentosPorId[item.producto.id] ?? 0) + item.cantidad.toDouble();
      }

      for (final sabor in item.sabores) {
        descuentosPorNombre[sabor] =
            (descuentosPorNombre[sabor] ?? 0) + item.cantidad.toDouble();
      }
    }
  }

  static Future<void> _descontarStockPorVenta({
    required List<ItemPedido> items,
    required int usuarioId,
    required int ventaId,
  }) async {
    final cliente = SupabaseCliente.cliente;

    final descuentosPorId = <int, double>{};

    final descuentosPorNombre = <String, double>{};

    _acumularDescuentosStock(
      items: items,
      descuentosPorId: descuentosPorId,
      descuentosPorNombre: descuentosPorNombre,
    );

    if (descuentosPorNombre.isNotEmpty) {
      final productos = await cliente
          .from('productos')
          .select('id, nombre, controla_stock')
          .eq('activo', true)
          .eq('controla_stock', true);

      final idsPorNombre = <String, int>{};

      for (final item in productos) {
        final mapa = Map<String, dynamic>.from(item as Map);

        idsPorNombre[(mapa['nombre'] ?? '').toString()] = (mapa['id'] as num)
            .toInt();
      }

      for (final entry in descuentosPorNombre.entries) {
        final id = idsPorNombre[entry.key];

        if (id == null) {
          throw Exception(
            'No existe producto terminado para el sabor "${entry.key}".',
          );
        }

        descuentosPorId[id] = (descuentosPorId[id] ?? 0) + entry.value;
      }
    }

    if (descuentosPorId.isEmpty) {
      return;
    }

    final productos = await cliente
        .from('productos')
        .select('id, nombre, stock_actual, controla_stock')
        .inFilter('id', descuentosPorId.keys.toList());

    final productosPorId = <int, Map<String, dynamic>>{};

    for (final item in productos) {
      final mapa = Map<String, dynamic>.from(item as Map);

      productosPorId[(mapa['id'] as num).toInt()] = mapa;
    }

    for (final entry in descuentosPorId.entries) {
      final producto = productosPorId[entry.key];

      if (producto == null) {
        throw Exception(
          'No se encontró uno de los productos que debía descontarse.',
        );
      }

      final controlaStock = producto['controla_stock'] as bool? ?? true;

      if (!controlaStock) {
        continue;
      }

      final nombre = (producto['nombre'] ?? '').toString();

      final stockAnterior = (producto['stock_actual'] as num?)?.toDouble() ?? 0;

      final stockNuevo = stockAnterior - entry.value;

      if (stockNuevo < -0.000001) {
        throw Exception('Stock insuficiente de $nombre.');
      }

      final stockNuevoSeguro = stockNuevo < 0 ? 0.0 : stockNuevo;

      await cliente
          .from('productos')
          .update({'stock_actual': stockNuevoSeguro})
          .eq('id', entry.key);

      await cliente.from('movimientos_stock').insert({
        'tipo_item': 'producto',
        'item_id': entry.key,
        'tipo_movimiento': 'venta_descuento',
        'cantidad': entry.value,
        'unidad_medida': 'unidad',
        'stock_anterior': stockAnterior,
        'stock_nuevo': stockNuevoSeguro,
        'motivo':
            'Venta #$ventaId - descuento por producto real vendido: $nombre',
        'referencia_tabla': 'ventas',
        'referencia_id': ventaId,
        'usuario_id': usuarioId,
      });
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

    double totalEfectivo = (caja['total_efectivo'] as num?)?.toDouble() ?? 0;

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

    await cliente
        .from('cajas')
        .update({
          'total_efectivo': totalEfectivo,
          'total_transferencia': totalTransferencia,
          'total_tarjeta': totalTarjeta,
          'total_ventas': totalVentas,
        })
        .eq('id', cajaId);
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
