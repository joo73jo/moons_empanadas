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

  bool _esCelular(BuildContext context) {
    return MediaQuery.of(context).size.width < 760;
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
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: ColoresApp.superficie,
      title: const Text(
        'Desactivar ingrediente',
        style: TextStyle(
          color: ColoresApp.textoPrincipal,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(
        '¿Seguro que deseas desactivar "${item.nombre}"?\n\nYa no aparecerá como ingrediente activo en el inventario.',
        style: const TextStyle(
          color: ColoresApp.textoSecundario,
          height: 1.35,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Sí, desactivar',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
              maxWidth: MediaQuery.of(context).size.width * 0.94,
            ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColoresApp.textoPrincipal,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
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
                                            fontWeight: FontWeight.w900,
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
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final compacto =
                                          constraints.maxWidth < 430;

                                      if (compacto) {
                                        return Column(
                                          children: [
                                            _datoMovimiento(
                                              'Cantidad',
                                              '${mov.cantidad.toStringAsFixed(3)} ${mov.unidadMedida}',
                                            ),
                                            const SizedBox(height: 8),
                                            _datoMovimiento(
                                              'Antes',
                                              mov.stockAnterior
                                                  .toStringAsFixed(3),
                                            ),
                                            const SizedBox(height: 8),
                                            _datoMovimiento(
                                              'Nuevo',
                                              mov.stockNuevo
                                                  .toStringAsFixed(3),
                                            ),
                                          ],
                                        );
                                      }

                                      return Row(
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
                                              mov.stockAnterior
                                                  .toStringAsFixed(3),
                                            ),
                                          ),
                                          Expanded(
                                            child: _datoMovimiento(
                                              'Nuevo',
                                              mov.stockNuevo
                                                  .toStringAsFixed(3),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
    final esCelular = _esCelular(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          if (_esDueno)
            esCelular
                ? IconButton(
                    onPressed: _nuevoItem,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: ColoresApp.principal,
                    ),
                  )
                : Padding(
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
            padding: EdgeInsets.only(right: esCelular ? 10 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: esCelular ? 110 : 220),
                child: Text(
                  widget.usuario.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresApp.textoSecundario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: ColoresApp.fondoPrincipal,
        child: RefreshIndicator(
          color: ColoresApp.principal,
          backgroundColor: ColoresApp.superficie,
          onRefresh: _cargarItems,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(esCelular ? 14 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  children: [
                    _resumenSuperior(
                      totalCriticos: totalCriticos,
                      totalMinimos: totalMinimos,
                      totalIngredientes: _items.length,
                    ),
                    const SizedBox(height: 18),
                    _panelIngredientes(
                      items: items,
                      esCelular: esCelular,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumenSuperior({
    required int totalCriticos,
    required int totalMinimos,
    required int totalIngredientes,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho < 430 ? 2 : 3;
        final alto = ancho < 430 ? 118.0 : 112.0;

        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: (ancho / columnas) / alto,
          children: [
            _tarjetaResumen(
              'Críticos',
              '$totalCriticos',
              Colors.redAccent,
            ),
            _tarjetaResumen(
              'Mínimos',
              '$totalMinimos',
              const Color(0xFFFFA726),
            ),
            _tarjetaResumen(
              'Ingredientes',
              '$totalIngredientes',
              ColoresApp.principal,
            ),
          ],
        );
      },
    );
  }

  Widget _panelIngredientes({
    required List<ItemInventario> items,
    required bool esCelular,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esCelular ? 18 : 20),
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
          Text(
            'Ingredientes',
            style: TextStyle(
              color: ColoresApp.textoPrincipal,
              fontSize: esCelular ? 24 : 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stock real, mínimos, críticos y movimientos',
            style: TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 14,
              height: 1.3,
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
          if (_cargando)
            const SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(
                  color: ColoresApp.principal,
                ),
              ),
            )
          else if (items.isEmpty)
            Container(
              width: double.infinity,
              height: 180,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ColoresApp.fondoSecundario,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No hay ingredientes registrados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 15,
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _tarjetaItem(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _tarjetaItem(ItemInventario item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSecundario,
            borderRadius: BorderRadius.circular(18),
          ),
          child: compacto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezadoItem(item),
                    const SizedBox(height: 12),
                    _datosItem(item),
                    const SizedBox(height: 14),
                    _accionesItem(item, compacto: true),
                  ],
                )
              : Row(
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _encabezadoItem(item, conIcono: false),
                          const SizedBox(height: 8),
                          _datosItem(item),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _accionesItem(item, compacto: false),
                  ],
                ),
        );
      },
    );
  }

  Widget _encabezadoItem(
    ItemInventario item, {
    bool conIcono = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (conIcono) ...[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ColoresApp.principalClaro,
                  ColoresApp.principal,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.categoria} • ${item.unidadMedida}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _colorNivel(item).withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _textoNivel(item).toUpperCase(),
            style: TextStyle(
              color: _colorNivel(item),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datosItem(ItemInventario item) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chipDatoItem(
          'Stock',
          '${item.stockActual.toStringAsFixed(3)} ${item.unidadMedida}',
        ),
        _chipDatoItem(
          'Mínimo',
          item.stockMinimo.toStringAsFixed(3),
        ),
        _chipDatoItem(
          'Crítico',
          item.stockCritico.toStringAsFixed(3),
        ),
        _chipDatoItem(
          'Costo',
          '\$${item.costoUnitario.toStringAsFixed(4)}',
        ),
      ],
    );
  }

  Widget _chipDatoItem(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: valor,
              style: const TextStyle(
                color: ColoresApp.textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionesItem(
    ItemInventario item, {
    required bool compacto,
  }) {
    if (compacto) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _botonMovimiento(item),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _botonHistorial(item),
          ),
          if (_esDueno) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: _botonEditar(item),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: _botonDesactivar(item),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 42,
          child: _botonMovimiento(item),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          height: 42,
          child: _botonHistorial(item),
        ),
        if (_esDueno) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            height: 42,
            child: _botonEditar(item),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            height: 42,
            child: _botonDesactivar(item),
          ),
        ],
      ],
    );
  }

  Widget _botonMovimiento(ItemInventario item) {
    return ElevatedButton(
      onPressed: () => _registrarMovimiento(item),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Movimiento',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _botonHistorial(ItemInventario item) {
    return OutlinedButton(
      onPressed: () => _verMovimientos(item),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Ver historial',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _botonEditar(ItemInventario item) {
    return OutlinedButton(
      onPressed: () => _editarItem(item),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Editar',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _botonDesactivar(ItemInventario item) {
    return OutlinedButton(
      onPressed: () => _desactivarItem(item),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: BorderSide(
          color: Colors.redAccent.withOpacity(0.45),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Desactivar',
        style: TextStyle(fontWeight: FontWeight.w700),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontSize: 13,
              height: 1.15,
            ),
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoMovimiento(String titulo, String valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
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
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}