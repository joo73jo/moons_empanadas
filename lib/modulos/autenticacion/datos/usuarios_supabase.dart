import '../../../nucleo/constantes/supabase_cliente.dart';
import '../dominio/modelos/usuario.dart';

class UsuariosSupabase {
  static Future<Usuario?> iniciarSesion({
    required String usuarioIngresado,
    required String claveIngresada,
  }) async {
    final respuesta = await SupabaseCliente.cliente
        .from('usuarios')
        .select()
        .ilike('usuario', usuarioIngresado)
        .eq('activo', true)
        .limit(1);

    if (respuesta.isEmpty) return null;

    final mapa = Map<String, dynamic>.from(respuesta.first as Map);

    final claveGuardada = (mapa['clave'] ?? '').toString();
    if (claveGuardada != claveIngresada) {
      throw Exception('Contraseña incorrecta.');
    }

    return Usuario(
      nombre: (mapa['nombre'] ?? '').toString(),
      usuario: (mapa['usuario'] ?? '').toString(),
      rol: (mapa['rol'] ?? '').toString(),
      clave: claveGuardada,
      activo: mapa['activo'] as bool? ?? true,
    );
  }
}