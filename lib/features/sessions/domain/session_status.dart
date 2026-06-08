enum SessionStatus {
  active('active'),
  completed('completed');

  const SessionStatus(this.value);

  final String value;

  bool get isActive => this == SessionStatus.active;

  static SessionStatus fromValue(String value) {
    return SessionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SessionStatus.active,
    );
  }
}
