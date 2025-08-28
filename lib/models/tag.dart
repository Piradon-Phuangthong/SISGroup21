class Tag {
  final String name;
  final int colorIndex;

  Tag(this.name, this.colorIndex);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          colorIndex == other.colorIndex;

  @override
  int get hashCode => name.hashCode ^ colorIndex.hashCode;
}
