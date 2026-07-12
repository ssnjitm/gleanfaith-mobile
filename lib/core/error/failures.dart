import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error', super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Validation error'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication error', super.statusCode});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Not found'});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'Unexpected error'});
}
