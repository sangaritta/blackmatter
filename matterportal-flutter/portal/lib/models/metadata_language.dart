class MetadataLanguage {
  final String code;
  final String name;

  const MetadataLanguage(this.code, this.name);

  factory MetadataLanguage.fromMap(Map<String, dynamic> map) {
    return MetadataLanguage(
      map['code'] as String,
      map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'code': code, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetadataLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}
