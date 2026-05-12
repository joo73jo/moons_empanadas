import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../nucleo/constantes/supabase_cliente.dart';
import 'ventas_modelos.dart';

class ProductosSupabase {
  static Future<List<ProductoVenta>> obtenerProductos() async {
    try {
      final respuesta = await SupabaseCliente.cliente
          .from('productos')
          .select()
          .eq('activo', true)
          .order('id');

      final lista = (respuesta as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return lista.map<ProductoVenta>((mapa) {
        return ProductoVenta(
          id: (mapa['id'] as num).toInt(),
          nombre: (mapa['nombre'] ?? '').toString(),
          categoria: (mapa['categoria'] ?? '').toString(),
          precio: (mapa['precio'] as num).toDouble(),
          seccion: _mapearSeccion((mapa['seccion'] ?? '').toString()),
          requiereSabores: mapa['requiere_sabores'] as bool? ?? false,
          cantidadSabores: (mapa['cantidad_sabores'] as num?)?.toInt() ?? 0,
          controlaStock: mapa['controla_stock'] as bool? ?? true,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Supabase productos: ${e.message}');
    } catch (e) {
      throw Exception('Error productos: $e');
    }
  }

  static Future<ProductoVenta> crearProducto(ProductoVenta producto) async {
    final respuesta = await SupabaseCliente.cliente
        .from('productos')
        .insert({
          'nombre': producto.nombre,
          'categoria': producto.categoria,
          'precio': producto.precio,
          'seccion': _mapearSeccionTexto(producto.seccion),
          'requiere_sabores': producto.requiereSabores,
          'cantidad_sabores': producto.cantidadSabores,
          'controla_stock': producto.controlaStock,
          'activo': true,
        })
        .select()
        .single();

    final mapa = Map<String, dynamic>.from(respuesta);

    return ProductoVenta(
      id: (mapa['id'] as num).toInt(),
      nombre: (mapa['nombre'] ?? '').toString(),
      categoria: (mapa['categoria'] ?? '').toString(),
      precio: (mapa['precio'] as num).toDouble(),
      seccion: _mapearSeccion((mapa['seccion'] ?? '').toString()),
      requiereSabores: mapa['requiere_sabores'] as bool? ?? false,
      cantidadSabores: (mapa['cantidad_sabores'] as num?)?.toInt() ?? 0,
      controlaStock: mapa['controla_stock'] as bool? ?? true,
    );
  }

  static Future<ProductoVenta> actualizarProducto(ProductoVenta producto) async {
    final respuesta = await SupabaseCliente.cliente
        .from('productos')
        .update({
          'nombre': producto.nombre,
          'categoria': producto.categoria,
          'precio': producto.precio,
          'seccion': _mapearSeccionTexto(producto.seccion),
          'requiere_sabores': producto.requiereSabores,
          'cantidad_sabores': producto.cantidadSabores,
          'controla_stock': producto.controlaStock,
        })
        .eq('id', producto.id)
        .select()
        .single();

    final mapa = Map<String, dynamic>.from(respuesta);

    return ProductoVenta(
      id: (mapa['id'] as num).toInt(),
      nombre: (mapa['nombre'] ?? '').toString(),
      categoria: (mapa['categoria'] ?? '').toString(),
      precio: (mapa['precio'] as num).toDouble(),
      seccion: _mapearSeccion((mapa['seccion'] ?? '').toString()),
      requiereSabores: mapa['requiere_sabores'] as bool? ?? false,
      cantidadSabores: (mapa['cantidad_sabores'] as num?)?.toInt() ?? 0,
      controlaStock: mapa['controla_stock'] as bool? ?? true,
    );
  }

  static Future<void> eliminarProducto(int id) async {
    await SupabaseCliente.cliente
        .from('productos')
        .update({'activo': false})
        .eq('id', id);
  }

  static SeccionVenta _mapearSeccion(String valor) {
    switch (valor) {
      case 'individuales':
        return SeccionVenta.individuales;
      case 'combos':
        return SeccionVenta.combos;
      case 'uber':
        return SeccionVenta.uber;
      default:
        return SeccionVenta.individuales;
    }
  }

  static String _mapearSeccionTexto(SeccionVenta valor) {
    switch (valor) {
      case SeccionVenta.individuales:
        return 'individuales';
      case SeccionVenta.combos:
        return 'combos';
      case SeccionVenta.uber:
        return 'uber';
    }
  }
}