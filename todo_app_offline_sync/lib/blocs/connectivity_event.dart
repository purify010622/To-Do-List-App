import 'package:equatable/equatable.dart';

/// Base class for connectivity events
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event when connectivity status changes
class ConnectivityChanged extends ConnectivityEvent {
  final bool isConnected;
  
  const ConnectivityChanged(this.isConnected);
  
  @override
  List<Object?> get props => [isConnected];
}

/// Event to check current connectivity status
class CheckConnectivity extends ConnectivityEvent {
  const CheckConnectivity();
}
