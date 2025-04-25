class Failure {
  final String message;
  Failure({required this.message});
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

class ValidationFailure extends Failure {
  ValidationFailure({required super.message});
}

class StorageFailure extends Failure {
  StorageFailure({required super.message});
}
