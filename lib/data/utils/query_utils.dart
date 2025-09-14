/// Utility class for building database queries
class QueryUtils {
  /// Builds a filter string for text search across multiple fields
  static String buildTextSearchFilter(String searchTerm, List<String> fields) {
    if (searchTerm.isEmpty || fields.isEmpty) return '';

    final cleanTerm = searchTerm.replaceAll("'", "''"); // Escape single quotes
    final conditions = fields
        .map((field) => "$field.ilike.%$cleanTerm%")
        .join(',');

    return "or($conditions)";
  }

  /// Builds a filter for array contains operations
  static String buildArrayContainsFilter(String field, List<String> values) {
    if (values.isEmpty) return '';

    final conditions = values.map((value) => "$field.cs.{$value}").join(',');

    return values.length == 1 ? conditions : "or($conditions)";
  }

  /// Builds a filter for tag filtering
  static String buildTagFilter(List<String> tagIds) {
    if (tagIds.isEmpty) return '';

    if (tagIds.length == 1) {
      return "contact_tags.tag_id.eq.${tagIds.first}";
    }

    final conditions = tagIds
        .map((tagId) => "contact_tags.tag_id.eq.$tagId")
        .join(',');

    return "contact_tags(or($conditions))";
  }

  /// Builds a filter for date ranges
  static String buildDateRangeFilter(
    String field,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final filters = <String>[];

    if (startDate != null) {
      filters.add("$field.gte.${startDate.toIso8601String()}");
    }

    if (endDate != null) {
      filters.add("$field.lte.${endDate.toIso8601String()}");
    }

    return filters.join(',');
  }

  /// Builds ordering string for queries
  static String buildOrderBy(String field, {bool ascending = true}) {
    return "$field${ascending ? '' : '.desc'}";
  }

  /// Builds multiple column ordering
  static String buildMultipleOrderBy(Map<String, bool> orders) {
    return orders.entries
        .map((entry) => "${entry.key}${entry.value ? '' : '.desc'}")
        .join(',');
  }

  /// Builds a pagination range
  static Map<String, int> buildPaginationRange(int page, int pageSize) {
    final start = page * pageSize;
    final end = start + pageSize - 1;
    return {'start': start, 'end': end};
  }

  /// Builds a select string for specific fields
  static String buildSelectFields(List<String> fields) {
    return fields.join(',');
  }

  /// Builds a select string with related data
  static String buildSelectWithRelations(
    List<String> fields,
    Map<String, List<String>> relations,
  ) {
    final allFields = [...fields];

    for (final entry in relations.entries) {
      final relationName = entry.key;
      final relationFields = entry.value;
      allFields.add("$relationName(${relationFields.join(',')})");
    }

    return allFields.join(',');
  }

  /// Sanitizes user input for SQL queries
  static String sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'''[';\"\\]'''), '');
  }

  /// Builds a filter for boolean fields
  static String buildBooleanFilter(String field, bool value) {
    return "$field.eq.$value";
  }

  /// Builds a filter for null checks
  static String buildNullFilter(String field, {bool isNull = true}) {
    return "$field.is.${isNull ? 'null' : 'not.null'}";
  }

  /// Builds a filter for array intersection
  static String buildArrayIntersectionFilter(
    String field,
    List<String> values,
  ) {
    if (values.isEmpty) return '';

    final arrayString = '{${values.map((v) => '"$v"').join(',')}}';
    return "$field.cd.$arrayString";
  }

  /// Builds a complex filter combining multiple conditions
  static String buildComplexFilter(Map<String, dynamic> conditions) {
    final filters = <String>[];

    for (final entry in conditions.entries) {
      final field = entry.key;
      final value = entry.value;

      if (value == null) {
        filters.add(buildNullFilter(field));
      } else if (value is bool) {
        filters.add(buildBooleanFilter(field, value));
      } else if (value is String) {
        filters.add("$field.eq.$value");
      } else if (value is List<String>) {
        if (value.isNotEmpty) {
          filters.add("$field.in.(${value.join(',')})");
        }
      }
    }

    return filters.join(',');
  }
}
