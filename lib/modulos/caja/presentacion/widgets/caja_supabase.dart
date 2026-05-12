import '../../../../nucleo/constantes/supabase_cliente.dart';

class CajaResumen {
  final int id;
  final String estado;
  final double montoInicial;
  final double montoFinalContado;
  final double totalEfectivo;
  final double totalTransferencia;
  final double totalTarjeta;
  final double totalVentas;
  final double diferencia;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final int usuarioAperturaId;
  final int? usuarioCierreId;

  const CajaResumen({
    required this.id,
    required this.estado,
    required this.montoInicial,
    required this.montoFinalContado,
    required this.totalEfectivo,
    required this.totalTransferencia,
    required this.totalTarjeta,
    required this.totalVentas,
    required this.diferencia,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.usuarioAperturaId,
    required this.usuarioCierreId,
  });

  double get esperadoEnCaja => montoInicial + totalEfectivo;
}

class CajaSupabase {
  static Future<int> obtenerUsuarioIdPorLogin(String usuarioLogin) async {
    final respuesta = await SupabaseCliente.cliente
        .from('usuarios')
        .select('id')
        .eq('usuario', usuarioLogin)
        .eq('activo', true)
        .single();

    return respuesta['id'] as int;
  }

  static Future<CajaResumen?> obtenerCajaAbierta() async {
    final respuesta = await SupabaseCliente.cliente
        .from('cajas')
        .select()
        .eq('estado', 'abierta')
        .order('fecha_apertura', ascending: false)
        .limit(1);

    if (respuesta.isEmpty) return null;

    final caja = Map<String, dynamic>.from(respuesta.first as Map);
    return _mapearCaja(caja);
  }

  static Future<List<CajaResumen>> obtenerUltimasCajas({
    int limite = 10,
  }) async {
    final respuesta = await SupabaseCliente.cliente
        .from('cajas')
        .select()
        .order('id', ascending: false)
        .limit(limite);

    return respuesta.map<CajaResumen>((item) {
      return _mapearCaja(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  static Future<CajaResumen> abrirCaja({
    required String usuarioLogin,
    required double montoInicial,
  }) async {
    final usuarioId = await obtenerUsuarioIdPorLogin(usuarioLogin);

    final cajaAbierta = await obtenerCajaAbierta();
    if (cajaAbierta != null) {
      throw Exception('Ya existe una caja abierta.');
    }

    final respuesta = await SupabaseCliente.cliente
        .from('cajas')
        .insert({
          'usuario_apertura_id': usuarioId,
          'monto_inicial': montoInicial,
          'monto_final_contado': 0,
          'total_efectivo': 0,
          'total_transferencia': 0,
          'total_tarjeta': 0,
          'total_ventas': 0,
          'diferencia': 0,
          'estado': 'abierta',
        })
        .select()
        .single();

    return _mapearCaja(Map<String, dynamic>.from(respuesta));
  }

  static Future<CajaResumen> actualizarMontoInicial({
    required int cajaId,
    required double montoInicial,
  }) async {
    final respuesta = await SupabaseCliente.cliente
        .from('cajas')
        .update({
          'monto_inicial': montoInicial,
        })
        .eq('id', cajaId)
        .eq('estado', 'abierta')
        .select()
        .single();

    return _mapearCaja(Map<String, dynamic>.from(respuesta));
  }

  static Future<CajaResumen> cerrarCaja({
    required int cajaId,
    required String usuarioLogin,
    required double montoInicialManual,
    required double montoFinalContado,
  }) async {
    final usuarioId = await obtenerUsuarioIdPorLogin(usuarioLogin);

    final caja = await SupabaseCliente.cliente
        .from('cajas')
        .select()
        .eq('id', cajaId)
        .single();

    final mapa = Map<String, dynamic>.from(caja);
    final totalEfectivo = (mapa['total_efectivo'] as num).toDouble();

    final esperado = montoInicialManual + totalEfectivo;
    final diferencia = montoFinalContado - esperado;

    final respuesta = await SupabaseCliente.cliente
        .from('cajas')
        .update({
          'usuario_cierre_id': usuarioId,
          'monto_inicial': montoInicialManual,
          'monto_final_contado': montoFinalContado,
          'diferencia': diferencia,
          'estado': 'cerrada',
          'fecha_cierre': DateTime.now().toIso8601String(),
        })
        .eq('id', cajaId)
        .select()
        .single();

    return _mapearCaja(Map<String, dynamic>.from(respuesta));
  }

  static CajaResumen _mapearCaja(Map<String, dynamic> caja) {
    return CajaResumen(
      id: caja['id'] as int,
      estado: (caja['estado'] ?? '').toString(),
      montoInicial: (caja['monto_inicial'] as num?)?.toDouble() ?? 0,
      montoFinalContado:
          (caja['monto_final_contado'] as num?)?.toDouble() ?? 0,
      totalEfectivo: (caja['total_efectivo'] as num?)?.toDouble() ?? 0,
      totalTransferencia:
          (caja['total_transferencia'] as num?)?.toDouble() ?? 0,
      totalTarjeta: (caja['total_tarjeta'] as num?)?.toDouble() ?? 0,
      totalVentas: (caja['total_ventas'] as num?)?.toDouble() ?? 0,
      diferencia: (caja['diferencia'] as num?)?.toDouble() ?? 0,
      fechaApertura: DateTime.parse(caja['fecha_apertura'] as String),
      fechaCierre: caja['fecha_cierre'] != null
          ? DateTime.parse(caja['fecha_cierre'] as String)
          : null,
      usuarioAperturaId: caja['usuario_apertura_id'] as int,
      usuarioCierreId: caja['usuario_cierre_id'] as int?,
    );
  }
}