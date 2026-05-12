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

  const ProductoVenta({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.seccion,
    required this.requiereSabores,
    required this.cantidadSabores,
    required this.controlaStock,
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
    );
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