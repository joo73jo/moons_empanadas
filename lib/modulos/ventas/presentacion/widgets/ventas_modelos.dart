enum SeccionVenta {
  individuales,
  combos,
  uber,
}

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
    );
  }

  String get nivelStock {
    if (!controlaStock) return 'sin_control';
    if (stockActual <= stockCritico) return 'critico';
    if (stockActual <= stockMinimo) return 'minimo';
    return 'normal';
  }
}

class ItemPedido {
  ProductoVenta producto;
  int cantidad;
  List<String> sabores;

  ItemPedido({
    required this.producto,
    required this.cantidad,
    List<String>? sabores,
  }) : sabores = sabores ?? [];

  double get subtotal => producto.precio * cantidad;

  bool mismaConfiguracion(ProductoVenta otroProducto, List<String> otrosSabores) {
    if (producto.id != otroProducto.id) return false;
    if (sabores.length != otrosSabores.length) return false;

    for (int i = 0; i < sabores.length; i++) {
      if (sabores[i] != otrosSabores[i]) return false;
    }

    return true;
  }
}

class PedidoPreparacion {
  final int id;
  final DateTime fecha;
  final String vendedorNombre;
  final String estadoPreparacion;
  final List<DetallePedidoPreparacion> detalles;

  const PedidoPreparacion({
    required this.id,
    required this.fecha,
    required this.vendedorNombre,
    required this.estadoPreparacion,
    required this.detalles,
  });
}

class DetallePedidoPreparacion {
  final String nombreProducto;
  final String categoriaProducto;
  final int cantidad;
  final List<String> sabores;

  const DetallePedidoPreparacion({
    required this.nombreProducto,
    required this.categoriaProducto,
    required this.cantidad,
    required this.sabores,
  });
}