import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'services/crashlytics_service.dart';

/// Example main.dart with Crashlytics integration
/// 
/// This file shows how to integrate Crashlytics into your app.
/// Copy the relevant parts to your actual main.dart file.

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Crashlytics service
  final crashlytics = CrashlyticsService();
  await crashlytics.initialize();
  
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // Log app start
  crashlytics.log('App started');
  
  // Set initial custom keys
  await crashlytics.setCustomKeys({
    'app_version': '1.0.0',
    'environment': kReleaseMode ? 'production' : 'development',
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final crashlytics = CrashlyticsService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crashlytics Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Crashlytics Integration Example'),
            const SizedBox(height: 20),
            
            // Example: Log a message
            ElevatedButton(
              onPressed: () {
                crashlytics.log('User tapped log button');
              },
              child: const Text('Log Message'),
            ),
            
            const SizedBox(height: 10),
            
            // Example: Record non-fatal error
            ElevatedButton(
              onPressed: () async {
                try {
                  throw Exception('This is a test exception');
                } catch (e, stack) {
                  await crashlytics.recordError(
                    e,
                    stack,
                    reason: 'Test error from button',
                    fatal: false,
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Non-fatal error recorded'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Record Non-Fatal Error'),
            ),
            
            const SizedBox(height: 10),
            
            // Example: Set custom key
            ElevatedButton(
              onPressed: () async {
                await crashlytics.setCustomKey('button_taps', 1);
                crashlytics.log('Custom key set');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom key set'),
                    ),
                  );
                }
              },
              child: const Text('Set Custom Key'),
            ),
            
            const SizedBox(height: 20),
            
            // WARNING: This will crash the app!
            // Only use for testing Crashlytics integration
            if (kDebugMode)
              ElevatedButton(
                onPressed: () {
                  crashlytics.forceCrash();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Test Crash (Debug Only)',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Example: Using Crashlytics in a BLoC
/// 
/// ```dart
/// class TaskBloc extends Bloc<TaskEvent, TaskState> {
///   final CrashlyticsService crashlytics = CrashlyticsService();
///   
///   TaskBloc() : super(TasksLoading()) {
///     on<AddTask>(_onAddTask);
///   }
///   
///   Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
///     crashlytics.log('Adding task: ${event.title}');
///     
///     try {
///       final task = await repository.createTask(event.title);
///       crashlytics.log('Task created successfully');
///       emit(TasksLoaded([task]));
///     } catch (e, stack) {
///       crashlytics.log('Failed to create task');
///       await crashlytics.recordError(
///         e,
///         stack,
///         reason: 'Task creation failed',
///         fatal: false,
///       );
///       emit(TaskError(e.toString()));
///     }
///   }
/// }
/// ```

/// Example: Using Crashlytics with Authentication
/// 
/// ```dart
/// class AuthBloc extends Bloc<AuthEvent, AuthState> {
///   final CrashlyticsService crashlytics = CrashlyticsService();
///   
///   Future<void> _onSignIn(SignIn event, Emitter<AuthState> emit) async {
///     try {
///       final user = await authService.signIn();
///       
///       // Set user context in Crashlytics
///       await crashlytics.setUserId(user.uid);
///       await crashlytics.setCustomKeys({
///         'email': user.email,
///         'display_name': user.displayName ?? 'Unknown',
///       });
///       
///       crashlytics.log('User signed in: ${user.uid}');
///       emit(Authenticated(user));
///     } catch (e, stack) {
///       await crashlytics.recordError(
///         e,
///         stack,
///         reason: 'Sign in failed',
///         fatal: false,
///       );
///       emit(AuthError(e.toString()));
///     }
///   }
///   
///   Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
///     await crashlytics.clearUserId();
///     crashlytics.log('User signed out');
///     emit(Unauthenticated());
///   }
/// }
/// ```

/// Example: Using Crashlytics with Sync
/// 
/// ```dart
/// class SyncService {
///   final CrashlyticsService crashlytics = CrashlyticsService();
///   
///   Future<void> syncTasks() async {
///     crashlytics.log('Sync started');
///     
///     try {
///       final localTasks = await localRepository.getAllTasks();
///       await crashlytics.setCustomKey('local_tasks_count', localTasks.length);
///       
///       final remoteTasks = await cloudService.downloadTasks();
///       await crashlytics.setCustomKey('remote_tasks_count', remoteTasks.length);
///       
///       final merged = mergeTasks(localTasks, remoteTasks);
///       await crashlytics.setCustomKey('merged_tasks_count', merged.length);
///       
///       crashlytics.log('Sync completed successfully');
///     } catch (e, stack) {
///       crashlytics.log('Sync failed');
///       await crashlytics.recordError(
///         e,
///         stack,
///         reason: 'Sync operation failed',
///         fatal: false,
///       );
///       rethrow;
///     }
///   }
/// }
/// ```
