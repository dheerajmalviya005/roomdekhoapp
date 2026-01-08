import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
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
import '../screens/main_srceen_component/owner_all_screen_component/owner_bottom_navigation_component/bottom_nav_shell.dart';
import '../screens/main_srceen_component/owner_all_screen_component/home_screen_comp_owner/create_&_edit_component/create_room_screen.dart';
import '../screens/main_srceen_component/owner_all_screen_component/home_screen_comp_owner/create_&_edit_component/edit_room_screen.dart';
import '../screens/main_srceen_component/owner_all_screen_component/owner_profile_component/onwer_all_edit_compo/edit_profile_screen.dart';
import '../screens/main_srceen_component/owner_all_screen_component/owner_profile_component/onwer_all_edit_compo/change_password_screen_flutter.dart';
import '../services/auth_service.dart';
import '../screens/main_srceen_component/common_faq_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ✅ Splash Screen - ONLY ONE SPLASH ROUTE
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ✅ Login Screen with auto-redirect
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const RentalAnimatedLogin(),
        redirect: (context, state) async {
          print('\n🔍 LOGIN ROUTE REDIRECT CHECK');
          // If user is already logged in, redirect based on role
          final isAuth = await AuthService.isAuthenticated();
          if (isAuth) {
            final role = AuthService.getUserRole();
            print('✅ User already logged in as: $role');
            if (role == 'OWNER') {
              return '/RenterTabs';
            } else if (role == 'TENANT') {
              return '/bottomnav';
            }
          }
          print('🔐 No user logged in, showing login screen');
          return null; // Show login screen
        },
      ),

      // ✅ Signup Screen
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpAuthenticationScreen(),
      ),

      // ✅ Forgot Password Screen
      GoRoute(
        path: '/forgotpassword',
        name: 'forgotpassword',
        builder: (context, state) => const RentalForgotPasswordScreen(),
      ),

      // ✅ Create New Password Screen
      GoRoute(
        path: '/createnewpassword',
        name: 'createnewpassword',
        builder: (context, state) => const CreateNewPasswordScreen(),
      ),

      // ✅ TENANT Dashboard (bottomnav)
      GoRoute(
        path: '/bottomnav',
        name: 'bottomnav',
        builder: (context, state) =>
            const BottomNavShell(), // ✅ Verify this exists
      ),

      // ✅ Chat Screen
      GoRoute(
        name: 'chat',
        path: '/chat',
        builder: (context, state) => const ChatScreenFlutter(),
      ),

      // ✅ Property Details Screen
      GoRoute(
        path: '/propertydetails',
        name: 'propertydetails',
        builder: (context, state) => const PropertyDetailScreenFlutter(),
      ),

      // ✅ Offers/Properties Screen
      GoRoute(
        path: '/offers',
        name: 'offers',
        builder: (context, state) => const AllPropertiesScreenFlutter(),
      ),

      // ✅ Notification Screen
      GoRoute(
        path: '/notification',
        name: 'notification',
        builder: (context, state) => const NotificationCenterScreen(),
      ),

      // ✅ OWNER Dashboard (RenterTabs)
      GoRoute(
        path: '/RenterTabs',
        name: 'RenterTabs',
        builder: (context, state) => const RenterTabs(),
        redirect: (context, state) async {
          print('\n🔍 RENTERTABS ROUTE ACCESS CHECK');
          final isAuth = await AuthService.isAuthenticated();
          if (!isAuth) {
            print('❌ User not authenticated, redirecting to login');
            return '/login';
          }

          final role = AuthService.getUserRole();
          if (role != 'OWNER') {
            print('❌ User role ($role) not OWNER, redirecting to login');
            return '/login';
          }
          print('✅ OWNER access granted');
          return null;
        },
      ),

      // ✅ Create Room Screen
      GoRoute(
        path: '/CreteateRoom',
        name: 'CreteateRoom',
        builder: (context, state) => const CreateRoomScreen(),
      ),

      // ✅ Edit Room Screen
      GoRoute(
        path: '/editRoom/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          final roomId =
              extra?["roomId"]?.toString() ?? state.pathParameters["id"];
          final accessToken = extra?["accessToken"]?.toString();
          final prefill = extra?["prefill"] as Map<String, dynamic>?;

          return EditRoomScreenFlutter(
            roomId: roomId,
            accessToken: accessToken,
            prefill: prefill,
          );
        },
      ),

      // ✅ Edit Profile Screen
      GoRoute(
        path: '/editProfile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreenFlutter(),
      ),

      // ✅ Change Password Screen
      GoRoute(
        path: '/changePassword',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreenFlutter(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FaqScreen(),
      ),
    ],

    redirect: (context, state) {
      final location = state.uri.toString();
      print('\n🌐 GLOBAL ROUTE CHECK: $location');

      if (location == '/') {
        print('📍 Root access, redirecting to splash');
        return '/splash';
      }

      return null;
    },

    // ✅ Error page for debugging
    errorBuilder: (context, state) {
      print('\n❌ ROUTE ERROR: ${state.error}');
      print('📍 Location: ${state.uri.toString()}');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Route Error: ${state.error}'),
              Text('Location: ${state.uri.toString()}'),
              ElevatedButton(
                onPressed: () => context.go('/splash'),
                child: const Text('Go to Splash'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
