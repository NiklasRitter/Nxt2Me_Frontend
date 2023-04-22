class CustomException implements Exception {
  String message;

  CustomException(this.message);

  throwException() {
    throw CustomException(message);
  }

  @override
  String toString() {
    return message;
  }
}
