import 'package:equatable/equatable.dart';
import '../models/user.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - authentication status unknown
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when user is authenticated
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// State when user is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State when authentication is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when authentication error occurs
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
