import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores_app.dart';
import '../widgets/contabilidad_supabase.dart';

class PaginaContabilidad extends StatefulWidget {
  const PaginaContabilidad({super.key});

  @override
  State<PaginaContabilidad> createState() => _PaginaContabilidadState();
}

class _PaginaContabilidadState extends State<PaginaContabilidad> {
  late DateTime _mes;

  List<ResumenContabilidadSemana> _semanas = [];

  static const Color _verde = Color(0xFFA9D18E);

  static const Color _amarillo = Color(0xFFFFD966);

  static const Color _naranja = Color(0xFFF4B183);

  static const Color _blanco = Color(0xFFF2F2F2);

  static const Color _borde = Color(0xFF444444);

  late DateTime _semana;

  ResumenContabilidadSemana? _resumen;

  bool _cargando = true;

  @override
  void initState() {
    super.initState();

    final ahora = DateTime.now();

    _mes = DateTime(ahora.year, ahora.month, 1);

    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
    });

    try {
      final semanas = await ContabilidadSupabase.obtenerMes(_mes);

      if (!mounted) return;

      setState(() {
        _semanas = semanas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      _mensaje('Error cargando contabilidad: $e');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: ColoresApp.principal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _mesAnterior() async {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month - 1, 1);
    });

    await _cargar();
  }

  Future<void> _mesSiguiente() async {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + 1, 1);
    });

    await _cargar();
  }

  Future<void> _seleccionarMes() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _mes,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _mes = DateTime(fecha.year, fecha.month, 1);
    });

    await _cargar();
  }

  Future<double?> _pedirValor({
    required String titulo,
    required double valorActual,
  }) async {
    final controller = TextEditingController(
      text: valorActual == 0 ? '' : valorActual.toStringAsFixed(2),
    );

    final resultado = await showDialog<double>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: ColoresApp.superficie,
          title: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: ColoresApp.textoPrincipal),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: '\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = double.tryParse(
                  controller.text.replaceAll(',', '.').trim(),
                );

                if (valor == null || valor < 0) {
                  return;
                }

                Navigator.pop(context, valor);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    return resultado;
  }

  Future<void> _editarGasto(
    CategoriaGastoContable categoria,
    ResumenContabilidadSemana resumen,
  ) async {
    final actual = resumen.gastosPorCategoria[categoria.id] ?? 0;

    final valor = await _pedirValor(
      titulo: '${categoria.nombre} · ${_fechaCorta(resumen.semanaInicio)}',
      valorActual: actual,
    );

    if (valor == null) {
      return;
    }

    await ContabilidadSupabase.guardarGasto(
      categoriaId: categoria.id,
      semanaInicio: resumen.semanaInicio,
      valor: valor,
    );

    if (!mounted) return;

    await _cargar();
  }

  Future<void> _editarLiquidacion(
    String plataforma,
    ResumenContabilidadSemana resumen,
  ) async {
    final actual = resumen.liquidacionesPlataforma[plataforma] ?? 0;

    final valor = await _pedirValor(
      titulo: 'Semana ant. $plataforma',
      valorActual: actual,
    );

    if (valor == null) {
      return;
    }

    await ContabilidadSupabase.guardarLiquidacionPlataforma(
      plataforma: plataforma,
      semanaInicio: resumen.semanaInicio,
      valor: valor,
    );

    if (!mounted) return;

    await _cargar();
  }

  Future<void> _agregarCampoGasto() async {
    final controller = TextEditingController();

    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: const Text(
          'Agregar campo de gasto',
          style: TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: ColoresApp.textoPrincipal),
          decoration: const InputDecoration(labelText: 'Nombre del gasto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = controller.text.trim();

              if (texto.isEmpty) {
                return;
              }

              Navigator.pop(context, texto);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (nombre == null) return;

    await ContabilidadSupabase.crearCategoriaGasto(nombre);

    await _cargar();
  }

  Future<void> _opcionesCategoria(CategoriaGastoContable categoria) async {
    final accion = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColoresApp.superficie,
        title: Text(
          categoria.nombre,
          style: const TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'renombrar'),
            child: const Text('Renombrar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'quitar'),
            child: const Text(
              'Quitar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (accion == 'quitar') {
      await ContabilidadSupabase.quitarCategoria(categoria.id);

      if (!mounted) return;

      await _cargar();

      return;
    }

    if (accion != 'renombrar') {
      return;
    }

    String nombreNuevo = categoria.nombre;

    final nombre = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: ColoresApp.superficie,
          title: const Text(
            'Renombrar campo',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextFormField(
            initialValue: categoria.nombre,
            autofocus: true,
            style: const TextStyle(color: ColoresApp.textoPrincipal),
            decoration: const InputDecoration(labelText: 'Nombre del campo'),
            onChanged: (valor) {
              nombreNuevo = valor;
            },
            onFieldSubmitted: (valor) {
              final limpio = valor.trim();

              if (limpio.isEmpty) {
                return;
              }

              Navigator.pop(context, limpio);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final limpio = nombreNuevo.trim();

                if (limpio.isEmpty) {
                  return;
                }

                Navigator.pop(context, limpio);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (!mounted || nombre == null) {
      return;
    }

    await ContabilidadSupabase.renombrarCategoria(
      id: categoria.id,
      nombre: nombre,
    );

    if (!mounted) return;

    await _cargar();
  }

  String _nombreMes(DateTime fecha) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  ResumenContabilidadSemana get _semanaEdicion {
    final ahora = DateTime.now();

    for (final semana in _semanas) {
      final inicio = semana.semanaInicio;

      final fin = inicio.add(const Duration(days: 7));

      if (!ahora.isBefore(inicio) && ahora.isBefore(fin)) {
        return semana;
      }
    }

    return _semanas.first;
  }

  String _dinero(double valor) {
    return '\$ ${valor.toStringAsFixed(2)}';
  }

  String _fechaCorta(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}';
  }

  String _dia(DateTime fecha) {
    const nombres = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    return '${nombres[fecha.weekday - 1]} ${fecha.day.toString().padLeft(2, '0')}';
  }

  Widget _celda(
    String texto, {
    Color color = _blanco,
    double width = 150,
    FontWeight peso = FontWeight.w600,
    Alignment alignment = Alignment.centerRight,
  }) {
    return Container(
      width: width,
      height: 42,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black54, width: 0.8),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: peso),
      ),
    );
  }

  Widget _filaTabla(
    String titulo,
    List<String> valores, {
    Color color = _blanco,
    FontWeight peso = FontWeight.w600,
  }) {
    return Row(
      children: [
        _celda(
          titulo,
          width: 190,
          color: color,
          peso: peso,
          alignment: Alignment.centerLeft,
        ),
        ...valores.map((valor) => _celda(valor, color: color, peso: peso)),
      ],
    );
  }

  Widget _tablaDiaria(ResumenContabilidadSemana r) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _celda(
                'Fecha',
                width: 190,
                peso: FontWeight.w900,
                alignment: Alignment.centerLeft,
              ),
              ...r.dias.map(
                (dia) => _celda(
                  _dia(dia.fecha),
                  peso: FontWeight.w900,
                  alignment: Alignment.center,
                ),
              ),
            ],
          ),

          _filaTabla(
            'Ventas local',
            r.dias.map((e) => _dinero(e.ventasLocal)).toList(),
          ),

          _filaTabla(
            'Ventas plataformas',
            r.dias.map((e) => _dinero(e.ventasPlataformas)).toList(),
          ),

          _filaTabla(
            'Dscto Plataformas',
            r.dias.map((e) => _dinero(e.descuentoPlataformas)).toList(),
          ),

          _filaTabla(
            'Domicilios',
            r.dias.map((e) => _dinero(e.domicilios)).toList(),
          ),

          _filaTabla(
            'Total con dom y plat',
            r.dias.map((e) => _dinero(e.totalConDomYPlat)).toList(),
            color: _verde,
            peso: FontWeight.w900,
          ),

          _filaTabla(
            'Total sin plat ni dom',
            r.dias.map((e) => _dinero(e.totalSinPlatNiDom)).toList(),
            color: _amarillo,
            peso: FontWeight.w900,
          ),
        ],
      ),
    );
  }

  Widget _filaResumen({
    required String titulo,
    required String valor,
    Color color = _blanco,
    VoidCallback? onTap,
  }) {
    final contenido = Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.black45)),
          child: contenido,
        ),
      ),
    );
  }

  Widget _resumenSemana(ResumenContabilidadSemana r) {
    return SizedBox(
      width: 440,
      child: Column(
        children: [
          _filaResumen(
            titulo: 'Total con Plataformas',
            valor: _dinero(r.totalConDomYPlat),
          ),

          _filaResumen(
            titulo: 'Solo domicilios',
            valor: _dinero(r.domicilios),
            color: const Color(0xFFFCE4D6),
          ),

          _filaResumen(
            titulo: 'Total sin Plat ni Domis',
            valor: _dinero(r.totalSinPlatNiDom),
            color: _amarillo,
          ),

          ...r.plataformas.map((plataforma) {
            final valor = r.liquidacionesPlataforma[plataforma] ?? 0;

            return _filaResumen(
              titulo: 'Semana ant. $plataforma',
              valor: _dinero(valor),
              color: const Color(0xFFFFE699),
              onTap: () => _editarLiquidacion(plataforma, r),
            );
          }),

          _filaResumen(
            titulo: 'Total para sem',
            valor: _dinero(r.totalParaSemana),
            color: _naranja,
          ),

          _filaResumen(
            titulo: 'Gastos sem',
            valor: _dinero(r.totalGastos),
            color: _amarillo,
          ),

          _filaResumen(
            titulo: 'Líquido sem',
            valor: _dinero(r.liquidoSemana),
            color: _naranja,
          ),
        ],
      ),
    );
  }

  Widget _resumenGeneral(ResumenContabilidadSemana r) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _cajaResumen('Total Plataformas', r.ventasPlataformas),
        _cajaResumen('Total Domicilios', r.domicilios),
        _cajaResumen('Media por día', r.mediaPorDia),
        _cajaResumen('Total líquido', r.liquidoSemana, color: _amarillo),
      ],
    );
  }

  Widget _cajaResumen(String titulo, double valor, {Color color = _blanco}) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black54),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _dinero(valor),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _celdaNombreGasto(CategoriaGastoContable categoria) {
    return Container(
      width: 190,
      height: 44,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: _blanco,
        border: Border.all(color: Colors.black54, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              categoria.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Editar campo',
            onPressed: () => _opcionesCategoria(categoria),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gastosMensuales() {
    if (_semanas.isEmpty) {
      return const SizedBox.shrink();
    }

    final categorias = _semanas.first.categoriasGasto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColoresApp.principal.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: ColoresApp.principal,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos del mes',
                      style: TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Cada valor corresponde a una semana específica',
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              ElevatedButton.icon(
                onPressed: _agregarCampoGasto,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar campo'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _celda(
                      'Gasto',
                      width: 190,
                      peso: FontWeight.w900,
                      alignment: Alignment.centerLeft,
                    ),

                    ..._semanas.asMap().entries.map((entry) {
                      final numero = entry.key + 1;

                      final semana = entry.value;

                      return _celda(
                        'Semana $numero\n${_fechaCorta(semana.semanaInicio)}',
                        width: 150,
                        peso: FontWeight.w900,
                        alignment: Alignment.center,
                      );
                    }),
                  ],
                ),

                ...categorias.map((categoria) {
                  return Row(
                    children: [
                      _celdaNombreGasto(categoria),

                      ..._semanas.map((semana) {
                        final valor =
                            semana.gastosPorCategoria[categoria.id] ?? 0;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _editarGasto(categoria, semana),
                            child: Container(
                              width: 150,
                              height: 44,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _blanco,
                                border: Border.all(
                                  color: Colors.black54,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    _dinero(valor),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(width: 7),

                                  const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),

                Row(
                  children: [
                    _celda(
                      'TOTAL GASTOS',
                      width: 190,
                      color: _amarillo,
                      peso: FontWeight.w900,
                      alignment: Alignment.centerLeft,
                    ),

                    ..._semanas.map(
                      (semana) => _celda(
                        _dinero(semana.totalGastos),
                        width: 150,
                        color: _amarillo,
                        peso: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Haz clic sobre cualquier valor para editar el gasto de esa semana. Usa ⋮ para renombrar o quitar un campo.',
            style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _bloqueSemana(ResumenContabilidadSemana r, int numero) {
    final fechaFin = r.semanaInicio.add(const Duration(days: 6));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColoresApp.principal.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: ColoresApp.principal,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semana $numero',
                      style: const TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${_fechaCorta(r.semanaInicio)} — ${_fechaCorta(fechaFin)}',
                      style: const TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tablaDiaria(r),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [_resumenSemana(r), _resumenGeneral(r)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contabilidad'),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        color: ColoresApp.fondoPrincipal,
        width: double.infinity,
        height: double.infinity,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: ColoresApp.principal),
              )
            : _semanas.isEmpty
            ? const Center(
                child: Text(
                  'No se pudo cargar la contabilidad.',
                  style: TextStyle(color: ColoresApp.textoSecundario),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _mesAnterior,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),

                            InkWell(
                              onTap: _seleccionarMes,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: ColoresApp.superficie,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _nombreMes(_mes),
                                  style: const TextStyle(
                                    color: ColoresApp.textoPrincipal,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: _mesSiguiente,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Resumen Moons · ${_nombreMes(_mes)}',
                          style: const TextStyle(
                            color: ColoresApp.textoPrincipal,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 16),

                        ..._semanas.asMap().entries.map(
                          (entry) => _bloqueSemana(entry.value, entry.key + 1),
                        ),

                        /*
                             * Los campos de gasto se siguen
                             * administrando igual.
                             *
                             * Al editar un valor se usa la
                             * semana actual si pertenece al
                             * mes mostrado; en otro caso,
                             * la primera semana del mes.
                             */
                        _gastosMensuales(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
