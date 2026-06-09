enum SubSessionType {
  lap('lap'),
  simple('simple');

  const SubSessionType(this.value);

  final String value;

  String get label => switch (this) {
        SubSessionType.lap => 'Cronometro lap',
        SubSessionType.simple => 'Cronometro',
      };

  static SubSessionType fromValue(String value) {
    return SubSessionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SubSessionType.lap,
    );
  }
}
