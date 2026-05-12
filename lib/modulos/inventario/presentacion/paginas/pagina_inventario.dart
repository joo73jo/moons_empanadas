import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../autenticacion/dominio/modelos/usuario.dart';
import '../widgets/dialogo_item_inventario.dart';
import '../widgets/dialogo_movimiento_inventario.dart';
import '../widgets/inventario_supabase.dart';

class PaginaInventario extends StatefulWidget {
  final Usuario usuario;

  const PaginaInventario({
    super.key,
    required this.usuario,
  });

  @override
  State<PaginaInventario> createState() => _PaginaInventarioState();
}

class _PaginaInventarioState extends State<PaginaInventario> {
  List<ItemInventario> _items = [];
  bool _cargando = true;
  String _busqueda = '';

  bool get _esDueno => widget.usuario.rol == 'dueno';

  @override
  void initState() {
    super.initState();
    _cargarItems();
  }

  Future<void> _cargarItems() async {
    setState(() {
      _cargando = true;
    });

    try {
      final items = await InventarioSupabase.obtenerItems();

      if (!mounted) return;

      setState(() {
        _items = items;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
      _mostrarMensaje('Error cargando inventario: $e');
    }
  }

  List<ItemInventario> get _itemsFiltrados {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items.where((item) {
      return item.nombre.toLowerCase().contains(q) ||
          item.categoria.toLowerCase().contains(q) ||
          item.unidadMedida.toLowerCase().contains(q);
    }).toList();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColoresApp.principal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _colorNivel(ItemInventario item) {
    switch (item.nivelStock) {
      case 'critico':
        return Colors.redAccent;
      case 'minimo':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF00A896);
    }
  }

  String _textoNivel(ItemInventario item) {
    switch (item.nivelStock) {
      case 'critico':
        return 'Crítico';
      case 'minimo':
        return 'Mínimo';
      default:
        return 'Normal';
    }
  }

  String _formatearFechaHora(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final yyyy = fecha.year.toString();
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Future<void> _nuevoItem() async {
    final resultado = await showDialog<ItemInventario>(
      context: context,
      builder: (_) => const DialogoItemInventario(),
    );

    if (resultado == null) return;

    try {
      await InventarioSupabase.crearItem(resultado);
      if (!mounted) return;
      _mostrarMensaje('Ingrediente creado.');
      await _cargarItems();
    } catch (e) {
      _mostrarMensaje('Error creando ingrediente: $e');
    }
  }

  Future<void> _editarItem(ItemInventario item) async {
    final resultado = await showDialog<ItemInventario>(
      context: context,
      builder: (_) => DialogoItemInventario(item: item),
    );

    if (resultado == null) return;

    try {
      await InventarioSupabase.actualizarItem(resultado.copyWith(id: item.id));
      if (!mounted) return;
      _mostrarMensaje('Ingrediente actualizado.');
      await _cargarItems();
    } catch (e) {
      _mostrarMensaje('Error actualizando ingrediente: $e');
    }
  }

  Future<void> _desactivarItem(ItemInventario item) async {
    try {
      await InventarioSupabase.desactivarItem(item.id);
      if (!mounted) return;
      _mostrarMensaje('Ingrediente desactivado.');
      await _cargarItems();
    } catch (e) {
      _mostrarMensaje('Error desactivando ingrediente: $e');
    }
  }

  Future<void> _registrarMovimiento(ItemInventario item) async {
    final resultado = await showDialog<ResultadoMovimientoInventario>(
      context: context,
      builder: (_) => DialogoMovimientoInventario(item: item),
    );

    if (resultado == null) return;

    try {
      await InventarioSupabase.registrarMovimiento(
        itemId: item.id,
        usuarioLogin: widget.usuario.usuario,
        tipo: resultado.tipo,
        valor: resultado.valor,
        motivo: resultado.motivo,
      );

      if (!mounted) return;
      _mostrarMensaje('Movimiento registrado.');
      await _cargarItems();
    } catch (e) {
      _mostrarMensaje('Error registrando movimiento: $e');
    }
  }

  Future<void> _verMovimientos(ItemInventario item) async {
    try {
      final movimientos =
          await InventarioSupabase.obtenerMovimientosPorItem(item.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 760,
            constraints: const BoxConstraints(maxHeight: 760),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColoresApp.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Movimientos • ${item.nombre}',
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: movimientos.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay movimientos registrados.',
                            style: TextStyle(
                              color: ColoresApp.textoSecundario,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: movimientos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final mov = movimientos[index];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ColoresApp.fondoSecundario,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mov.tipoMovimiento.toUpperCase(),
                                          style: const TextStyle(
                                            color: ColoresApp.textoPrincipal,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatearFechaHora(mov.createdAt),
                                        style: const TextStyle(
                                          color: ColoresApp.textoSecundario,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    mov.motivo,
                                    style: const TextStyle(
                                      color: ColoresApp.textoSecundario,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _datoMovimiento(
                                          'Cantidad',
                                          '${mov.cantidad.toStringAsFixed(3)} ${mov.unidadMedida}',
                                        ),
                                      ),
                                      Expanded(
                                        child: _datoMovimiento(
                                          'Antes',
                                          mov.stockAnterior.toStringAsFixed(3),
                                        ),
                                      ),
                                      Expanded(
                                        child: _datoMovimiento(
                                          'Nuevo',
                                          mov.stockNuevo.toStringAsFixed(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _mostrarMensaje('Error cargando movimientos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFiltrados;
    final totalCriticos = _items.where((e) => e.nivelStock == 'critico').length;
    final totalMinimos = _items.where((e) => e.nivelStock == 'minimo').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          if (_esDueno)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _nuevoItem,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: ColoresApp.principal,
                ),
                label: const Text(
                  'Nuevo ingrediente',
                  style: TextStyle(
                    color: ColoresApp.textoPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                widget.usuario.nombre,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: ColoresApp.fondoPrincipal,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _tarjetaResumen(
                    'Críticos',
                    '$totalCriticos',
                    Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _tarjetaResumen(
                    'Mínimos',
                    '$totalMinimos',
                    const Color(0xFFFFA726),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _tarjetaResumen(
                    'Ingredientes',
                    '${_items.length}',
                    ColoresApp.principal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColoresApp.superficie,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingredientes',
                      style: TextStyle(
                        color: ColoresApp.textoPrincipal,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stock real, mínimos, críticos y movimientos',
                      style: TextStyle(
                        color: ColoresApp.textoSecundario,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                        });
                      },
                      style: const TextStyle(color: ColoresApp.textoPrincipal),
                      decoration: InputDecoration(
                        hintText: 'Buscar ingrediente...',
                        hintStyle: const TextStyle(
                          color: ColoresApp.textoSecundario,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: ColoresApp.principal,
                        ),
                        filled: true,
                        fillColor: ColoresApp.fondoSecundario,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _cargando
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: ColoresApp.principal,
                              ),
                            )
                          : items.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay ingredientes registrados.',
                                    style: TextStyle(
                                      color: ColoresApp.textoSecundario,
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = items[index];

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: ColoresApp.fondoSecundario,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  ColoresApp.principalClaro,
                                                  ColoresApp.principal,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.inventory_2_rounded,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.nombre,
                                                        style: const TextStyle(
                                                          color: ColoresApp
                                                              .textoPrincipal,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _colorNivel(item)
                                                            .withOpacity(0.14),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        _textoNivel(item)
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          color:
                                                              _colorNivel(item),
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${item.categoria} • ${item.unidadMedida}',
                                                  style: const TextStyle(
                                                    color: ColoresApp
                                                        .textoSecundario,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 18,
                                                  runSpacing: 8,
                                                  children: [
                                                    _datoItem(
                                                      'Stock',
                                                      '${item.stockActual.toStringAsFixed(3)} ${item.unidadMedida}',
                                                    ),
                                                    _datoItem(
                                                      'Mínimo',
                                                      item.stockMinimo
                                                          .toStringAsFixed(3),
                                                    ),
                                                    _datoItem(
                                                      'Crítico',
                                                      item.stockCritico
                                                          .toStringAsFixed(3),
                                                    ),
                                                    _datoItem(
                                                      'Costo',
                                                      '\$${item.costoUnitario.toStringAsFixed(4)}',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            children: [
                                              SizedBox(
                                                width: 150,
                                                height: 42,
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _registrarMovimiento(item),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        ColoresApp.principal,
                                                    foregroundColor:
                                                        Colors.black,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Movimiento',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: 150,
                                                height: 42,
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      _verMovimientos(item),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor: ColoresApp
                                                        .textoPrincipal,
                                                    side: BorderSide(
                                                      color: Colors.white
                                                          .withOpacity(0.12),
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Ver historial',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (_esDueno) ...[
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  width: 150,
                                                  height: 42,
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        _editarItem(item),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor: ColoresApp
                                                          .textoPrincipal,
                                                      side: BorderSide(
                                                        color: Colors.white
                                                            .withOpacity(0.12),
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Editar',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  width: 150,
                                                  height: 42,
                                                  child: OutlinedButton(
                                                    onPressed: () =>
                                                        _desactivarItem(item),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.redAccent,
                                                      side: BorderSide(
                                                        color: Colors.redAccent
                                                            .withOpacity(0.45),
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Desactivar',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoItem(String titulo, String valor) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$titulo: ',
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: valor,
            style: const TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoMovimiento(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: ColoresApp.textoSecundario,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: ColoresApp.textoPrincipal,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}