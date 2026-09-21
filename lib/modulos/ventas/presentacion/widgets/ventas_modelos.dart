enum SeccionVenta { individuales, combos, uber }

enum TipoPedido { local, paraLlevar, domicilio }

enum EstadoCobroVenta { pagado, pendientePago, cobradoRepartidor, entregado }

class ProductoVenta {
  final int id;
  final String nombre;
  final String categoria;
  final double precio;
  final SeccionVenta seccion;
  final bool requiereSabores;
  final int cantidadSabores;
  final bool controlaStock;
  final double stockActual;
  final double stockMinimo;
  final double stockCritico;

  /// Componentes configurados cuando este producto es un combo.
  final List<ComponenteCombo> componentesCombo;

  const ProductoVenta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.seccion,
    required this.requiereSabores,
    required this.cantidadSabores,
    required this.controlaStock,
    this.stockActual = 0,
    this.stockMinimo = 0,
    this.stockCritico = 0,
    this.componentesCombo = const [],
  });

  ProductoVenta copyWith({
    int? id,
    String? nombre,
    String? categoria,
    double? precio,
    SeccionVenta? seccion,
    bool? requiereSabores,
    int? cantidadSabores,
    bool? controlaStock,
    double? stockActual,
    double? stockMinimo,
    double? stockCritico,
    List<ComponenteCombo>? componentesCombo,
  }) {
    return ProductoVenta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      seccion: seccion ?? this.seccion,
      requiereSabores: requiereSabores ?? this.requiereSabores,
      cantidadSabores: cantidadSabores ?? this.cantidadSabores,
      controlaStock: controlaStock ?? this.controlaStock,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockCritico: stockCritico ?? this.stockCritico,
      componentesCombo: componentesCombo ?? this.componentesCombo,
    );
  }

  String get nivelStock {
    if (!controlaStock) return 'sin_control';
    if (stockActual <= stockCritico) return 'critico';
    if (stockActual <= stockMinimo) return 'minimo';
    return 'normal';
  }

  bool get esCombo {
    return seccion == SeccionVenta.combos;
  }

  bool get tieneComponentesCombo {
    return componentesCombo.isNotEmpty;
  }
}

class ComponenteCombo {
  final int id;
  final int comboId;
  final String nombreComponente;
  final ProductoVenta productoPredeterminado;
  final int cantidad;
  final bool permiteSustitucion;
  final bool obligatorio;
  final int orden;
  final bool activo;
  final List<OpcionComponenteCombo> opciones;

  const ComponenteCombo({
    required this.id,
    required this.comboId,
    required this.nombreComponente,
    required this.productoPredeterminado,
    required this.cantidad,
    required this.permiteSustitucion,
    required this.obligatorio,
    required this.orden,
    required this.activo,
    this.opciones = const [],
  });

  ComponenteCombo copyWith({
    int? id,
    int? comboId,
    String? nombreComponente,
    ProductoVenta? productoPredeterminado,
    int? cantidad,
    bool? permiteSustitucion,
    bool? obligatorio,
    int? orden,
    bool? activo,
    List<OpcionComponenteCombo>? opciones,
  }) {
    return ComponenteCombo(
      id: id ?? this.id,
      comboId: comboId ?? this.comboId,
      nombreComponente: nombreComponente ?? this.nombreComponente,
      productoPredeterminado:
          productoPredeterminado ?? this.productoPredeterminado,
      cantidad: cantidad ?? this.cantidad,
      permiteSustitucion: permiteSustitucion ?? this.permiteSustitucion,
      obligatorio: obligatorio ?? this.obligatorio,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
      opciones: opciones ?? this.opciones,
    );
  }

  List<OpcionComponenteCombo> get opcionesActivasOrdenadas {
    final lista = opciones.where((opcion) => opcion.activo).toList();

    lista.sort((a, b) {
      final comparacionOrden = a.orden.compareTo(b.orden);

      if (comparacionOrden != 0) {
        return comparacionOrden;
      }

      return a.producto.nombre.toLowerCase().compareTo(
        b.producto.nombre.toLowerCase(),
      );
    });

    return lista;
  }

  OpcionComponenteCombo get opcionPredeterminada {
    return OpcionComponenteCombo(
      id: 0,
      componenteId: id,
      producto: productoPredeterminado,
      recargo: 0,
      activo: true,
      orden: -1,
      esPredeterminada: true,
    );
  }

  List<OpcionComponenteCombo> get todasLasOpciones {
    final resultado = <OpcionComponenteCombo>[opcionPredeterminada];

    if (permiteSustitucion) {
      for (final opcion in opcionesActivasOrdenadas) {
        final yaExiste = resultado.any(
          (item) => item.producto.id == opcion.producto.id,
        );

        if (!yaExiste) {
          resultado.add(opcion);
        }
      }
    }

    return resultado;
  }
}

class OpcionComponenteCombo {
  final int id;
  final int componenteId;
  final ProductoVenta producto;
  final double recargo;
  final bool activo;
  final int orden;
  final bool esPredeterminada;

  const OpcionComponenteCombo({
    required this.id,
    required this.componenteId,
    required this.producto,
    required this.recargo,
    required this.activo,
    required this.orden,
    this.esPredeterminada = false,
  });

  OpcionComponenteCombo copyWith({
    int? id,
    int? componenteId,
    ProductoVenta? producto,
    double? recargo,
    bool? activo,
    int? orden,
    bool? esPredeterminada,
  }) {
    return OpcionComponenteCombo(
      id: id ?? this.id,
      componenteId: componenteId ?? this.componenteId,
      producto: producto ?? this.producto,
      recargo: recargo ?? this.recargo,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
      esPredeterminada: esPredeterminada ?? this.esPredeterminada,
    );
  }
}

class EleccionComponenteCombo {
  final int? componenteId;
  final String nombreComponente;
  final int? productoPredeterminadoId;
  final ProductoVenta productoElegido;
  final int cantidad;
  final double recargoUnitario;
  final bool fueSustituido;

  const EleccionComponenteCombo({
    required this.componenteId,
    required this.nombreComponente,
    required this.productoPredeterminadoId,
    required this.productoElegido,
    required this.cantidad,
    required this.recargoUnitario,
    required this.fueSustituido,
  });

  double get recargoTotal {
    return recargoUnitario * cantidad;
  }

  EleccionComponenteCombo copyWith({
    int? componenteId,
    bool limpiarComponenteId = false,
    String? nombreComponente,
    int? productoPredeterminadoId,
    bool limpiarProductoPredeterminadoId = false,
    ProductoVenta? productoElegido,
    int? cantidad,
    double? recargoUnitario,
    bool? fueSustituido,
  }) {
    return EleccionComponenteCombo(
      componenteId: limpiarComponenteId
          ? null
          : componenteId ?? this.componenteId,
      nombreComponente: nombreComponente ?? this.nombreComponente,
      productoPredeterminadoId: limpiarProductoPredeterminadoId
          ? null
          : productoPredeterminadoId ?? this.productoPredeterminadoId,
      productoElegido: productoElegido ?? this.productoElegido,
      cantidad: cantidad ?? this.cantidad,
      recargoUnitario: recargoUnitario ?? this.recargoUnitario,
      fueSustituido: fueSustituido ?? this.fueSustituido,
    );
  }

  String get descripcion {
    if (cantidad <= 1) {
      return productoElegido.nombre;
    }

    return '$cantidad x ${productoElegido.nombre}';
  }
}

class ResultadoSeleccionCombo {
  final List<EleccionComponenteCombo> elecciones;

  const ResultadoSeleccionCombo({required this.elecciones});

  double get recargoUnitarioTotal {
    return elecciones.fold(
      0,
      (total, eleccion) => total + eleccion.recargoTotal,
    );
  }

  List<String> get descripciones {
    return elecciones.map((eleccion) => eleccion.descripcion).toList();
  }

  bool get tieneSustituciones {
    return elecciones.any((eleccion) => eleccion.fueSustituido);
  }
}

class ItemPedido {
  ProductoVenta producto;
  int cantidad;

  /// Se mantiene para compatibilidad con ventas anteriores.
  List<String> sabores;

  /// Selección real de componentes del combo.
  List<EleccionComponenteCombo> eleccionesCombo;

  ItemPedido({
    required this.producto,
    required this.cantidad,
    List<String>? sabores,
    List<EleccionComponenteCombo>? eleccionesCombo,
  }) : sabores = sabores ?? [],
       eleccionesCombo = eleccionesCombo ?? [];

  double get recargoComboUnitario {
    return eleccionesCombo.fold(
      0,
      (total, eleccion) => total + eleccion.recargoTotal,
    );
  }

  double get precioUnitarioFinal {
    return producto.precio + recargoComboUnitario;
  }

  double get subtotalBase {
    return producto.precio * cantidad;
  }

  double get totalRecargoCombo {
    return recargoComboUnitario * cantidad;
  }

  double get subtotal {
    return precioUnitarioFinal * cantidad;
  }

  bool get esComboConfigurado {
    return producto.esCombo && eleccionesCombo.isNotEmpty;
  }

  List<String> get descripcionesCombo {
    if (eleccionesCombo.isNotEmpty) {
      return eleccionesCombo.map((eleccion) => eleccion.descripcion).toList();
    }

    return sabores;
  }

  bool mismaConfiguracion(
    ProductoVenta otroProducto,
    List<String> otrosSabores, {
    List<EleccionComponenteCombo> otrasEleccionesCombo = const [],
  }) {
    if (producto.id != otroProducto.id) {
      return false;
    }

    if (eleccionesCombo.isNotEmpty || otrasEleccionesCombo.isNotEmpty) {
      return _mismasEleccionesCombo(eleccionesCombo, otrasEleccionesCombo);
    }

    if (sabores.length != otrosSabores.length) {
      return false;
    }

    for (int i = 0; i < sabores.length; i++) {
      if (sabores[i] != otrosSabores[i]) {
        return false;
      }
    }

    return true;
  }

  bool _mismasEleccionesCombo(
    List<EleccionComponenteCombo> actuales,
    List<EleccionComponenteCombo> otras,
  ) {
    if (actuales.length != otras.length) {
      return false;
    }

    for (int i = 0; i < actuales.length; i++) {
      final actual = actuales[i];
      final otra = otras[i];

      if (actual.componenteId != otra.componenteId) {
        return false;
      }

      if (actual.productoElegido.id != otra.productoElegido.id) {
        return false;
      }

      if (actual.cantidad != otra.cantidad) {
        return false;
      }

      if ((actual.recargoUnitario - otra.recargoUnitario).abs() > 0.001) {
        return false;
      }
    }

    return true;
  }
}

class PlataformaConfiguracion {
  final int id;
  final String nombre;
  final double porcentaje;
  final bool activo;
  final int orden;

  const PlataformaConfiguracion({
    required this.id,
    required this.nombre,
    required this.porcentaje,
    required this.activo,
    required this.orden,
  });
}

class RecargoConfiguracion {
  final int id;
  final String nombre;
  final double porcentaje;
  final bool activo;
  final int orden;

  const RecargoConfiguracion({
    required this.id,
    required this.nombre,
    required this.porcentaje,
    required this.activo,
    required this.orden,
  });

  double calcularValor(double subtotal) {
    return subtotal * porcentaje / 100;
  }

  RecargoConfiguracion copyWith({
    int? id,
    String? nombre,
    double? porcentaje,
    bool? activo,
    int? orden,
  }) {
    return RecargoConfiguracion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      porcentaje: porcentaje ?? this.porcentaje,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
    );
  }
}

class RecargoAplicado {
  final int? configuracionId;
  final String nombre;
  final double porcentaje;
  final double valor;

  const RecargoAplicado({
    required this.configuracionId,
    required this.nombre,
    required this.porcentaje,
    required this.valor,
  });
}

class DatosPedidoVenta {
  final String nombrePedido;
  final TipoPedido tipoPedido;
  final String barrio;
  final EstadoCobroVenta estadoCobro;
  final String responsableDinero;
  final bool enviarPreparacion;
  final List<RecargoAplicado> recargos;

  final double valorDomicilio;
  final bool usaIndrive;

  final String plataforma;
  final double porcentajePlataforma;
  final double descuentoPlataforma;

  final bool esProgramado;
  final DateTime? fechaProgramada;

  const DatosPedidoVenta({
    required this.nombrePedido,
    required this.tipoPedido,
    required this.barrio,
    required this.estadoCobro,
    required this.responsableDinero,
    required this.enviarPreparacion,
    required this.recargos,
    this.valorDomicilio = 0,
    this.usaIndrive = false,
    this.plataforma = '',
    this.porcentajePlataforma = 0,
    this.descuentoPlataforma = 0,
    this.esProgramado = false,
    this.fechaProgramada,
  });

  bool get requiereCobroInmediato {
    return !esProgramado && estadoCobro == EstadoCobroVenta.pagado;
  }

  bool get esDomicilio {
    return tipoPedido == TipoPedido.domicilio;
  }

  bool get esPlataforma {
    return plataforma.trim().isNotEmpty;
  }

  double totalRecargos() {
    return recargos.fold(0, (total, recargo) => total + recargo.valor);
  }

  double get totalExtras {
    return totalRecargos() + (esDomicilio ? valorDomicilio : 0);
  }
}

class PedidoPreparacion {
  final int id;
  final DateTime fecha;
  final String nombrePedido;
  final String vendedorNombre;
  final String estadoPreparacion;
  final TipoPedido tipoPedido;
  final String barrio;
  final EstadoCobroVenta estadoCobro;
  final String responsableDinero;
  final bool enviadoPreparacion;
  final double subtotal;
  final double totalRecargos;
  final double total;
  final List<DetallePedidoPreparacion> detalles;

  const PedidoPreparacion({
    required this.id,
    required this.fecha,
    required this.nombrePedido,
    required this.vendedorNombre,
    required this.estadoPreparacion,
    required this.tipoPedido,
    required this.barrio,
    required this.estadoCobro,
    required this.responsableDinero,
    required this.enviadoPreparacion,
    required this.subtotal,
    required this.totalRecargos,
    required this.total,
    required this.detalles,
  });

  bool get estaPagado {
    return estadoCobro == EstadoCobroVenta.pagado ||
        estadoCobro == EstadoCobroVenta.entregado;
  }

  bool get pendienteDeCobro {
    return estadoCobro == EstadoCobroVenta.pendientePago;
  }

  bool get dineroConRepartidor {
    return estadoCobro == EstadoCobroVenta.cobradoRepartidor;
  }

  bool get puedeEnviarPreparacion {
    return !enviadoPreparacion;
  }

  bool get puedeMarcarDineroEntregado {
    return dineroConRepartidor;
  }
}

class DetallePedidoPreparacion {
  final String nombreProducto;
  final String categoriaProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  /// Se conserva para mostrar ventas antiguas.
  final List<String> sabores;

  /// Componentes reales elegidos en combos nuevos.
  final List<DetalleEleccionComboPreparacion> eleccionesCombo;

  const DetallePedidoPreparacion({
    required this.nombreProducto,
    required this.categoriaProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.sabores,
    this.eleccionesCombo = const [],
  });

  List<String> get descripcionesConfiguracion {
    if (eleccionesCombo.isNotEmpty) {
      return eleccionesCombo.map((eleccion) => eleccion.descripcion).toList();
    }

    return sabores;
  }
}

class DetalleEleccionComboPreparacion {
  final String nombreComponente;
  final String nombreProductoElegido;
  final int cantidad;
  final double recargoUnitario;
  final double recargoTotal;
  final bool fueSustituido;

  const DetalleEleccionComboPreparacion({
    required this.nombreComponente,
    required this.nombreProductoElegido,
    required this.cantidad,
    required this.recargoUnitario,
    required this.recargoTotal,
    required this.fueSustituido,
  });

  String get descripcion {
    final cantidadTexto = cantidad > 1 ? '$cantidad x ' : '';

    final recargoTexto = recargoTotal > 0
        ? ' (+\$${recargoTotal.toStringAsFixed(2)})'
        : '';

    return '$nombreComponente: '
        '$cantidadTexto'
        '$nombreProductoElegido'
        '$recargoTexto';
  }
}

String tipoPedidoBaseDatos(TipoPedido tipo) {
  switch (tipo) {
    case TipoPedido.local:
      return 'local';

    case TipoPedido.paraLlevar:
      return 'para_llevar';

    case TipoPedido.domicilio:
      return 'domicilio';
  }
}

TipoPedido tipoPedidoDesdeBaseDatos(dynamic valor) {
  switch (valor?.toString()) {
    case 'para_llevar':
      return TipoPedido.paraLlevar;

    case 'domicilio':
      return TipoPedido.domicilio;

    case 'local':
    default:
      return TipoPedido.local;
  }
}

String nombreTipoPedido(TipoPedido tipo) {
  switch (tipo) {
    case TipoPedido.local:
      return 'Local';

    case TipoPedido.paraLlevar:
      return 'Para llevar';

    case TipoPedido.domicilio:
      return 'Domicilio';
  }
}

String estadoCobroBaseDatos(EstadoCobroVenta estado) {
  switch (estado) {
    case EstadoCobroVenta.pagado:
      return 'pagado';

    case EstadoCobroVenta.pendientePago:
      return 'pendiente_pago';

    case EstadoCobroVenta.cobradoRepartidor:
      return 'cobrado_repartidor';

    case EstadoCobroVenta.entregado:
      return 'entregado';
  }
}

EstadoCobroVenta estadoCobroDesdeBaseDatos(dynamic valor) {
  switch (valor?.toString()) {
    case 'pendiente_pago':
      return EstadoCobroVenta.pendientePago;

    case 'cobrado_repartidor':
      return EstadoCobroVenta.cobradoRepartidor;

    case 'entregado':
      return EstadoCobroVenta.entregado;

    case 'pagado':
    default:
      return EstadoCobroVenta.pagado;
  }
}

String nombreEstadoCobro(EstadoCobroVenta estado) {
  switch (estado) {
    case EstadoCobroVenta.pagado:
      return 'Pagado';

    case EstadoCobroVenta.pendientePago:
      return 'Pendiente de pago';

    case EstadoCobroVenta.cobradoRepartidor:
      return 'Cobrado por repartidor';

    case EstadoCobroVenta.entregado:
      return 'Dinero entregado';
  }
}
