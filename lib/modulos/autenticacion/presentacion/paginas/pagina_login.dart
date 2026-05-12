import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../nucleo/tema/colores_app.dart';
import '../../../inicio/presentacion/paginas/pagina_inicio.dart';
import '../../datos/usuarios_quemados.dart';
import '../../dominio/modelos/usuario.dart';

class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();

  bool _ocultarClave = true;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controlador.dispose();
    _usuarioController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFD99A1B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Usuario? _buscarUsuario(String usuarioIngresado) {
    for (final usuario in UsuariosQuemados.lista) {
      if (usuario.usuario.toLowerCase() == usuarioIngresado.toLowerCase()) {
        return usuario;
      }
    }
    return null;
  }

  Future<void> _iniciarSesion() async {
    if (_cargando) return;

    final usuarioIngresado = _usuarioController.text.trim();
    final claveIngresada = _claveController.text.trim();

    if (usuarioIngresado.isEmpty || claveIngresada.isEmpty) {
      _mostrarMensaje('Completa usuario y contraseña.');
      return;
    }

    setState(() {
      _cargando = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final usuario = _buscarUsuario(usuarioIngresado);

    if (!mounted) return;

    if (usuario == null) {
      setState(() {
        _cargando = false;
      });
      _mostrarMensaje('Usuario no encontrado.');
      return;
    }

    if (!usuario.activo) {
      setState(() {
        _cargando = false;
      });
      _mostrarMensaje('Este usuario está inactivo.');
      return;
    }

    if (usuario.clave != claveIngresada) {
      setState(() {
        _cargando = false;
      });
      _mostrarMensaje('Contraseña incorrecta.');
      return;
    }

    setState(() {
      _cargando = false;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaginaInicio(usuario: usuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controlador,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF020202),
                  Color(0xFF070707),
                  Color(0xFF101010),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CieloPainter(
                      progreso: _controlador.value,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF242424),
                          Color(0xFF1A1A1A),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: ColoresApp.principal.withOpacity(0.08),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: ColoresApp.principal.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/imagenes/logo_moons.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Bienvenido',
                          style: TextStyle(
                            color: ColoresApp.textoPrincipal,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inicia sesión para acceder al sistema POS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColoresApp.textoSecundario,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _CampoLogin(
                          controller: _usuarioController,
                          etiqueta: 'Usuario',
                          icono: Icons.person_outline_rounded,
                          onSubmitted: (_) => _iniciarSesion(),
                        ),
                        const SizedBox(height: 16),
                        _CampoLogin(
                          controller: _claveController,
                          etiqueta: 'Contraseña',
                          icono: Icons.lock_outline_rounded,
                          esContrasena: _ocultarClave,
                          onSubmitted: (_) => _iniciarSesion(),
                          sufijo: IconButton(
                            onPressed: () {
                              setState(() {
                                _ocultarClave = !_ocultarClave;
                              });
                            },
                            icon: Icon(
                              _ocultarClave
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: ColoresApp.textoSecundario,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [
                                ColoresApp.principalClaro,
                                ColoresApp.principal,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ColoresApp.principal.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Ingresar',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CampoLogin extends StatelessWidget {
  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final bool esContrasena;
  final Widget? sufijo;
  final ValueChanged<String>? onSubmitted;

  const _CampoLogin({
    required this.controller,
    required this.etiqueta,
    required this.icono,
    this.esContrasena = false,
    this.sufijo,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: esContrasena,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: etiqueta,
        hintStyle: const TextStyle(
          color: ColoresApp.textoSecundario,
        ),
        prefixIcon: Icon(
          icono,
          color: ColoresApp.principal,
          size: 20,
        ),
        suffixIcon: sufijo,
        filled: true,
        fillColor: const Color(0xFF121212),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: ColoresApp.principal,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CieloPainter extends CustomPainter {
  final double progreso;

  _CieloPainter({required this.progreso});

  @override
  void paint(Canvas canvas, Size size) {
    _dibujarNeblina(canvas, size);
    _dibujarLuna(canvas, size);
    _dibujarEstrellas(canvas, size);
  }

  void _dibujarNeblina(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          ColoresApp.principal.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.08, size.height * 0.06),
          radius: size.width * 0.16,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.06),
      size.width * 0.16,
      paint1,
    );

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.025),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.22),
          radius: size.width * 0.20,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.22),
      size.width * 0.20,
      paint2,
    );
  }

  void _dibujarLuna(Canvas canvas, Size size) {
    final centro = Offset(size.width * 0.72, size.height * 0.24);
    final radio = math.min(size.width, size.height) * 0.11;

    final sombra = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
      ..color = Colors.white.withOpacity(0.04);
    canvas.drawCircle(centro, radio + 8, sombra);

    final luna = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.035),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: centro, radius: radio));

    canvas.drawCircle(centro, radio, luna);

    final tapa = Paint()..color = const Color(0xFF060606).withOpacity(0.92);
    canvas.drawCircle(
      Offset(centro.dx + radio * 0.34, centro.dy - radio * 0.06),
      radio * 0.92,
      tapa,
    );
  }

  void _dibujarEstrellas(Canvas canvas, Size size) {
    const total = 140;

    for (int i = 0; i < total; i++) {
      final randomX = ((i * 37) % 1000) / 1000;
      final randomY = ((i * 91) % 1000) / 1000;

      final dx = randomX * size.width;
      final dy = randomY * size.height;

      final baseTam = 0.8 + ((i * 17) % 10) / 10;
      final fase = (progreso * 2 * math.pi) + (i * 0.35);
      final brillo = 0.35 + ((math.sin(fase) + 1) / 2) * 0.55;

      final paint = Paint()..color = Colors.white.withOpacity(brillo * 0.9);
      canvas.drawCircle(Offset(dx, dy), baseTam, paint);

      if (i % 11 == 0) {
        final glow = Paint()
          ..color = Colors.white.withOpacity(brillo * 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(Offset(dx, dy), baseTam + 1.2, glow);
      }

      if (i % 23 == 0) {
        final cruz = Paint()
          ..color = Colors.white.withOpacity(brillo * 0.55)
          ..strokeWidth = 0.6;

        canvas.drawLine(
          Offset(dx - 3, dy),
          Offset(dx + 3, dy),
          cruz,
        );
        canvas.drawLine(
          Offset(dx, dy - 3),
          Offset(dx, dy + 3),
          cruz,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CieloPainter oldDelegate) {
    return oldDelegate.progreso != progreso;
  }
}