enum FilterOperator { equals, contains, between }

/// This class is astract and should not be used directly
///
/// Instead use [PropertyFilter], [LogicalOperatorFilter], [RelationFilter].
abstract class Filter {
  String get asJSON;
}

class PropertyFilter implements Filter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  const PropertyFilter(
      {required this.field, required this.operator, required this.value});

  String _operatorAsString(FilterOperator operator) {
    final String value;
    switch (operator) {
      case FilterOperator.equals:
        value = "_eq";
        break;
      case FilterOperator.contains:
        value = "_contains";
        break;
      case FilterOperator.between:
        value = "_between";
        break;
    }
    return value;
  }

  @override
  String get asJSON =>
      '{ "$field": { "${_operatorAsString(operator)}": ${_encodeFilteredValue(value)} }}';

  String _encodeFilteredValue(dynamic value) {
    final builder = StringBuffer();
    if (value is String) {
      builder.write('"$value"');
    } else if (value is Iterable) {
      builder.write('[');
      for (int index = 0; index < value.length; index++) {
        final child = value.elementAt(index);
        builder.write(_encodeFilteredValue(child));
        if (index < value.length - 1) {
          builder.write(", ");
        }
      }
      builder.write(']');
    } else {
      builder.write(value);
    }
    return builder.toString();
  }
}

enum LogicalOperator { and, or }

class LogicalOperatorFilter implements Filter {
  final LogicalOperator operator;
  final List<Filter> children;

  LogicalOperatorFilter({required this.operator, required this.children});
  String _operatorAsString(LogicalOperator operator) {
    final String value;
    switch (operator) {
      case LogicalOperator.and:
        value = "_and";
        break;
      case LogicalOperator.or:
        value = "_or";
        break;
    }
    return value;
  }

  @override
  String get asJSON {
    final buffer = StringBuffer('{ "${_operatorAsString(operator)}": [ ');
    final count = children.length;
    for (int childIndex = 0; childIndex < count; childIndex++) {
      final child = children[childIndex];
      buffer.write(child.asJSON);
      if (childIndex < count - 1) {
        buffer.write(" , ");
      }
    }
    buffer.write(" ] }");
    return buffer.toString();
  }
}

class RelationFilter implements Filter {
  final String propertyName;
  final PropertyFilter linkedObjectFilter;

  RelationFilter(
      {required this.propertyName, required this.linkedObjectFilter});
  @override
  String get asJSON => '{ "$propertyName": ${linkedObjectFilter.asJSON}}';
}
