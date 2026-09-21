import '../../../../nucleo/constantes/supabase_cliente.dart';

class CategoriaGastoContable {
  final int id;
  final String nombre;
  final int orden;

  const CategoriaGastoContable({
    required this.id,
    required this.nombre,
    required this.orden,
  });
}

class ContabilidadDia {
  final DateTime fecha;

  final double ventasLocal;
  final double ventasPlataformas;
  final double descuentoPlataformas;
  final double domicilios;

  const ContabilidadDia({
    required this.fecha,
    required this.ventasLocal,
    required this.ventasPlataformas,
    required this.descuentoPlataformas,
    required this.domicilios,
  });

  double get totalConDomYPlat {
    return ventasLocal + ventasPlataformas - descuentoPlataformas - domicilios;
  }

  double get totalSinPlatNiDom {
    return ventasLocal - domicilios;
  }
}

class ResumenContabilidadSemana {
  final DateTime semanaInicio;
  final List<ContabilidadDia> dias;

  final List<CategoriaGastoContable> categoriasGasto;

  final Map<int, double> gastosPorCategoria;

  final List<String> plataformas;

  final Map<String, double> liquidacionesPlataforma;

  const ResumenContabilidadSemana({
    required this.semanaInicio,
    required this.dias,
    required this.categoriasGasto,
    required this.gastosPorCategoria,
    required this.plataformas,
    required this.liquidacionesPlataforma,
  });

  double get ventasLocal {
    return dias.fold(0, (total, dia) => total + dia.ventasLocal);
  }

  double get ventasPlataformas {
    return dias.fold(0, (total, dia) => total + dia.ventasPlataformas);
  }

  double get descuentoPlataformas {
    return dias.fold(0, (total, dia) => total + dia.descuentoPlataformas);
  }

  double get domicilios {
    return dias.fold(0, (total, dia) => total + dia.domicilios);
  }

  double get totalConDomYPlat {
    return dias.fold(0, (total, dia) => total + dia.totalConDomYPlat);
  }

  double get totalSinPlatNiDom {
    return dias.fold(0, (total, dia) => total + dia.totalSinPlatNiDom);
  }

  double get totalLiquidaciones {
    return liquidacionesPlataforma.values.fold(
      0,
      (total, valor) => total + valor,
    );
  }

  double get totalParaSemana {
    return totalSinPlatNiDom + totalLiquidaciones;
  }

  double get totalGastos {
    return gastosPorCategoria.values.fold(0, (total, valor) => total + valor);
  }

  double get liquidoSemana {
    return totalParaSemana - totalGastos;
  }

  double get mediaPorDia {
    return dias.isEmpty ? 0 : totalConDomYPlat / dias.length;
  }
}

class ContabilidadSupabase {
  static DateTime inicioSemana(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);

    return dia.subtract(Duration(days: dia.weekday - DateTime.monday));
  }

  static Future<List<ResumenContabilidadSemana>> obtenerMes(
    DateTime mes,
  ) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);

    final finMes = DateTime(mes.year, mes.month + 1, 1);

    /*
     * Incluimos cada semana que tenga al menos
     * un día dentro del mes seleccionado.
     */
    DateTime semana = inicioSemana(inicioMes);

    final semanas = <ResumenContabilidadSemana>[];

    while (semana.isBefore(finMes)) {
      final resumen = await obtenerSemana(semana);

      semanas.add(resumen);

      semana = semana.add(const Duration(days: 7));
    }

    return semanas;
  }

  static Future<ResumenContabilidadSemana> obtenerSemana(DateTime fecha) async {
    final cliente = SupabaseCliente.cliente;

    final inicio = inicioSemana(fecha);

    final fin = inicio.add(const Duration(days: 7));

    final ventasResponse = await cliente
        .from('ventas')
        .select('''
          id,
          fecha_contable,
          total,
          plataforma,
          descuento_plataforma,
          valor_domicilio,
          estado
        ''')
        .gte('fecha_contable', _fecha(inicio))
        .lt('fecha_contable', _fecha(fin))
        .eq('estado', 'pagada');

    final categoriasResponse = await cliente
        .from('contabilidad_categorias_gasto')
        .select('id, nombre, orden')
        .eq('activo', true)
        .order('orden', ascending: true);

    final gastosResponse = await cliente
        .from('contabilidad_gastos_semanales')
        .select('categoria_id, valor')
        .eq('semana_inicio', _fecha(inicio));

    final liquidacionesResponse = await cliente
        .from('contabilidad_liquidaciones_plataforma')
        .select('plataforma, valor')
        .eq('semana_inicio', _fecha(inicio));

    final plataformasResponse = await cliente
        .from('plataformas_configuracion')
        .select('nombre')
        .eq('activo', true)
        .order('orden', ascending: true);

    final ventas = (ventasResponse as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();

    final categorias = (categoriasResponse as List).map<CategoriaGastoContable>(
      (item) {
        final mapa = Map<String, dynamic>.from(item as Map);

        return CategoriaGastoContable(
          id: (mapa['id'] as num).toInt(),
          nombre: (mapa['nombre'] ?? '').toString(),
          orden: (mapa['orden'] as num?)?.toInt() ?? 0,
        );
      },
    ).toList();

    final gastos = <int, double>{};

    for (final item in gastosResponse as List) {
      final mapa = Map<String, dynamic>.from(item as Map);

      gastos[(mapa['categoria_id'] as num).toInt()] =
          (mapa['valor'] as num?)?.toDouble() ?? 0;
    }

    final liquidaciones = <String, double>{};

    for (final item in liquidacionesResponse as List) {
      final mapa = Map<String, dynamic>.from(item as Map);

      liquidaciones[(mapa['plataforma'] ?? '').toString()] =
          (mapa['valor'] as num?)?.toDouble() ?? 0;
    }

    final plataformas = (plataformasResponse as List)
        .map<String>((item) {
          final mapa = Map<String, dynamic>.from(item as Map);

          return (mapa['nombre'] ?? '').toString();
        })
        .where((nombre) => nombre.trim().isNotEmpty)
        .toList();

    final dias = <ContabilidadDia>[];

    for (int i = 0; i < 7; i++) {
      final dia = inicio.add(Duration(days: i));

      double local = 0;
      double plataformasDia = 0;
      double descuentos = 0;
      double domicilios = 0;

      for (final venta in ventas) {
        final fecha = DateTime.tryParse(
          (venta['fecha_contable'] ?? '').toString(),
        );

        if (fecha == null ||
            fecha.year != dia.year ||
            fecha.month != dia.month ||
            fecha.day != dia.day) {
          continue;
        }

        final total = (venta['total'] as num?)?.toDouble() ?? 0;

        final plataforma = (venta['plataforma'] ?? '').toString().trim();

        if (plataforma.isEmpty) {
          local += total;
        } else {
          plataformasDia += total;
        }

        descuentos += (venta['descuento_plataforma'] as num?)?.toDouble() ?? 0;

        domicilios += (venta['valor_domicilio'] as num?)?.toDouble() ?? 0;
      }

      dias.add(
        ContabilidadDia(
          fecha: dia,
          ventasLocal: local,
          ventasPlataformas: plataformasDia,
          descuentoPlataformas: descuentos,
          domicilios: domicilios,
        ),
      );
    }

    return ResumenContabilidadSemana(
      semanaInicio: inicio,
      dias: dias,
      categoriasGasto: categorias,
      gastosPorCategoria: gastos,
      plataformas: plataformas,
      liquidacionesPlataforma: liquidaciones,
    );
  }

  static Future<void> guardarGasto({
    required int categoriaId,
    required DateTime semanaInicio,
    required double valor,
  }) async {
    if (valor < 0) {
      throw Exception('El gasto no puede ser negativo.');
    }

    await SupabaseCliente.cliente.from('contabilidad_gastos_semanales').upsert({
      'categoria_id': categoriaId,
      'semana_inicio': _fecha(inicioSemana(semanaInicio)),
      'valor': valor,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'categoria_id,semana_inicio');
  }

  static Future<void> guardarLiquidacionPlataforma({
    required String plataforma,
    required DateTime semanaInicio,
    required double valor,
  }) async {
    if (valor < 0) {
      throw Exception('El valor no puede ser negativo.');
    }

    await SupabaseCliente.cliente
        .from('contabilidad_liquidaciones_plataforma')
        .upsert({
          'semana_inicio': _fecha(inicioSemana(semanaInicio)),
          'plataforma': plataforma.trim(),
          'valor': valor,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'semana_inicio,plataforma');
  }

  static Future<void> crearCategoriaGasto(String nombre) async {
    final limpio = nombre.trim();

    if (limpio.isEmpty) {
      throw Exception('Escribe el nombre del gasto.');
    }

    final existentes = await SupabaseCliente.cliente
        .from('contabilidad_categorias_gasto')
        .select('id, nombre, activo, orden');

    for (final item in existentes) {
      final mapa = Map<String, dynamic>.from(item as Map);

      final nombreExistente = (mapa['nombre'] ?? '').toString().trim();

      if (nombreExistente.toLowerCase() == limpio.toLowerCase()) {
        await SupabaseCliente.cliente
            .from('contabilidad_categorias_gasto')
            .update({
              'activo': true,
              'nombre': limpio,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', (mapa['id'] as num).toInt());

        return;
      }
    }

    int orden = 1;

    if (existentes.isNotEmpty) {
      for (final item in existentes) {
        final mapa = Map<String, dynamic>.from(item as Map);

        final actual = (mapa['orden'] as num?)?.toInt() ?? 0;

        if (actual >= orden) {
          orden = actual + 1;
        }
      }
    }

    await SupabaseCliente.cliente.from('contabilidad_categorias_gasto').insert({
      'nombre': limpio,
      'orden': orden,
      'activo': true,
    });
  }

  static Future<void> renombrarCategoria({
    required int id,
    required String nombre,
  }) async {
    final limpio = nombre.trim();

    if (limpio.isEmpty) {
      throw Exception('El nombre no puede quedar vacío.');
    }

    await SupabaseCliente.cliente
        .from('contabilidad_categorias_gasto')
        .update({
          'nombre': limpio,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> quitarCategoria(int id) async {
    await SupabaseCliente.cliente
        .from('contabilidad_categorias_gasto')
        .update({
          'activo': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static String _fecha(DateTime fecha) {
    final yyyy = fecha.year.toString().padLeft(4, '0');

    final mm = fecha.month.toString().padLeft(2, '0');

    final dd = fecha.day.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd';
  }
}
