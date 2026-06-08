enum SessionKind {
  gara('gara', 'Gara'),
  allenamento('allenamento', 'Allenamento');

  const SessionKind(this.value, this.label);

  final String value;
  final String label;

  static SessionKind fromValue(String value) {
    return SessionKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => SessionKind.allenamento,
    );
  }
}
