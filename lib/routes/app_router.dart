import 'package:go_router/go_router.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../screens/authentication/rental_animated_login.dart';
import '../screens/authentication/sign_up_authentication.dart';
import '../screens/authentication/rental_forgot_password_screen.dart';
import '../screens/authentication/create_new_password_screen.dart';
import '../screens/main_srceen_component/renter_all_screen_component/renter_bottom_navigation_component/bottom_nav_shell.dart';
import '../screens/main_srceen_component/renter_all_screen_component/chat_screen_componenet/chat_screen.dart';
import '../screens/main_srceen_component/renter_all_screen_component/home_screen_component/home_screen_sub_component/property_detail_screen.dart';
import '../screens/main_srceen_component/renter_all_screen_component/home_screen_component/home_screen_sub_component/all_properties_screen.dart';
import '../screens/main_srceen_component/renter_all_screen_component/notification_screen_component/notification_center_screen.dart';

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
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreenFlutter(),
      ),
      GoRoute(
        path: '/propertydetails',
        name: 'propertydetails',
        builder: (context, state) => const PropertyDetailScreenFlutter(),
      ),
      GoRoute(
        path: '/offers',
        name: 'offers',
        builder: (context, state) => const AllPropertiesScreenFlutter(),
      ),
      GoRoute(
        path: '/notification',
        name: 'notification',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
  );
}
