import '../../../../nucleo/constantes/supabase_cliente.dart';

class KpiReporte {
  final String titulo;
  final String valor;
  final String subtitulo;
  final double variacionPorcentual;
  final bool mostrarVariacion;

  const KpiReporte({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    this.variacionPorcentual = 0,
    this.mostrarVariacion = false,
  });
}

class SerieDiaReporte {
  final String etiqueta;
  final double valor;
  final int cantidadVentas;

  const SerieDiaReporte({
    required this.etiqueta,
    required this.valor,
    this.cantidadVentas = 0,
  });
}

class SerieHoraReporte {
  final String hora;
  final double total;
  final int ventas;

  const SerieHoraReporte({
    required this.hora,
    required this.total,
    required this.ventas,
  });
}

class MetodoPagoReporte {
  final String metodo;
  final double total;
  final int cantidad;
  final double porcentaje;

  const MetodoPagoReporte({
    required this.metodo,
    required this.total,
    required this.cantidad,
    required this.porcentaje,
  });
}

class TopProductoReporte {
  final String nombre;
  final String categoria;
  final int cantidad;
  final double total;
  final double porcentaje;

  const TopProductoReporte({
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.total,
    required this.porcentaje,
  });
}

class CategoriaReporte {
  final String categoria;
  final int cantidad;
  final double total;
  final double porcentaje;

  const CategoriaReporte({
    required this.categoria,
    required this.cantidad,
    required this.total,
    required this.porcentaje,
  });
}

class VendedorReporte {
  final String nombre;
  final String usuario;
  final int ventas;
  final double total;
  final double ticketPromedio;

  const VendedorReporte({
    required this.nombre,
    required this.usuario,
    required this.ventas,
    required this.total,
    required this.ticketPromedio,
  });
}

class AlertaStockReporte {
  final String nombre;
  final String tipo;
  final String nivel;
  final double stockActual;
  final double stockMinimo;
  final double stockCritico;

  const AlertaStockReporte({
    required this.nombre,
    required this.tipo,
    required this.nivel,
    required this.stockActual,
    required this.stockMinimo,
    required this.stockCritico,
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

class InsightReporte {
  final String titulo;
  final String descripcion;
  final String tipo;

  const InsightReporte({
    required this.titulo,
    required this.descripcion,
    required this.tipo,
  });
}

class ReporteEjecutivoData {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final DateTime fechaInicioAnterior;
  final DateTime fechaFinAnterior;

  final double totalVendido;
  final double totalAnterior;
  final int cantidadVentas;
  final int cantidadVentasAnterior;
  final int productosVendidos;
  final int productosVendidosAnterior;
  final double ticketPromedio;
  final double ticketPromedioAnterior;

  final String mejorProducto;
  final String mejorVendedor;
  final String horaFuerte;

  final List<KpiReporte> kpis;
  final List<SerieDiaReporte> ventasPorDia;
  final List<SerieHoraReporte> ventasPorHora;
  final List<MetodoPagoReporte> metodosPago;
  final List<TopProductoReporte> topProductosCantidad;
  final List<TopProductoReporte> topProductosIngresos;
  final List<CategoriaReporte> categorias;
  final List<VendedorReporte> vendedores;
  final List<AlertaStockReporte> alertasStock;
  final List<ProduccionRecienteReporte> produccionesRecientes;
  final List<InsightReporte> insights;

  const ReporteEjecutivoData({
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaInicioAnterior,
    required this.fechaFinAnterior,
    required this.totalVendido,
    required this.totalAnterior,
    required this.cantidadVentas,
    required this.cantidadVentasAnterior,
    required this.productosVendidos,
    required this.productosVendidosAnterior,
    required this.ticketPromedio,
    required this.ticketPromedioAnterior,
    required this.mejorProducto,
    required this.mejorVendedor,
    required this.horaFuerte,
    required this.kpis,
    required this.ventasPorDia,
    required this.ventasPorHora,
    required this.metodosPago,
    required this.topProductosCantidad,
    required this.topProductosIngresos,
    required this.categorias,
    required this.vendedores,
    required this.alertasStock,
    required this.produccionesRecientes,
    required this.insights,
  });
}

class ReportesEjecutivoSupabase {
  static Future<ReporteEjecutivoData> obtenerReporteEjecutivo({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final cliente = SupabaseCliente.cliente;

    final ahora = DateTime.now();

    final inicio = fechaInicio == null
        ? DateTime(ahora.year, ahora.month, ahora.day)
        : DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);

    final finBase = fechaFin == null
        ? DateTime(ahora.year, ahora.month, ahora.day)
        : DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

    final finExclusivo = finBase.add(const Duration(days: 1));

    final diasRango = finExclusivo.difference(inicio).inDays <= 0
        ? 1
        : finExclusivo.difference(inicio).inDays;

    final inicioAnterior = inicio.subtract(Duration(days: diasRango));
    final finAnterior = inicio;

    final ventasResponse = await cliente
        .from('ventas')
        .select('''
          id,
          created_at,
          metodo_pago,
          subtotal,
          total,
          estado,
          usuario:usuarios!ventas_usuario_id_fkey(nombre, usuario)
        ''')
        .gte('created_at', _fechaSql(inicio))
        .lt('created_at', _fechaSql(finExclusivo))
        .eq('estado', 'pagada')
        .order('created_at', ascending: true);

    final ventasAnteriorResponse = await cliente
        .from('ventas')
        .select('id, created_at, total, estado')
        .gte('created_at', _fechaSql(inicioAnterior))
        .lt('created_at', _fechaSql(finAnterior))
        .eq('estado', 'pagada');

    final ventas = _normalizarLista(ventasResponse);
    final ventasAnterior = _normalizarLista(ventasAnteriorResponse);

    final idsVentas = ventas.map((v) => v['id'] as int).toList();
    final idsVentasAnterior =
        ventasAnterior.map((v) => v['id'] as int).toList();

    final detalles = idsVentas.isEmpty
        ? <Map<String, dynamic>>[]
        : _normalizarLista(
            await cliente
                .from('detalle_venta')
                .select('''
                  id,
                  venta_id,
                  created_at,
                  nombre_producto,
                  categoria_producto,
                  precio_unitario,
                  cantidad,
                  subtotal,
                  sabores
                ''')
                .inFilter('venta_id', idsVentas),
          );

    final detallesAnterior = idsVentasAnterior.isEmpty
        ? <Map<String, dynamic>>[]
        : _normalizarLista(
            await cliente
                .from('detalle_venta')
                .select('id, venta_id, created_at, cantidad, subtotal')
                .inFilter('venta_id', idsVentasAnterior),
          );

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
        .limit(10);

    final totalVendido = _sumarCampo(ventas, 'total');
    final totalAnterior = _sumarCampo(ventasAnterior, 'total');

    final cantidadVentas = ventas.length;
    final cantidadVentasAnterior = ventasAnterior.length;

    final productosVendidos = _sumarCantidad(detalles);
    final productosVendidosAnterior = _sumarCantidad(detallesAnterior);

    final ticketPromedio =
        cantidadVentas == 0 ? 0.0 : totalVendido / cantidadVentas;

    final ticketPromedioAnterior = cantidadVentasAnterior == 0
        ? 0.0
        : totalAnterior / cantidadVentasAnterior;

    final ventasPorDia = _construirVentasPorDia(
      ventas: ventas,
      inicio: inicio,
      dias: diasRango,
    );

    final ventasPorHora = _construirVentasPorHora(ventas);
    final metodosPago = _construirMetodosPago(ventas, totalVendido);
    final topCantidad = _construirTopProductos(detalles, porCantidad: true);
    final topIngresos = _construirTopProductos(detalles, porCantidad: false);
    final categorias = _construirCategorias(detalles);
    final vendedores = _construirVendedores(ventas);
    final alertas = _construirAlertas(
      ingredientesResponse: ingredientesResponse,
      productosResponse: productosResponse,
    );
    final producciones = _construirProducciones(produccionesResponse);

    final mejorProducto =
        topCantidad.isEmpty ? 'Sin datos' : topCantidad.first.nombre;
    final mejorVendedor =
        vendedores.isEmpty ? 'Sin datos' : vendedores.first.nombre;
    final horaFuerte =
        ventasPorHora.isEmpty ? 'Sin datos' : ventasPorHora.first.hora;

    final kpis = <KpiReporte>[
      KpiReporte(
        titulo: 'Total vendido',
        valor: '\$${totalVendido.toStringAsFixed(2)}',
        subtitulo: 'Ingresos del período seleccionado',
        variacionPorcentual: _variacion(totalVendido, totalAnterior),
        mostrarVariacion: true,
      ),
      KpiReporte(
        titulo: 'Ventas',
        valor: '$cantidadVentas',
        subtitulo: 'Transacciones pagadas',
        variacionPorcentual: _variacion(
          cantidadVentas.toDouble(),
          cantidadVentasAnterior.toDouble(),
        ),
        mostrarVariacion: true,
      ),
      KpiReporte(
        titulo: 'Ticket promedio',
        valor: '\$${ticketPromedio.toStringAsFixed(2)}',
        subtitulo: 'Promedio por venta',
        variacionPorcentual: _variacion(ticketPromedio, ticketPromedioAnterior),
        mostrarVariacion: true,
      ),
      KpiReporte(
        titulo: 'Productos vendidos',
        valor: '$productosVendidos',
        subtitulo: 'Unidades registradas',
        variacionPorcentual: _variacion(
          productosVendidos.toDouble(),
          productosVendidosAnterior.toDouble(),
        ),
        mostrarVariacion: true,
      ),
      KpiReporte(
        titulo: 'Producto líder',
        valor: mejorProducto,
        subtitulo: 'Mayor rotación por cantidad',
      ),
      KpiReporte(
        titulo: 'Hora fuerte',
        valor: horaFuerte,
        subtitulo: 'Franja con mayor ingreso',
      ),
      KpiReporte(
        titulo: 'Mejor vendedor',
        valor: mejorVendedor,
        subtitulo: 'Mayor venta acumulada',
      ),
      KpiReporte(
        titulo: 'Alertas críticas',
        valor: '${alertas.where((e) => e.nivel == 'Crítico').length}',
        subtitulo: 'Stock en riesgo operativo',
      ),
    ];

    final insights = _construirInsights(
      totalVendido: totalVendido,
      totalAnterior: totalAnterior,
      cantidadVentas: cantidadVentas,
      ticketPromedio: ticketPromedio,
      mejorProducto: mejorProducto,
      mejorVendedor: mejorVendedor,
      horaFuerte: horaFuerte,
      metodos: metodosPago,
      categorias: categorias,
      alertas: alertas,
    );

    return ReporteEjecutivoData(
      fechaInicio: inicio,
      fechaFin: finBase,
      fechaInicioAnterior: inicioAnterior,
      fechaFinAnterior: finAnterior.subtract(const Duration(days: 1)),
      totalVendido: totalVendido,
      totalAnterior: totalAnterior,
      cantidadVentas: cantidadVentas,
      cantidadVentasAnterior: cantidadVentasAnterior,
      productosVendidos: productosVendidos,
      productosVendidosAnterior: productosVendidosAnterior,
      ticketPromedio: ticketPromedio,
      ticketPromedioAnterior: ticketPromedioAnterior,
      mejorProducto: mejorProducto,
      mejorVendedor: mejorVendedor,
      horaFuerte: horaFuerte,
      kpis: kpis,
      ventasPorDia: ventasPorDia,
      ventasPorHora: ventasPorHora,
      metodosPago: metodosPago,
      topProductosCantidad: topCantidad.take(10).toList(),
      topProductosIngresos: topIngresos.take(10).toList(),
      categorias: categorias.take(8).toList(),
      vendedores: vendedores.take(8).toList(),
      alertasStock: alertas.take(14).toList(),
      produccionesRecientes: producciones,
      insights: insights,
    );
  }

  static List<Map<String, dynamic>> _normalizarLista(dynamic response) {
    return (response as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  static double _sumarCampo(List<Map<String, dynamic>> lista, String campo) {
    double total = 0;
    for (final item in lista) {
      total += (item[campo] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  static int _sumarCantidad(List<Map<String, dynamic>> lista) {
    int total = 0;
    for (final item in lista) {
      total += (item['cantidad'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  static double _variacion(double actual, double anterior) {
    if (anterior == 0 && actual == 0) return 0;
    if (anterior == 0 && actual > 0) return 100;
    return ((actual - anterior) / anterior) * 100;
  }

  static List<SerieDiaReporte> _construirVentasPorDia({
    required List<Map<String, dynamic>> ventas,
    required DateTime inicio,
    required int dias,
  }) {
    final resultado = <SerieDiaReporte>[];

    for (int i = 0; i < dias; i++) {
      final dia = inicio.add(Duration(days: i));
      final siguiente = dia.add(const Duration(days: 1));

      double total = 0;
      int cantidad = 0;

      for (final venta in ventas) {
        final fecha = DateTime.parse(venta['created_at'] as String);
        if (!fecha.isBefore(dia) && fecha.isBefore(siguiente)) {
          total += (venta['total'] as num?)?.toDouble() ?? 0;
          cantidad++;
        }
      }

      resultado.add(
        SerieDiaReporte(
          etiqueta: dias <= 10 ? _nombreDia(dia.weekday) : _fechaCorta(dia),
          valor: total,
          cantidadVentas: cantidad,
        ),
      );
    }

    return resultado;
  }

  static List<SerieHoraReporte> _construirVentasPorHora(
    List<Map<String, dynamic>> ventas,
  ) {
    final Map<int, double> totalPorHora = {};
    final Map<int, int> ventasPorHora = {};

    for (int hora = 0; hora < 24; hora++) {
      totalPorHora[hora] = 0;
      ventasPorHora[hora] = 0;
    }

    for (final venta in ventas) {
      final fecha = DateTime.parse(venta['created_at'] as String);
      final total = (venta['total'] as num?)?.toDouble() ?? 0;
      totalPorHora[fecha.hour] = (totalPorHora[fecha.hour] ?? 0) + total;
      ventasPorHora[fecha.hour] = (ventasPorHora[fecha.hour] ?? 0) + 1;
    }

    final resultado = totalPorHora.entries
        .where(
          (entry) => entry.value > 0 || (ventasPorHora[entry.key] ?? 0) > 0,
        )
        .map(
          (entry) => SerieHoraReporte(
            hora: '${entry.key.toString().padLeft(2, '0')}:00',
            total: entry.value,
            ventas: ventasPorHora[entry.key] ?? 0,
          ),
        )
        .toList();

    resultado.sort((a, b) => b.total.compareTo(a.total));
    return resultado;
  }

  static List<MetodoPagoReporte> _construirMetodosPago(
    List<Map<String, dynamic>> ventas,
    double totalGeneral,
  ) {
    final Map<String, double> totales = {};
    final Map<String, int> cantidades = {};

    for (final venta in ventas) {
      final metodo = (venta['metodo_pago'] ?? 'sin método').toString();
      final nombre = _nombreMetodo(metodo);
      final total = (venta['total'] as num?)?.toDouble() ?? 0;

      totales[nombre] = (totales[nombre] ?? 0) + total;
      cantidades[nombre] = (cantidades[nombre] ?? 0) + 1;
    }

    final resultado = totales.entries
        .map(
          (entry) => MetodoPagoReporte(
            metodo: entry.key,
            total: entry.value,
            cantidad: cantidades[entry.key] ?? 0,
            porcentaje: totalGeneral == 0 ? 0 : (entry.value / totalGeneral) * 100,
          ),
        )
        .toList();

    resultado.sort((a, b) => b.total.compareTo(a.total));
    return resultado;
  }

  static List<TopProductoReporte> _construirTopProductos(
    List<Map<String, dynamic>> detalles, {
    required bool porCantidad,
  }) {
    final Map<String, int> cantidades = {};
    final Map<String, double> totales = {};
    final Map<String, String> categorias = {};

    int cantidadGeneral = 0;
    double totalGeneral = 0;

    for (final detalle in detalles) {
      final nombre = (detalle['nombre_producto'] ?? 'Sin producto').toString();
      final categoria =
          (detalle['categoria_producto'] ?? 'Sin categoría').toString();
      final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 0;
      final subtotal = (detalle['subtotal'] as num?)?.toDouble() ?? 0;

      cantidades[nombre] = (cantidades[nombre] ?? 0) + cantidad;
      totales[nombre] = (totales[nombre] ?? 0) + subtotal;
      categorias[nombre] = categoria;
      cantidadGeneral += cantidad;
      totalGeneral += subtotal;
    }

    final resultado = cantidades.keys.map((nombre) {
      final cantidad = cantidades[nombre] ?? 0;
      final total = totales[nombre] ?? 0;

      return TopProductoReporte(
        nombre: nombre,
        categoria: categorias[nombre] ?? 'Sin categoría',
        cantidad: cantidad,
        total: total,
        porcentaje: porCantidad
            ? cantidadGeneral == 0
                ? 0
                : (cantidad / cantidadGeneral) * 100
            : totalGeneral == 0
                ? 0
                : (total / totalGeneral) * 100,
      );
    }).toList();

    if (porCantidad) {
      resultado.sort((a, b) => b.cantidad.compareTo(a.cantidad));
    } else {
      resultado.sort((a, b) => b.total.compareTo(a.total));
    }

    return resultado;
  }

  static List<CategoriaReporte> _construirCategorias(
    List<Map<String, dynamic>> detalles,
  ) {
    final Map<String, int> cantidades = {};
    final Map<String, double> totales = {};
    double totalGeneral = 0;

    for (final detalle in detalles) {
      final categoria =
          (detalle['categoria_producto'] ?? 'Sin categoría').toString();
      final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 0;
      final subtotal = (detalle['subtotal'] as num?)?.toDouble() ?? 0;

      cantidades[categoria] = (cantidades[categoria] ?? 0) + cantidad;
      totales[categoria] = (totales[categoria] ?? 0) + subtotal;
      totalGeneral += subtotal;
    }

    final resultado = totales.keys.map((categoria) {
      final total = totales[categoria] ?? 0;

      return CategoriaReporte(
        categoria: categoria,
        cantidad: cantidades[categoria] ?? 0,
        total: total,
        porcentaje: totalGeneral == 0 ? 0 : (total / totalGeneral) * 100,
      );
    }).toList();

    resultado.sort((a, b) => b.total.compareTo(a.total));
    return resultado;
  }

  static List<VendedorReporte> _construirVendedores(
    List<Map<String, dynamic>> ventas,
  ) {
    final Map<String, double> totales = {};
    final Map<String, int> cantidades = {};
    final Map<String, String> usuarios = {};

    for (final venta in ventas) {
      final usuario = Map<String, dynamic>.from(venta['usuario'] as Map? ?? {});
      final nombre = (usuario['nombre'] ?? 'Sin vendedor').toString();
      final login = (usuario['usuario'] ?? '').toString();
      final total = (venta['total'] as num?)?.toDouble() ?? 0;

      totales[nombre] = (totales[nombre] ?? 0) + total;
      cantidades[nombre] = (cantidades[nombre] ?? 0) + 1;
      usuarios[nombre] = login;
    }

    final resultado = totales.keys.map((nombre) {
      final ventasVendedor = cantidades[nombre] ?? 0;
      final total = totales[nombre] ?? 0;

      return VendedorReporte(
        nombre: nombre,
        usuario: usuarios[nombre] ?? '',
        ventas: ventasVendedor,
        total: total,
        ticketPromedio: ventasVendedor == 0 ? 0 : total / ventasVendedor,
      );
    }).toList();

    resultado.sort((a, b) => b.total.compareTo(a.total));
    return resultado;
  }

  static List<AlertaStockReporte> _construirAlertas({
    required dynamic ingredientesResponse,
    required dynamic productosResponse,
  }) {
    final alertas = <AlertaStockReporte>[];

    for (final item in ingredientesResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre'] ?? '').toString();
      final stockActual = (mapa['stock_actual'] as num?)?.toDouble() ?? 0;
      final stockMinimo = (mapa['stock_minimo'] as num?)?.toDouble() ?? 0;
      final stockCritico = (mapa['stock_critico'] as num?)?.toDouble() ?? 0;

      if (stockActual <= stockCritico) {
        alertas.add(
          AlertaStockReporte(
            nombre: nombre,
            tipo: 'Ingrediente',
            nivel: 'Crítico',
            stockActual: stockActual,
            stockMinimo: stockMinimo,
            stockCritico: stockCritico,
          ),
        );
      } else if (stockActual <= stockMinimo) {
        alertas.add(
          AlertaStockReporte(
            nombre: nombre,
            tipo: 'Ingrediente',
            nivel: 'Mínimo',
            stockActual: stockActual,
            stockMinimo: stockMinimo,
            stockCritico: stockCritico,
          ),
        );
      }
    }

    for (final item in productosResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre'] ?? '').toString();
      final stockActual = (mapa['stock_actual'] as num?)?.toDouble() ?? 0;
      final stockMinimo = (mapa['stock_minimo'] as num?)?.toDouble() ?? 0;
      final stockCritico = (mapa['stock_critico'] as num?)?.toDouble() ?? 0;

      if (stockActual <= stockCritico) {
        alertas.add(
          AlertaStockReporte(
            nombre: nombre,
            tipo: 'Producto',
            nivel: 'Crítico',
            stockActual: stockActual,
            stockMinimo: stockMinimo,
            stockCritico: stockCritico,
          ),
        );
      } else if (stockActual <= stockMinimo) {
        alertas.add(
          AlertaStockReporte(
            nombre: nombre,
            tipo: 'Producto',
            nivel: 'Mínimo',
            stockActual: stockActual,
            stockMinimo: stockMinimo,
            stockCritico: stockCritico,
          ),
        );
      }
    }

    alertas.sort((a, b) {
      if (a.nivel == b.nivel) return a.nombre.compareTo(b.nombre);
      if (a.nivel == 'Crítico') return -1;
      return 1;
    });

    return alertas;
  }

  static List<ProduccionRecienteReporte> _construirProducciones(
    dynamic produccionesResponse,
  ) {
    return (produccionesResponse as List).map<ProduccionRecienteReporte>((item) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final producto = Map<String, dynamic>.from(mapa['producto'] as Map? ?? {});
      final usuario = Map<String, dynamic>.from(mapa['usuario'] as Map? ?? {});

      return ProduccionRecienteReporte(
        producto: (producto['nombre'] ?? 'Sin producto').toString(),
        cantidad: (mapa['cantidad_producida'] as num?)?.toDouble() ?? 0,
        usuario: (usuario['nombre'] ?? 'Sin usuario').toString(),
        fecha: DateTime.parse(mapa['created_at'] as String),
      );
    }).toList();
  }

  static List<InsightReporte> _construirInsights({
    required double totalVendido,
    required double totalAnterior,
    required int cantidadVentas,
    required double ticketPromedio,
    required String mejorProducto,
    required String mejorVendedor,
    required String horaFuerte,
    required List<MetodoPagoReporte> metodos,
    required List<CategoriaReporte> categorias,
    required List<AlertaStockReporte> alertas,
  }) {
    final insights = <InsightReporte>[];

    final variacion = _variacion(totalVendido, totalAnterior);

    if (cantidadVentas == 0) {
      insights.add(
        const InsightReporte(
          titulo: 'Sin ventas en el período',
          descripcion:
              'No existen ventas pagadas para el rango seleccionado. Revisa si el rango de fechas es correcto o si las ventas fueron registradas con otro estado.',
          tipo: 'advertencia',
        ),
      );
      return insights;
    }

    if (variacion > 10) {
      insights.add(
        InsightReporte(
          titulo: 'Crecimiento positivo',
          descripcion:
              'El negocio creció ${variacion.toStringAsFixed(1)}% frente al período anterior. Conviene revisar qué productos impulsaron ese resultado para repetir la estrategia.',
          tipo: 'positivo',
        ),
      );
    } else if (variacion < -10) {
      insights.add(
        InsightReporte(
          titulo: 'Caída de ventas',
          descripcion:
              'Las ventas bajaron ${variacion.abs().toStringAsFixed(1)}% frente al período anterior. Revisa horarios flojos, productos con baja rotación y disponibilidad de stock.',
          tipo: 'riesgo',
        ),
      );
    } else {
      insights.add(
        const InsightReporte(
          titulo: 'Ventas estables',
          descripcion:
              'El período se mantiene relativamente estable frente al anterior. La prioridad debe ser subir ticket promedio y mejorar productos de alta rotación.',
          tipo: 'neutral',
        ),
      );
    }

    insights.add(
      InsightReporte(
        titulo: 'Producto ganador',
        descripcion:
            '$mejorProducto lidera la rotación. Debe mantenerse con stock suficiente y puede usarse como producto ancla para combos o promociones.',
        tipo: 'positivo',
      ),
    );

    if (metodos.isNotEmpty) {
      insights.add(
        InsightReporte(
          titulo: 'Método de pago dominante',
          descripcion:
              '${metodos.first.metodo} concentra el ${metodos.first.porcentaje.toStringAsFixed(1)}% del ingreso. Esto ayuda a controlar caja, transferencias y datáfono con más precisión.',
          tipo: 'neutral',
        ),
      );
    }

    if (categorias.isNotEmpty) {
      insights.add(
        InsightReporte(
          titulo: 'Categoría más fuerte',
          descripcion:
              '${categorias.first.categoria} representa el ${categorias.first.porcentaje.toStringAsFixed(1)}% del ingreso del período. Es la línea que más pesa en el resultado.',
          tipo: 'positivo',
        ),
      );
    }

    insights.add(
      InsightReporte(
        titulo: 'Hora de mayor venta',
        descripcion:
            'La franja más fuerte es $horaFuerte. Refuerza producción, mise en place y personal antes de esa hora para evitar pérdida de ventas.',
        tipo: 'neutral',
      ),
    );

    final criticas = alertas.where((e) => e.nivel == 'Crítico').length;
    if (criticas > 0) {
      insights.add(
        InsightReporte(
          titulo: 'Riesgo de inventario',
          descripcion:
              'Hay $criticas alerta(s) críticas de stock. Resolver esto debe ser prioridad porque puede afectar ventas de productos clave.',
          tipo: 'riesgo',
        ),
      );
    }

    if (ticketPromedio > 0) {
      insights.add(
        InsightReporte(
          titulo: 'Ticket promedio',
          descripcion:
              'El ticket promedio actual es \$${ticketPromedio.toStringAsFixed(2)}. Para subirlo, conviene empujar combos, bebidas y productos complementarios.',
          tipo: 'neutral',
        ),
      );
    }

    return insights;
  }

  static String _nombreMetodo(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      case 'mixto':
        return 'Pago mixto';
      default:
        return metodo.isEmpty ? 'Sin método' : metodo;
    }
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

  static String _fechaCorta(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm';
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