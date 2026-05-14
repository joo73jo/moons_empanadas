import '../../../../nucleo/constantes/supabase_cliente.dart';

class KpiReporte {
  final String titulo;
  final String valor;
  final String subtitulo;

  const KpiReporte({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
  });
}

class SerieDiaReporte {
  final String etiqueta;
  final double valor;

  const SerieDiaReporte({
    required this.etiqueta,
    required this.valor,
  });
}

class MetodoPagoReporte {
  final String metodo;
  final double total;

  const MetodoPagoReporte({
    required this.metodo,
    required this.total,
  });
}

class TopProductoReporte {
  final String nombre;
  final int cantidad;
  final double total;

  const TopProductoReporte({
    required this.nombre,
    required this.cantidad,
    required this.total,
  });
}

class AlertaStockReporte {
  final String nombre;
  final String nivel;
  final double stockActual;

  const AlertaStockReporte({
    required this.nombre,
    required this.nivel,
    required this.stockActual,
  });
}

class ProduccionRecienteReporte {
  final String producto;
  final double cantidad;
  final String usuario;
  final DateTime fecha;

  const ProduccionRecienteReporte({
    required this.producto,
    required this.cantidad,
    required this.usuario,
    required this.fecha,
  });
}

class ReporteEjecutivoData {
  final List<KpiReporte> kpis;
  final List<SerieDiaReporte> ventas7Dias;
  final List<MetodoPagoReporte> metodosPago;
  final List<TopProductoReporte> topProductos;
  final List<AlertaStockReporte> alertasStock;
  final List<ProduccionRecienteReporte> produccionesRecientes;

  const ReporteEjecutivoData({
    required this.kpis,
    required this.ventas7Dias,
    required this.metodosPago,
    required this.topProductos,
    required this.alertasStock,
    required this.produccionesRecientes,
  });
}

class ReportesEjecutivoSupabase {
  static Future<ReporteEjecutivoData> obtenerReporteEjecutivo() async {
    final cliente = SupabaseCliente.cliente;
    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioManana = inicioHoy.add(const Duration(days: 1));
    final inicioSemana = inicioHoy.subtract(const Duration(days: 6));

    final ventasHoyResponse = await cliente
        .from('ventas')
        .select('id, total, metodo_pago, created_at')
        .gte('created_at', inicioHoy.toIso8601String())
        .lt('created_at', inicioManana.toIso8601String())
        .eq('estado', 'pagada');

    final ventas7DiasResponse = await cliente
        .from('ventas')
        .select('id, total, metodo_pago, created_at')
        .gte('created_at', inicioSemana.toIso8601String())
        .lt('created_at', inicioManana.toIso8601String())
        .eq('estado', 'pagada');

    final detalleVentasResponse = await cliente
        .from('detalle_venta')
        .select('nombre_producto, cantidad, subtotal')
        .gte('created_at', inicioSemana.toIso8601String())
        .lt('created_at', inicioManana.toIso8601String());

    final ingredientesResponse = await cliente
        .from('ingredientes')
        .select('nombre, stock_actual, stock_minimo, stock_critico')
        .eq('activo', true);

    final productosResponse = await cliente
        .from('productos')
        .select(
          'nombre, stock_actual, stock_minimo, stock_critico, controla_stock',
        )
        .eq('activo', true)
        .eq('controla_stock', true);

    final produccionesResponse = await cliente
        .from('producciones')
        .select('''
          cantidad_producida,
          created_at,
          producto:productos(nombre),
          usuario:usuarios(nombre)
        ''')
        .order('created_at', ascending: false)
        .limit(8);

    final totalVentasHoy = _sumarCampo(ventasHoyResponse, 'total');
    final cantidadVentasHoy = ventasHoyResponse.length;
    final ticketPromedio = cantidadVentasHoy == 0
        ? 0.0
        : totalVentasHoy / cantidadVentasHoy;

    double totalEfectivo = 0;
    double totalTransferencia = 0;
    double totalTarjeta = 0;

    for (final item in ventasHoyResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final metodo = (mapa['metodo_pago'] ?? '').toString();
      final total = (mapa['total'] as num).toDouble();

      if (metodo == 'efectivo') totalEfectivo += total;
      if (metodo == 'transferencia') totalTransferencia += total;
      if (metodo == 'tarjeta') totalTarjeta += total;
    }

    final ventas7Dias = <SerieDiaReporte>[];
    for (int i = 0; i < 7; i++) {
      final dia = inicioSemana.add(Duration(days: i));
      final siguiente = dia.add(const Duration(days: 1));

      double totalDia = 0;
      for (final item in ventas7DiasResponse) {
        final mapa = Map<String, dynamic>.from(item as Map);
        final fecha = DateTime.parse(mapa['created_at'] as String).toLocal();
        if (!fecha.isBefore(dia) && fecha.isBefore(siguiente)) {
          totalDia += (mapa['total'] as num).toDouble();
        }
      }

      ventas7Dias.add(
        SerieDiaReporte(
          etiqueta: _nombreDia(dia.weekday),
          valor: totalDia,
        ),
      );
    }

    final metodosPago = <MetodoPagoReporte>[
      MetodoPagoReporte(
        metodo: 'Efectivo',
        total: totalEfectivo,
      ),
      MetodoPagoReporte(
        metodo: 'Transferencia',
        total: totalTransferencia,
      ),
      MetodoPagoReporte(
        metodo: 'Tarjeta',
        total: totalTarjeta,
      ),
    ];

    final Map<String, TopProductoReporte> acumuladoProductos = {};
    for (final item in detalleVentasResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre_producto'] ?? '').toString();
      final cantidad = (mapa['cantidad'] as num).toInt();
      final subtotal = (mapa['subtotal'] as num).toDouble();

      final actual = acumuladoProductos[nombre];
      if (actual == null) {
        acumuladoProductos[nombre] = TopProductoReporte(
          nombre: nombre,
          cantidad: cantidad,
          total: subtotal,
        );
      } else {
        acumuladoProductos[nombre] = TopProductoReporte(
          nombre: nombre,
          cantidad: actual.cantidad + cantidad,
          total: actual.total + subtotal,
        );
      }
    }

    final topProductos = acumuladoProductos.values.toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

    final alertasStock = <AlertaStockReporte>[];

    for (final item in ingredientesResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre'] ?? '').toString();
      final stockActual = (mapa['stock_actual'] as num).toDouble();
      final stockMinimo = (mapa['stock_minimo'] as num).toDouble();
      final stockCritico = (mapa['stock_critico'] as num).toDouble();

      if (stockActual <= stockCritico) {
        alertasStock.add(
          AlertaStockReporte(
            nombre: nombre,
            nivel: 'Crítico',
            stockActual: stockActual,
          ),
        );
      } else if (stockActual <= stockMinimo) {
        alertasStock.add(
          AlertaStockReporte(
            nombre: nombre,
            nivel: 'Mínimo',
            stockActual: stockActual,
          ),
        );
      }
    }

    for (final item in productosResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre'] ?? '').toString();
      final stockActual = (mapa['stock_actual'] as num).toDouble();
      final stockMinimo = (mapa['stock_minimo'] as num).toDouble();
      final stockCritico = (mapa['stock_critico'] as num).toDouble();

      if (stockActual <= stockCritico) {
        alertasStock.add(
          AlertaStockReporte(
            nombre: '$nombre (producto)',
            nivel: 'Crítico',
            stockActual: stockActual,
          ),
        );
      } else if (stockActual <= stockMinimo) {
        alertasStock.add(
          AlertaStockReporte(
            nombre: '$nombre (producto)',
            nivel: 'Mínimo',
            stockActual: stockActual,
          ),
        );
      }
    }

    alertasStock.sort((a, b) {
      if (a.nivel == b.nivel) return a.nombre.compareTo(b.nombre);
      if (a.nivel == 'Crítico') return -1;
      return 1;
    });

    final produccionesRecientes = produccionesResponse
        .map<ProduccionRecienteReporte>((item) {
          final mapa = Map<String, dynamic>.from(item as Map);
          final producto =
              Map<String, dynamic>.from(mapa['producto'] as Map? ?? {});
          final usuario =
              Map<String, dynamic>.from(mapa['usuario'] as Map? ?? {});

          return ProduccionRecienteReporte(
            producto: (producto['nombre'] ?? 'Sin producto').toString(),
            cantidad: (mapa['cantidad_producida'] as num).toDouble(),
            usuario: (usuario['nombre'] ?? 'Sin usuario').toString(),
            fecha: DateTime.parse(mapa['created_at'] as String).toLocal(),
          );
        })
        .toList();

    final totalAlertasCriticas =
        alertasStock.where((e) => e.nivel == 'Crítico').length;

    final kpis = <KpiReporte>[
      KpiReporte(
        titulo: 'Ventas hoy',
        valor: '$cantidadVentasHoy',
        subtitulo: 'Transacciones del día',
      ),
      KpiReporte(
        titulo: 'Total vendido',
        valor: '\$${totalVentasHoy.toStringAsFixed(2)}',
        subtitulo: 'Ingreso bruto de hoy',
      ),
      KpiReporte(
        titulo: 'Ticket promedio',
        valor: '\$${ticketPromedio.toStringAsFixed(2)}',
        subtitulo: 'Promedio por venta',
      ),
      KpiReporte(
        titulo: 'Alertas críticas',
        valor: '$totalAlertasCriticas',
        subtitulo: 'Inventario y stock comprometido',
      ),
    ];

    return ReporteEjecutivoData(
      kpis: kpis,
      ventas7Dias: ventas7Dias,
      metodosPago: metodosPago,
      topProductos: topProductos.take(8).toList(),
      alertasStock: alertasStock.take(10).toList(),
      produccionesRecientes: produccionesRecientes,
    );
  }

  static double _sumarCampo(List<dynamic> lista, String campo) {
    double total = 0;
    for (final item in lista) {
      final mapa = Map<String, dynamic>.from(item as Map);
      total += (mapa[campo] as num).toDouble();
    }
    return total;
  }

  static String _nombreDia(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mié';
      case DateTime.thursday:
        return 'Jue';
      case DateTime.friday:
        return 'Vie';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }
}