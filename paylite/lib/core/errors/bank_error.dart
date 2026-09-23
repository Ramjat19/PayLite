sealed class BankError {
  final String message;
  final String? traceId;
  final int? statusCode;

  const BankError(this.message, {this.traceId, this.statusCode});
}

class Unauthorized extends BankError {
  const Unauthorized([super.message = 'Please sign in again.']);
}

class VpaNotFound extends BankError {
  const VpaNotFound([super.message = 'No account found for this UPI ID.']);
}

class InsufficientFunds extends BankError {
  const InsufficientFunds([super.message = 'Insufficient balance.']);
}

class LimitExceeded extends BankError {
  const LimitExceeded([super.message = 'Transaction limit exceeded.']);
}

class Expired extends BankError {
  const Expired([super.message = 'This request has expired.']);
}

class Network extends BankError {
  const Network([super.message = 'Unable to connect. Check your internet.']);
}

class Server extends BankError {
  const Server([super.message = 'Something went wrong on our end.']);
}

class Unknown extends BankError {
  const Unknown([super.message = 'An unexpected error occurred.']);
}   