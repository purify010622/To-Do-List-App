import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc_exports.dart';

/// Authentication screen for Google sign-in
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Navigate back when authenticated
            Navigator.of(context).pop();
          } else if (state is AuthError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<AuthBloc>().add(const SignInWithGoogle());
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App branding
                  _buildBranding(context),
                  const SizedBox(height: 48),

                  // Welcome message
                  _buildWelcomeMessage(context),
                  const SizedBox(height: 48),

                  // Sign in button or loading state
                  if (state is AuthLoading)
                    _buildLoadingState(context)
                  else
                    _buildSignInButton(context),

                  const SizedBox(height: 24),

                  // Skip button for guest mode
                  _buildSkipButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build app branding section
  Widget _buildBranding(BuildContext context) {
    return Column(
      children: [
        // App icon/logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        // App name
        Text(
          'Todo App',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Offline-First Task Management',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  /// Build welcome message
  Widget _buildWelcomeMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Sign in with Google to sync your tasks across devices, or continue as a guest to use the app offline.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build sign in button
  Widget _buildSignInButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<AuthBloc>().add(const SignInWithGoogle());
      },
      icon: Image.asset(
        'assets/google_logo.png',
        height: 24,
        width: 24,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if asset not found
          return const Icon(Icons.login, size: 24);
        },
      ),
      label: const Text(
        'Sign in with Google',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  /// Build loading state during authentication
  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Signing in...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  /// Build skip button for guest mode
  Widget _buildSkipButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: Text(
        'Continue as Guest',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
