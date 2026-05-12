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
    required this.detalles,
  });
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
    int limite = 30,
  }) async {
    final ventasResponse = await SupabaseCliente.cliente
        .from('ventas')
        .select('''
          id,
          created_at,
          metodo_pago,
          banco,
          datofono,
          subtotal,
          total,
          usuario:usuarios(nombre, usuario)
        ''')
        .order('id', ascending: false)
        .limit(limite);

    final List<Map<String, dynamic>> ventas = ventasResponse
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
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
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
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
      final usuario = Map<String, dynamic>.from(venta['usuario'] as Map);

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
        detalles: detallesPorVenta[venta['id'] as int] ?? [],
      );
    }).toList();
  }
}