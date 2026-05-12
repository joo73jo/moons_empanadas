import '../../../../nucleo/constantes/supabase_cliente.dart';

class DashboardResumen {
  final bool hayCajaAbierta;
  final int? cajaId;
  final double totalVentasHoy;
  final int cantidadVentasHoy;
  final int ingredientesCriticos;
  final int ingredientesMinimos;
  final int productosBajos;
  final List<String> alertas;

  const DashboardResumen({
    required this.hayCajaAbierta,
    required this.cajaId,
    required this.totalVentasHoy,
    required this.cantidadVentasHoy,
    required this.ingredientesCriticos,
    required this.ingredientesMinimos,
    required this.productosBajos,
    required this.alertas,
  });
}

class DashboardSupabase {
  static Future<DashboardResumen> obtenerResumen() async {
    final cliente = SupabaseCliente.cliente;

    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final cajaAbiertaResponse = await cliente
        .from('cajas')
        .select('id')
        .eq('estado', 'abierta')
        .order('fecha_apertura', ascending: false)
        .limit(1);

    final ventasHoyResponse = await cliente
        .from('ventas')
        .select('id, total')
        .gte('created_at', inicioDia.toIso8601String())
        .lt('created_at', finDia.toIso8601String())
        .eq('estado', 'pagada');

    final ingredientesResponse = await cliente
        .from('ingredientes')
        .select('id, nombre, stock_actual, stock_minimo, stock_critico')
        .eq('activo', true);

    final productosResponse = await cliente
        .from('productos')
        .select('id, nombre, stock_actual, stock_minimo, stock_critico, controla_stock')
        .eq('activo', true)
        .eq('controla_stock', true);

    final hayCajaAbierta = cajaAbiertaResponse.isNotEmpty;
    final cajaId = hayCajaAbierta
        ? (Map<String, dynamic>.from(cajaAbiertaResponse.first as Map))['id'] as int
        : null;

    double totalVentasHoy = 0;
    for (final item in ventasHoyResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      totalVentasHoy += (mapa['total'] as num).toDouble();
    }

    int ingredientesCriticos = 0;
    int ingredientesMinimos = 0;
    final List<String> alertas = [];

    for (final item in ingredientesResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre'] ?? '').toString();
      final stockActual = (mapa['stock_actual'] as num).toDouble();
      final stockMinimo = (mapa['stock_minimo'] as num).toDouble();
      final stockCritico = (mapa['stock_critico'] as num).toDouble();

      if (stockActual <= stockCritico) {
        ingredientesCriticos++;
        alertas.add('Crítico: $nombre');
      } else if (stockActual <= stockMinimo) {
        ingredientesMinimos++;
        alertas.add('Mínimo: $nombre');
      }
    }

    int productosBajos = 0;

    for (final item in productosResponse) {
      final mapa = Map<String, dynamic>.from(item as Map);
      final nombre = (mapa['nombre'] ?? '').toString();
      final stockActual = (mapa['stock_actual'] as num).toDouble();
      final stockMinimo = (mapa['stock_minimo'] as num).toDouble();
      final stockCritico = (mapa['stock_critico'] as num).toDouble();

      if (stockActual <= stockMinimo) {
        productosBajos++;
      }

      if (stockActual <= stockCritico) {
        alertas.add('Producto crítico: $nombre');
      }
    }

    if (hayCajaAbierta) {
      alertas.insert(0, 'Caja abierta #$cajaId');
    } else {
      alertas.insert(0, 'No hay caja abierta');
    }

    return DashboardResumen(
      hayCajaAbierta: hayCajaAbierta,
      cajaId: cajaId,
      totalVentasHoy: totalVentasHoy,
      cantidadVentasHoy: ventasHoyResponse.length,
      ingredientesCriticos: ingredientesCriticos,
      ingredientesMinimos: ingredientesMinimos,
      productosBajos: productosBajos,
      alertas: alertas.take(8).toList(),
    );
  }
}