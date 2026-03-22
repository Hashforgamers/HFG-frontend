class AuthConflictException implements Exception {
  AuthConflictException({
    required this.state,
    required this.message,
    this.email,
  });

  final String state;
  final String message;
  final String? email;

  @override
  String toString() {
    return 'AuthConflictException(state: $state, message: $message, email: $email)';
  }
}
