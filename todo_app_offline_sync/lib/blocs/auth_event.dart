import 'package:equatable/equatable.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to sign in with Google
class SignInWithGoogle extends AuthEvent {
  const SignInWithGoogle();
}

/// Event to sign out
class SignOut extends AuthEvent {
  const SignOut();
}

/// Event to check authentication status on app start
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
