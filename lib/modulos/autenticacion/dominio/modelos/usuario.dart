class Usuario {
  final String nombre;
  final String usuario;
  final String rol;
  final String clave;
  final bool activo;

  const Usuario({
    required this.nombre,
    required this.usuario,
    required this.rol,
    required this.clave,
    required this.activo,
  });
}