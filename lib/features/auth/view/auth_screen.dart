import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/features/auth/widget/widget.dart';
import 'package:vaulth_app/features/home/cubit/home_cubit.dart';
import 'package:vaulth_app/route/app_router.dart';

@RoutePage()
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _deviceTypeController = TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  bool _showUnauthenticated = false;
  Timer? _splashTimer;

  bool _isPreloadingHome = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AuthCubit>().checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _deviceNameController.dispose();
    _deviceTypeController.dispose();
    super.dispose();
  }

  void _submit() {
    final cubit = context.read<AuthCubit>();
    setState(() => _isSubmitting = true);
    if (_isLoginMode) {
      cubit.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      cubit.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _startSplashTimer() {
    if (_splashTimer != null) return;
    _splashTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showUnauthenticated = true;
        });
      }
    });
  }

  void _resetSplashTimer() {
    _splashTimer?.cancel();
    _splashTimer = null;
    if (_showUnauthenticated) {
      setState(() {
        _showUnauthenticated = false;
      });
    }
  }

  Future<void> _preloadHomeData() async {
    try {
      await context.read<HomeCubit>().loadData();
    } catch (_) {}
    if (mounted) {
      context.replaceRoute(const MainHomeRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (_) {
              _resetSplashTimer();
              if (mounted) setState(() => _isSubmitting = false);
            },
            unauthenticated: () {
              if (mounted) setState(() => _isSubmitting = false);
              if (mounted && !_showUnauthenticated) {
                _startSplashTimer();
              }
            },
            error: (message) {
              if (mounted) {
                setState(() => _isSubmitting = false);
                _showSnackBar(message, isError: true);
              }
            },
          );
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return state.when(
              initial: () => const VaultlySplash(),
              loading: () {
                if (_isSubmitting) {
                  return UnauthenticatedContent(
                    isLoginMode: _isLoginMode,
                    onToggleMode: (value) =>
                        setState(() => _isLoginMode = value),
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    isSubmitting: _isSubmitting,
                    onSubmit: _submit,
                  );
                }
                return const VaultlySplash();
              },
              authenticated: (authResponse) {
                _resetSplashTimer();
                if (!_isPreloadingHome) {
                  _isPreloadingHome = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _preloadHomeData();
                  });
                }
                return const VaultlySplash();
              },
              unauthenticated: () {
                if (!_showUnauthenticated) {
                  return const VaultlySplash();
                }
                return UnauthenticatedContent(
                  isLoginMode: _isLoginMode,
                  onToggleMode: (value) => setState(() => _isLoginMode = value),
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                );
              },
              error: (message) => ErrorContent(
                message: message,
                onRetry: () => context.read<AuthCubit>().checkAuthStatus(),
              ),
            );
          },
        ),
      ),
    );
  }
}
