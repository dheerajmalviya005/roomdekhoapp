import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/error_toast.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    print('\n${'=' * 60}');
    print('🚀 SPLASH SCREEN INITIALIZED');
    print('=' * 60);

    // ✅ START CHECKING AUTH STATUS
    _checkAuthAndNavigate();
  }

  // ✅ METHOD TO CHECK AUTH AND NAVIGATE
  Future<void> _checkAuthAndNavigate() async {
    print('\n🔍 CHECKING AUTHENTICATION STATUS...');

    try {
      // Wait a bit for splash animation
      await Future.delayed(const Duration(milliseconds: 1000));

      // ✅ Step 1: Try to restore user from storage
      print('\n🔄 Attempting to restore user from storage...');
      final isAuthenticated = await AuthService.isAuthenticated();

      if (isAuthenticated) {
        print('✅ USER IS ALREADY AUTHENTICATED');

        // ✅ Step 2: Get user role
        final role = AuthService.getUserRole();
        final userId = AuthService.getUserId();
        print('📊 User Details:');
        print('   ID: $userId');
        print('   Role: $role');

        // ✅ Step 3: Navigate based on role
        await _navigateBasedOnRole(role);
      } else {
        print('🔐 NO USER FOUND - GOING TO LOGIN');
        await _goToLogin();
      }
    } catch (e) {
      print('❌ ERROR CHECKING AUTH: $e');
      print('⚠️ Falling back to login screen');

      // ✅ Error for authentication error
      if (mounted) {
        ErrorToast.show(
          context,
          title: 'Authentication Error',
          message: 'Failed to check login status',
          icon: Icons.error,
          accent: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }

      await _goToLogin();
    }
  }

  // ✅ METHOD TO NAVIGATE BASED ON ROLE
  Future<void> _navigateBasedOnRole(String? role) async {
    if (!mounted) return;

    print('\n📍 NAVIGATION DECISION BASED ON ROLE:');

    // Ensure minimum splash time (2 seconds)
    final elapsed = DateTime.now().difference(_startTime);
    final remaining = const Duration(seconds: 2) - elapsed;

    if (remaining > Duration.zero) {
      print('⏳ Waiting ${remaining.inMilliseconds}ms...');
      await Future.delayed(remaining);
    }

    if (role == 'OWNER') {
      print('   ✅ Role: OWNER');
      print('   ➡️ Navigating to: /RenterTabs');

      if (mounted) {
        // ✅ ErrorToast for welcome message
        ErrorToast.show(
          context,
          title: 'Welcome back!',
          message: 'Owner dashboard loading...',
          icon: Icons.person,
          accent: Colors.green,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        context.goNamed('RenterTabs');
      }
    } else if (role == 'TENANT') {
      print('   ✅ Role: TENANT');
      print('   ➡️ Navigating to: /bottomnav');

      if (mounted) {
        // ✅ ErrorToast for welcome message
        ErrorToast.show(
          context,
          title: 'Welcome back!',
          message: 'Tenant dashboard loading...',
          icon: Icons.home,
          accent: Colors.blue,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        context.goNamed('bottomnav');
      }
    } else {
      print('   ⚠️ Unknown role: $role');
      print('   ➡️ Defaulting to login');

      if (mounted) {
        ErrorToast.show(
          context,
          title: 'Role Error',
          message: 'Unknown user role detected',
          icon: Icons.warning,
          accent: Colors.orange,
          duration: const Duration(seconds: 2),
        );
      }

      await _goToLogin();
    }
  }

  // ✅ METHOD TO GO TO LOGIN SCREEN
  Future<void> _goToLogin() async {
    if (!mounted) return;

    // Ensure minimum splash time (3 seconds total)
    final elapsed = DateTime.now().difference(_startTime);
    final remaining = const Duration(seconds: 3) - elapsed;

    if (remaining > Duration.zero) {
      print('⏳ Waiting ${remaining.inMilliseconds}ms before login...');
      await Future.delayed(remaining);
    }

    if (mounted) {
      print('   ➡️ Navigating to: /login');
      context.goNamed('login');
    }
  }

  // Track when splash started
  final DateTime _startTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double maxWidth = size.width * 0.9;
    final double maxHeight = size.height * 0.9;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                  child: Image.asset(
                    'assets/icon/splash.png',
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
