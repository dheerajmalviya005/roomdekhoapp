import 'package:go_router/go_router.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../screens/authentication/rental_animated_login.dart';
import '../screens/authentication/sign_up_authentication.dart';
import '../screens/authentication/rental_forgot_password_screen.dart';
import '../screens/authentication/create_new_password_screen.dart';
import '../screens/main_srceen_component/renter_all_screen_component/renter_bottom_navigation_component/bottom_nav_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const RentalAnimatedLogin(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpAuthenticationScreen(),
      ),
      GoRoute(
        path: '/forgotpassword',
        name: 'forgotpassword',
        builder: (context, state) => const RentalForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/createnewpassword',
        name: 'createnewpassword',
        builder: (context, state) => const CreateNewPasswordScreen(),
      ),
      GoRoute(
        path: '/bottomnav',
        name: 'bottomnav',
        builder: (context, state) => const BottomNavShell(),
      ),
    ],
  );
}
