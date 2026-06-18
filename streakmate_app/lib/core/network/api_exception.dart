/// api_exception.dart
/// Normalized error thrown by repositories, carrying the backend's message
/// and statusCode (your controllers always return { success:false, message }).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}