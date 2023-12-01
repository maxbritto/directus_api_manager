import 'dart:convert';

enum FilterOperator {
  equals,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  oneOf,
  notOneOf,
  isNull,
  isNotNull,
  contains,
  notContains,
  startWith,
  notStartWith,
  endWith,
  notEndWith,
  between,
  notBetween,
  isEmpty,
  isNotEmpty
}

/// This class is astract and should not be used directly
///
/// Instead use [PropertyFilter], [LogicalOperatorFilter], [RelationFilter].
abstract class Filter {
  String get asJSON;
  Map<String, dynamic> get asMap;
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
      case FilterOperator.notEqual:
        value = "_neq";
        break;

      case FilterOperator.lessThan:
        value = "_lt";
        break;

      case FilterOperator.lessThanOrEqual:
        value = "_lte";
        break;
      case FilterOperator.greaterThan:
        value = "_gt";
        break;
      case FilterOperator.greaterThanOrEqual:
        value = "_gte";
        break;
      case FilterOperator.oneOf:
        value = "_in";
        break;
      case FilterOperator.notOneOf:
        value = "_nin";
        break;
      case FilterOperator.isNull:
        value = "_null";
        break;
      case FilterOperator.isNotNull:
        value = "_nnull";
        break;
      case FilterOperator.contains:
        value = "_contains";
        break;
      case FilterOperator.notContains:
        value = "_ncontains";
        break;

      case FilterOperator.startWith:
        value = "_starts_with";
        break;
      case FilterOperator.notStartWith:
        value = "_nstarts_with";
        break;
      case FilterOperator.endWith:
        value = "_ends_with";
        break;
      case FilterOperator.notEndWith:
        value = "_nends_with";
        break;
      case FilterOperator.between:
        value = "_between";
        break;
      case FilterOperator.notBetween:
        value = "_nbetween";
        break;
      case FilterOperator.isEmpty:
        value = "_empty";
        break;
      case FilterOperator.isNotEmpty:
        value = "_nempty";
        break;
    }
    return value;
  }

  @override
  String get asJSON =>
      '{ "$field": { "${_operatorAsString(operator)}": ${jsonEncode(value)} }}';

  @override
  Map<String, dynamic> get asMap => {
        field: {_operatorAsString(operator): value}
      };
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

  @override
  Map<String, dynamic> get asMap {
    List<Map<String, dynamic>> childrenMap = [];
    final count = children.length;
    for (int childIndex = 0; childIndex < count; childIndex++) {
      final child = children[childIndex];
      childrenMap.add(child.asMap);
    }
    Map<String, dynamic> map = {_operatorAsString(operator): childrenMap};

    return map;
  }
}

class RelationFilter implements Filter {
  final String propertyName;
  final Filter linkedObjectFilter;

  RelationFilter(
      {required this.propertyName, required this.linkedObjectFilter});
  @override
  String get asJSON => '{ "$propertyName": ${linkedObjectFilter.asJSON}}';

  @override
  Map<String, dynamic> get asMap => {propertyName: linkedObjectFilter.asMap};
}
