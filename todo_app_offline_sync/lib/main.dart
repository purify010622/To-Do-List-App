import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/task_bloc_exports.dart';
import 'blocs/auth_bloc_exports.dart';
import 'blocs/sync_bloc_exports.dart';
import 'firebase_options.dart';
import 'blocs/connectivity_bloc_exports.dart';
import 'services/local_storage_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_queue_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/sync_screen.dart';
import 'models/task.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Set up notification tap handler
  notificationService.onNotificationTap = (taskId) {
    // Navigate to task edit screen when notification is tapped
    navigatorKey.currentState?.pushNamed(
      '/task/edit',
      arguments: null, // We'll need to fetch the task by ID
    );
  };
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  /// Build named routes for the app
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const HomeScreen(),
      '/splash': (context) => SplashScreen(
            onComplete: () {
              setState(() {
                _showSplash = false;
              });
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
      '/auth': (context) => const AuthScreen(),
      '/sync': (context) => const SyncScreen(),
      '/task/create': (context) => const TaskFormScreen(),
    };
  }

  /// Handle dynamic routes (e.g., task edit with parameters)
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/task/edit') {
      final task = settings.arguments as Task?;
      return MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
        settings: settings,
      );
    }
    return null;
  }

  /// Build light theme with Material Design 3
  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // Typography scale
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      
      // Card theme with elevation and shadows
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      
      // FloatingActionButton theme with 48x48dp minimum
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
      ),
      
      // Button themes with 48x48dp minimum touch targets
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      
      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    );
  }

  /// Build dark theme with Material Design 3
  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      
      // Use same typography scale as light theme
      textTheme: _buildLightTheme().textTheme,
      
      // Card theme with elevation and shadows
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      
      // FloatingActionButton theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      
      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final taskRepository = LocalStorageService();
    final authService = AuthService();
    final cloudSyncService = CloudSyncService();
    final notificationService = NotificationService();
    final connectivityService = ConnectivityService();
    final syncQueueService = SyncQueueService(
      cloudSyncService: cloudSyncService,
      authService: authService,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SyncQueueService>.value(value: syncQueueService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TaskBloc>(
            create: (context) => TaskBloc(
              repository: taskRepository,
              notificationService: notificationService,
            )..add(const LoadTasks()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authService: authService,
            )..add(const CheckAuthStatus()),
          ),
          BlocProvider<SyncBloc>(
            create: (context) => SyncBloc(
              taskRepository: taskRepository,
              cloudSyncService: cloudSyncService,
              authService: authService,
            ),
          ),
          BlocProvider<ConnectivityBloc>(
            create: (context) => ConnectivityBloc(
              connectivityService: connectivityService,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Todo App',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: ThemeMode.system,
          initialRoute: _showSplash ? '/splash' : '/',
          routes: _buildRoutes(),
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }
}
