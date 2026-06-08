enum SessionType {
  corsa('corsa', 'Corsa');

  const SessionType(this.value, this.label);

  final String value;
  final String label;

  static SessionType fromValue(String value) {
    return SessionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SessionType.corsa,
    );
  }
}
