import 'package:directus_api_manager/src/filter.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  test('PropertyFilter equals', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.equals, value: "Hello World!");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_eq": "Hello World!" }}');
  });

  test('PropertyFilter not equals', () {
    final sut = PropertyFilter(
        field: "title",
        operator: FilterOperator.notEqual,
        value: "Hello World!");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_neq": "Hello World!" }}');
  });

  test('PropertyFilter less than', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.lessThan, value: 10);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_lt": 10 }}');
  });

  test('PropertyFilter equal or less than', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.lessThanOrEqual, value: 10);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_lte": 10 }}');
  });

  test('PropertyFilter greater than', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.greaterThan, value: 10);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_gt": 10 }}');
  });

  test('PropertyFilter equal or greater than', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.greaterThanOrEqual, value: 10);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_gte": 10 }}');
  });

  test('PropertyFilter is one of', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.oneOf, value: [1, 2, 3]);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_in": [1, 2, 3] }}');
  });

  test('PropertyFilter is not one of', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.notOneOf, value: [1, 2, 3]);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_nin": [1, 2, 3] }}');
  });

  test('PropertyFilter isNull', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.isNull, value: null);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_null": null }}');
  });

  test('PropertyFilter isNotNull', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.isNotNull, value: null);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_nnull": null }}');
  });

  test('PropertyFilter contains', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.contains, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_contains": "Hello" }}');
  });

  test('PropertyFilter not contains', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.notContains, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_ncontains": "Hello" }}');
  });

  test('PropertyFilter start with', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.startWith, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_starts_with": "Hello" }}');
  });

  test('PropertyFilter not start with', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.notStartWith, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_nstarts_with": "Hello" }}');
  });

  test('PropertyFilter end with', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.endWith, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_ends_with": "Hello" }}');
  });

  test('PropertyFilter not end with', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.notEndWith, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_nends_with": "Hello" }}');
  });

  test('PropertyFilter between', () {
    final sut = PropertyFilter(
        field: "score", operator: FilterOperator.between, value: [10, 100]);
    final json = sut.asJSON;
    expect(json, '{ "score": { "_between": [10, 100] }}');
  });

  test('PropertyFilter not between', () {
    final sut = PropertyFilter(
        field: "score", operator: FilterOperator.notBetween, value: [10, 100]);
    final json = sut.asJSON;
    expect(json, '{ "score": { "_nbetween": [10, 100] }}');
  });

  test('PropertyFilter between system variables', () {
    final sut = PropertyFilter(
        field: "start_date",
        operator: FilterOperator.between,
        value: ["\$NOW", "\$NOW(+2 weeks)"]);
    final json = sut.asJSON;
    expect(
        json, '{ "start_date": { "_between": ["\$NOW", "\$NOW(+2 weeks)"] }}');
  });

  test('PropertyFilter is empty', () {
    final sut = PropertyFilter(
        field: "score", operator: FilterOperator.isEmpty, value: null);
    final json = sut.asJSON;
    expect(json, '{ "score": { "_empty": null }}');
  });

  test('PropertyFilter is not empty', () {
    final sut = PropertyFilter(
        field: "score", operator: FilterOperator.isNotEmpty, value: null);
    final json = sut.asJSON;
    expect(json, '{ "score": { "_nempty": null }}');
  });

  test('LogicalFilter and', () {
    final a1 = PropertyFilter(
        field: "title", operator: FilterOperator.contains, value: "Hello");
    final a2 = PropertyFilter(
        field: "description", operator: FilterOperator.equals, value: "world");
    final sut = LogicalOperatorFilter(
        operator: LogicalOperator.and, children: [a1, a2]);
    final json = sut.asJSON;
    expect(json,
        '{ "_and": [ { "title": { "_contains": "Hello" }} , { "description": { "_eq": "world" }} ] }');
  });

  test('LogicalFilter or', () {
    final a1 = PropertyFilter(
        field: "title", operator: FilterOperator.contains, value: "Hello");
    final a2 = PropertyFilter(
        field: "description", operator: FilterOperator.equals, value: "world");
    final sut =
        LogicalOperatorFilter(operator: LogicalOperator.or, children: [a1, a2]);
    final json = sut.asJSON;
    expect(json,
        '{ "_or": [ { "title": { "_contains": "Hello" }} , { "description": { "_eq": "world" }} ] }');
  });

  test('RelationFilter _eq', () {
    final sut = RelationFilter(
        propertyName: "users",
        linkedObjectFilter: PropertyFilter(
            field: "id", operator: FilterOperator.equals, value: "23"));
    final json = sut.asJSON;
    expect(json, '{ "users": { "id": { "_eq": "23" }}}');
  });

  test('RelationFilter M2M _eq', () {
    final m2mRelation = RelationFilter(
        propertyName: "idWord",
        linkedObjectFilter: PropertyFilter(
            field: "word", operator: FilterOperator.equals, value: "zelda"));
    final sut =
        RelationFilter(propertyName: "words", linkedObjectFilter: m2mRelation);
    final json = sut.asJSON;

    expect(json, '{ "words": { "idWord": { "word": { "_eq": "zelda" }}}}');
  });

  test('RelationFilter M2M _contains', () {
    final m2mRelation = RelationFilter(
        propertyName: "idWord",
        linkedObjectFilter: PropertyFilter(
            field: "word", operator: FilterOperator.contains, value: "zelda"));
    final sut =
        RelationFilter(propertyName: "words", linkedObjectFilter: m2mRelation);
    final json = sut.asJSON;

    expect(
        json, '{ "words": { "idWord": { "word": { "_contains": "zelda" }}}}');
  });
}
