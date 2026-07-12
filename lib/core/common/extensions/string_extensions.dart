extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String get truncate {
    if (length <= 100) return this;
    return '${substring(0, 100)}...';
  }

  bool get isValidEmail {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 6;
  }

  bool get isNumericOnly {
    return RegExp(r'^\d+$').hasMatch(this);
  }

  String toPhoneFormat() {
    if (length != 10) return this;
    return '(${substring(0, 3)}) ${substring(3, 6)}-${substring(6)}';
  }
}
