/// Tipo de tutor propuesto, igual al enum del backend (`ck_postulaciones_tipo_tutor`).
library;

enum TipoTutor {
  interno('interno', 'Interno'),
  externo('externo', 'Externo');

  const TipoTutor(this.wire, this.label);

  final String wire;
  final String label;

  static TipoTutor fromWire(String value) {
    return TipoTutor.values.firstWhere(
      (t) => t.wire == value,
      orElse: () => TipoTutor.interno,
    );
  }
}
