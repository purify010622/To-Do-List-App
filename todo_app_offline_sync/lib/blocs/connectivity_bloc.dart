import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/connectivity_service.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

/// BLoC to manage connectivity state
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;
  
  ConnectivityBloc({
    required ConnectivityService connectivityService,
  })  : _connectivityService = connectivityService,
        super(const ConnectivityInitial()) {
    on<CheckConnectivity>(_onCheckConnectivity);
    on<ConnectivityChanged>(_onConnectivityChanged);
    
    // Start monitoring connectivity
    _startMonitoring();
  }
  
  void _startMonitoring() {
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        add(ConnectivityChanged(isConnected));
      },
    );
    
    // Check initial connectivity
    add(const CheckConnectivity());
  }
  
  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      emit(const ConnectivityOnline());
    } else {
      emit(const ConnectivityOffline());
    }
  }
  
  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    if (event.isConnected) {
      emit(const ConnectivityOnline());
    } else {
      emit(const ConnectivityOffline());
    }
  }
  
  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}
