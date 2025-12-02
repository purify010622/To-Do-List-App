import 'package:equatable/equatable.dart';

/// Base class for connectivity states
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before connectivity is checked
class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

/// State when device is online
class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

/// State when device is offline
class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}
