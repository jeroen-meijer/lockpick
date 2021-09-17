String describeEnum(dynamic obj) {
  if (obj == null) {
    return 'null';
  } else {
    return obj.toString().split('.').last;
  }
}

T findEnumValue<T>(Iterable<T> options, String value) {
  for (final option in options) {
    if (describeEnum(option) == value) {
      return option;
    }
  }

  throw StateError(
    'Could not find enum value "$value" '
    'in options: [${options.map(describeEnum).join(', ')}]',
  );
}
