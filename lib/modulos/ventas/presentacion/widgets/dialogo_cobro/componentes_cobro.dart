part of '../dialogo_cobro.dart';

extension _DialogoCobroComponentes on _DialogoCobroState {
  Widget _bloque({
    required String titulo,
    required IconData icono,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.fondoSecundario,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: ColoresApp.principal),
              const SizedBox(width: 9),
              Text(
                titulo,
                style: const TextStyle(
                  color: ColoresApp.textoPrincipal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _opcionMetodo({
    required MetodoPago metodo,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: activo ? ColoresApp.principal.withOpacity(0.14) : Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo
                ? ColoresApp.principal
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconoMetodo(metodo),
              color: activo ? ColoresApp.principal : ColoresApp.textoSecundario,
            ),
            const SizedBox(width: 12),
            Text(
              _nombreMetodo(metodo),
              style: TextStyle(
                color: ColoresApp.textoPrincipal,
                fontWeight: activo ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenEfectivoSimple() {
    return _miniResumen(
      titulo: _efectivoSimpleInsuficiente
          ? 'Falta por pagar'
          : 'Vuelto a entregar',
      valor: _efectivoSimpleInsuficiente
          ? '\$${(_totalFinal - _valorRecibidoSimple).toStringAsFixed(2)}'
          : '\$${_cambioSimple.toStringAsFixed(2)}',
      color: _efectivoSimpleInsuficiente
          ? ColoresApp.error
          : ColoresApp.principal,
    );
  }

  Widget _campoDinero({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    bool error = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(
        color: ColoresApp.textoPrincipal,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        prefixStyle: const TextStyle(
          color: ColoresApp.principal,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: error ? ColoresApp.error : Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: error ? ColoresApp.error : ColoresApp.principal,
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        hintStyle: const TextStyle(color: ColoresApp.textoSecundario),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _selectorDatofono({
    required String valor,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: valor,
      dropdownColor: ColoresApp.superficie,
      style: const TextStyle(color: ColoresApp.textoPrincipal),
      decoration: InputDecoration(
        labelText: 'Datáfono',
        labelStyle: const TextStyle(color: ColoresApp.textoSecundario),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items: const [
        DropdownMenuItem(value: 'Bendo', child: Text('Bendo')),
        DropdownMenuItem(value: 'Ya Ganaste', child: Text('Ya Ganaste')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _miniResumen({
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaResumen({
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: ColoresApp.textoSecundario,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _botonesInferiores(bool esCelular) {
    final cancelar = OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.textoPrincipal,
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text('Cancelar'),
    );

    final String textoConfirmar;

    if (widget.soloCobro) {
      textoConfirmar = 'Confirmar cobro';
    } else if (_requiereCobroAhora) {
      textoConfirmar = 'Cobrar y enviar a preparación';
    } else {
      textoConfirmar = 'Enviar a preparación';
    }

    final confirmar = ElevatedButton(
      onPressed: _confirmar,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColoresApp.principal,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        textoConfirmar,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );

    if (esCelular) {
      return Column(
        children: [
          SizedBox(width: double.infinity, height: 48, child: confirmar),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 44, child: cancelar),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: SizedBox(height: 48, child: cancelar)),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 48, child: confirmar)),
      ],
    );
  }
}
