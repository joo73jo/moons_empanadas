import '../dominio/modelos/usuario.dart';

class UsuariosQuemados {
  static const List<Usuario> lista = [
    Usuario(
      nombre: 'David Tonato',
      usuario: 'David2T',
      rol: 'dueno',
      clave: 'David2T#2026',
      activo: true,
    ),
    Usuario(
      nombre: 'Vanessa Tigsilema',
      usuario: 'Vane2T',
      rol: 'dueno',
      clave: 'Vane2T#2026',
      activo: true,
    ),
    Usuario(
      nombre: 'Adriana Tonato',
      usuario: 'Adri1T',
      rol: 'empleado',
      clave: 'Adri1T#2026',
      activo: true,
    ),
    Usuario(
      nombre: 'Empleado nuevo 1',
      usuario: 'Nuevo1',
      rol: 'empleado',
      clave: 'Nuevo1',
      activo: true,
    ),
    Usuario(
      nombre: 'Empleado nuevo 2',
      usuario: 'Nuevo2',
      rol: 'invitado',
      clave: 'Nuevo2',
      activo: true,
    ),
    Usuario(
      nombre: 'Empleado nuevo 3',
      usuario: 'Nuevo3',
      rol: 'invitado',
      clave: 'Nuevo3',
      activo: true,
    ),
  ];
}