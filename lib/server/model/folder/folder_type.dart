enum FolderType {
  default_('DEFAULT'),
  hidden('HIDDEN'),
  shared('SHARED'),
  locked('LOCKED');

  final String value;
  const FolderType(this.value);

  static FolderType fromString(String value) {
    return FolderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FolderType.default_,
    );
  }

  String toJson() => value;
}
