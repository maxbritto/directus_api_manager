class SortProperty {
  final String name;
  final bool ascending;

  const SortProperty(this.name, {this.ascending = true});

  @override
  String toString() {
    return (ascending ? "" : "-") + name;
  }
}
