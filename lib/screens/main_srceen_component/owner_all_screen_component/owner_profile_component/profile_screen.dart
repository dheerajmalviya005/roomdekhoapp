import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:material_design_icons_flutter/material_design_icons_flutter.dart";
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/room_service.dart';
import '../../../../services/auth_service.dart'; // ✅ AuthService import

const double TAB_BAR_SPACE = 90; // like RN verticalScale(90)

/* ---------------- Theme Tokens (same props like your RN T) ---------------- */

class Tokens {
  final Color background;
  final Color elevated;
  final Color surface;
  final Color border;

  final Color primary;
  final Color onPrimary;

  final Color onBackground;
  final Color muted;

  final Color disabled;
  final Color error;

  // used by ConfirmModal toneMap
  final Color info;
  final Color warning;

  const Tokens({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
    required this.muted,
    required this.disabled,
    required this.error,
    required this.info,
    required this.warning,
  });

  // ✅ BACKGROUND #FFFF (pure white) as you asked
  factory Tokens.light() => Tokens(
    background: const Color(0xFFFFFFFF),
    elevated: Colors.white,
    surface: const Color(0xFFF6F7FB),
    border: const Color(0xFFE5E7EB),
    primary: const Color(0xFF667EEA),
    onPrimary: Colors.white,
    onBackground: const Color(0xFF0F172A),
    muted: const Color(0xFF64748B),
    disabled: const Color(0xFFCBD5E1),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF3B82F6),
    warning: const Color(0xFFF59E0B),
  );

  factory Tokens.dark() => Tokens(
    background: const Color(0xFF0B1220),
    elevated: const Color(0xFF111B33),
    surface: const Color(0xFF0F172A),
    border: Colors.white.withOpacity(0.10),
    primary: const Color(0xFF667EEA),
    onPrimary: Colors.white,
    onBackground: const Color(0xFFE5E7EB),
    muted: const Color(0xFF94A3B8),
    disabled: Colors.white.withOpacity(0.12),
    error: const Color(0xFFEF4444),
    info: const Color(0xFF3B82F6),
    warning: const Color(0xFFF59E0B),
  );
}

/* ---------------- Screen ---------------- */

class ProfileScreenFlutter extends StatefulWidget {
  const ProfileScreenFlutter({super.key});

  @override
  State<ProfileScreenFlutter> createState() => _ProfileScreenFlutterState();
}

class _ProfileScreenFlutterState extends State<ProfileScreenFlutter> {
  // change this to your theme provider
  final Tokens T = Tokens.light();
  final String themeName = "light"; // "dark" / "light"
  final ImagePicker _picker = ImagePicker();

  bool pickerOpen = false;
  bool showLogout = false;
  bool showDelete = false;
  bool showDeleteAvatar = false;
  bool notif = true;

  // Loading state
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  // User data from API
  Map<String, dynamic> user = {
    "name": "",
    "role": "",
    "email": "",
    "phone": "",
    "avatar": null,
  };

  final Map<String, int> stats = {"listings": 0, "published": 0, "drafts": 0};

  @override
  void initState() {
    super.initState();

    // ✅ First try to restore user session
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('\n🔄 Profile Screen: Checking authentication status...');

      // Try to restore user from storage first
      final restored = await AuthService.restoreUser();

      if (restored) {
        print('✅ User restored from storage');
        // Then fetch user data from API
        await _fetchUserData();
      } else {
        print('⚠️ No user session found, checking auth...');
        final ok = await isAuthenticated();
        if (!mounted) return;
        if (!ok) {
          print('❌ Not authenticated, redirecting to login');
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil("LoginAuthentication", (_) => false);
        } else {
          // If authenticated, fetch user data
          await _fetchUserData();
        }
      }
    });
  }

  // ✅ Fetch user data from API
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Get access token from AuthService
      final accessToken = AuthService.getCurrentToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception("No access token found");
      }

      print(
        '🔑 Fetching user data with token: ${AuthService.maskToken(accessToken)}',
      );

      // Call API
      final userData = await RoomService.getMe(accessToken: accessToken);

      // Debug print to see API response
      print('📦 API Response: $userData');
      print('📸 Profile Image URL from API: ${userData["profile_image_url"]}');

      // Update user data
      if (mounted) {
        setState(() {
          // Combine first_name and last_name
          final firstName = userData["first_name"] ?? "";
          final lastName = userData["last_name"] ?? "";
          final fullName = "$firstName $lastName".trim();

          user = {
            "name": fullName.isNotEmpty ? fullName : "User",
            "role": _getUserRoleFromToken(), // ✅ Token से role लें
            "email": userData["email"] ?? "",
            "phone": userData["phone"] ?? "",
            "avatar": _getFullImageUrl(
              userData["profile_image_url"],
            ), // ✅ Convert to full URL
          };

          // Update stats if available in API response
          stats["listings"] = userData["total_listings"] ?? 0;
          stats["published"] = userData["published_listings"] ?? 0;
          stats["drafts"] = userData["draft_listings"] ?? 0;

          isLoading = false;
        });
      }

      print('✅ User data fetched successfully');
      print('   Name: ${user["name"]}');
      print('   Role from token: ${user["role"]}');
      print('   Email: ${user["email"]}');
      print('   Phone: ${user["phone"]}');
      print('   Avatar URL: ${user["avatar"]}');
    } catch (e) {
      print('❌ Error fetching user data: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
      }

      // Show error
      _showErrorSnackbar("Failed to load profile data");
    }
  }

  String? _getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return null;
    }

    if (relativeUrl.startsWith('http://') ||
        relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }

    if (relativeUrl.startsWith('/public/')) {
      final path = relativeUrl.startsWith('/')
          ? relativeUrl.substring(1)
          : relativeUrl;
      return 'https://room.24x7techelp.com/$path';
    }

    return 'https://room.24x7techelp.com/public/users/${AuthService.getUserId()}/avatar/$relativeUrl';
  }

  String _getUserRoleFromToken() {
    final role = AuthService.getUserRole();
    if (role != null) {
      return role;
    }

    final payload = AuthService.getCurrentPayload();
    if (payload != null && payload.containsKey('role')) {
      return payload['role'].toString();
    }

    return "User";
  }

  // ✅ Upload avatar function
  Future<void> onUploadAvatar() async {
    // Show photo picker sheet
    setState(() => pickerOpen = true);
  }

  // ✅ Pick image function (camera/gallery se)
  Future<void> pickImage(String source) async {
    try {
      print('📸 Picking image from: $source');

      final XFile? pickedFile;

      if (source == "camera") {
        pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
          preferredCameraDevice: CameraDevice.front,
        );
      } else {
        pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 800,
          maxHeight: 800,
        );
      }

      if (pickedFile != null) {
        print('✅ Image picked successfully');
        print('   File path: ${pickedFile.path}');
        print('   File name: ${pickedFile.name}');

        // Close the picker sheet
        setState(() => pickerOpen = false);

        // Upload to API
        await _uploadAvatarToApi(File(pickedFile.path));
      } else {
        print('⚠️ No image selected');
        setState(() => pickerOpen = false);
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      setState(() => pickerOpen = false);
      _showErrorSnackbar("Failed to pick image: $e");
    }
  }

  // ✅ Delete avatar handler
  void onDeleteAvatar() {
    if (user["avatar"] != null) {
      // Show confirmation modal
      setState(() {
        showDeleteAvatar = true;
      });
    } else {
      _showErrorSnackbar("No profile picture to delete");
    }
  }

  // ✅ Actual delete avatar function
  Future<void> _deleteAvatarFromApi() async {
    try {
      print('🗑️ Starting avatar delete from API...');

      // Get access token
      final accessToken = AuthService.getCurrentToken();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorSnackbar("Please login again");
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: T.elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: T.primary),
              const SizedBox(height: 16),
              Text(
                "Deleting profile picture...",
                style: TextStyle(
                  color: T.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait",
                style: TextStyle(color: T.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );

      // Call delete API
      final result = await RoomService.deleteAvatar(accessToken: accessToken);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Check result
      if (result['success'] == true) {
        print('✅ Avatar delete successful!');
        print('   Full response: $result');

        // Show success message
        _showSuccessSnackbar("Profile picture deleted successfully!");

        // Clear avatar in local state
        setState(() {
          user = {...user, "avatar": null};
        });

        // Refresh user data
        await _fetchUserData();
      } else {
        print('❌ Avatar delete failed');
        print('   Error: ${result['message']}');
        print('   Response data: ${result['response_data']}');

        _showErrorSnackbar("Failed to delete: ${result['message']}");
      }
    } catch (e) {
      print('❌ Error in _deleteAvatarFromApi: $e');
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackbar("Delete failed: $e");
      }
    }
  }

  // ✅ Actual API upload function
  Future<void> _uploadAvatarToApi(File imageFile) async {
    try {
      print('🔄 Starting avatar upload to API...');

      // Get access token
      final accessToken = AuthService.getCurrentToken();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorSnackbar("Please login again");
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: T.elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: T.primary),
              const SizedBox(height: 16),
              Text(
                "Uploading profile picture...",
                style: TextStyle(
                  color: T.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait",
                style: TextStyle(color: T.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );

      // Call upload API
      final result = await RoomService.uploadAvatar(
        imageFile: imageFile,
        accessToken: accessToken,
        onProgress: (progress) {
          print('📊 Upload progress: $progress%');
        },
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Check result
      if (result['success'] == true) {
        print('🎉 Avatar upload successful!');
        print('   Full response: $result');

        // Show success message
        _showSuccessSnackbar("Profile picture updated successfully!");

        // Refresh user data
        await _fetchUserData();

        // Print updated user info
        final userData = await RoomService.getMe(accessToken: accessToken);
        print('🔄 Updated user profile: $userData');
      } else {
        print('❌ Avatar upload failed');
        print('   Error: ${result['message']}');
        print('   Response data: ${result["response_data"]}');

        _showErrorSnackbar("Failed to upload: ${result['message']}");
      }
    } catch (e) {
      print('❌ Error in _uploadAvatarToApi: $e');
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackbar("Upload failed: $e");
      }
    }
  }

  // ✅ Success snackbar function
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ✅ Logout handler
  void onLogout() {
    setState(() {
      showLogout = true;
    });
  }

  void onDelete() => setState(() => showDelete = true);

  void _alert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(msg)),
    );
  }

  // ✅ Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: T.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barStyle = themeName == "dark"
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barStyle.copyWith(
        statusBarColor: themeName == "dark"
            ? const Color(0xFF1A1A2E)
            : const Color(0xFF667EEA),
      ),
      child: Scaffold(
        backgroundColor: T.background, // ✅ white
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(T: T),

                  // Show loading indicator
                  if (isLoading)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: T.primary),
                            const SizedBox(height: 16),
                            Text(
                              "Loading profile...",
                              style: TextStyle(color: T.muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Show error
                  else if (hasError)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              MdiIcons.alertCircleOutline,
                              size: 48,
                              color: T.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Failed to load profile",
                              style: TextStyle(
                                color: T.onBackground,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: T.muted, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: T.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                "Retry",
                                style: TextStyle(
                                  color: T.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Show content
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ).copyWith(bottom: TAB_BAR_SPACE + 16),
                        child: Column(
                          children: [
                            // Profile card
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(
                                16,
                              ).copyWith(top: 20, bottom: 20),
                              decoration: BoxDecoration(
                                color: T.elevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: T.border, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF667EEA,
                                    ).withOpacity(0.12),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // ✅ AvatarBlock with imageUrl and userName
                                  _AvatarBlock(
                                    T: T,
                                    imageUrl: user["avatar"]
                                        ?.toString(), // ✅ String URL
                                    userName:
                                        user["name"]?.toString() ??
                                        "User", // ✅ User name for letter
                                    onTapCamera: onUploadAvatar,
                                  ),

                                  const SizedBox(height: 12),
                                  Text(
                                    (user["name"] ?? "User").toString(),
                                    style: TextStyle(
                                      color: T.onBackground,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      letterSpacing: 0.3,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: themeName == "dark"
                                            ? const [
                                                Color(0xFF2D2D44),
                                                Color(0xFF1A1A2E),
                                              ]
                                            : const [
                                                Color(0xFFF0F4FF),
                                                Color(0xFFE8ECFF),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: T.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF667EEA,
                                          ).withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          MdiIcons.shieldAccount,
                                          size: 14,
                                          color: const Color(0xFF667EEA),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          (user["role"] ?? "User").toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF667EEA),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if ((user["email"] ?? "")
                                          .toString()
                                          .isNotEmpty)
                                        RowIconText(
                                          T: T,
                                          icon: MdiIcons.emailOutline,
                                          text: user["email"],
                                        ),
                                      if ((user["email"] ?? "")
                                          .toString()
                                          .isNotEmpty)
                                        const SizedBox(width: 10),
                                      if ((user["phone"] ?? "")
                                          .toString()
                                          .isNotEmpty)
                                        RowIconText(
                                          T: T,
                                          icon: MdiIcons.phone,
                                          text: user["phone"],
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // KPI row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Kpi(
                                          C: T,
                                          icon: MdiIcons.homeAnalytics,
                                          label: "Listings",
                                          value: stats["listings"] ?? 0,
                                          tint: const Color(0xFF667EEA),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Kpi(
                                          C: T,
                                          icon: MdiIcons.checkDecagram,
                                          label: "Published",
                                          value: stats["published"] ?? 0,
                                          tint: const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Kpi(
                                          C: T,
                                          icon: MdiIcons.fileDocumentEdit,
                                          label: "Drafts",
                                          value: stats["drafts"] ?? 0,
                                          tint: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Account
                            Section(
                              title: "Account",
                              T: T,
                              child: Column(
                                children: [
                                  // ✅ gap 5 + radius 8 applied inside ListItem
                                  ListItem(
                                    T: T,
                                    icon: MdiIcons.pencil,
                                    label: "Edit profile",
                                    onTap: () => context.push('/editProfile'),
                                  ),
                                  const SizedBox(height: 5),
                                  ListItem(
                                    T: T,
                                    icon: MdiIcons.formTextboxPassword,
                                    label: "Change password",
                                    onTap: () =>
                                        context.push('/changePassword'),
                                    last: true,
                                  ),
                                ],
                              ),
                            ),

                            // Preferences
                            Section(
                              title: "Preferences",
                              T: T,
                              child: Column(
                                children: [
                                  ListItem(
                                    T: T,
                                    icon: MdiIcons.bellOutline,
                                    label: "Notifications",
                                    right: Switch(
                                      value: notif,
                                      onChanged: (v) =>
                                          setState(() => notif = v),
                                      thumbColor: WidgetStateProperty.all(
                                        notif ? T.onPrimary : null,
                                      ),
                                      trackColor:
                                          WidgetStateProperty.resolveWith((_) {
                                            return notif
                                                ? T.primary
                                                : T.disabled;
                                          }),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ListItem(
                                    T: T,
                                    icon: MdiIcons.weatherNight,
                                    label: "Appearance",
                                    sub: themeName == "dark" ? "Dark" : "Light",
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed("Appearance"),
                                  ),
                                  const SizedBox(height: 5),
                                  ListItem(
                                    T: T,
                                    icon: MdiIcons.translate,
                                    label: "Language",
                                    sub: "English (India)",
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed("Language"),
                                    last: true,
                                  ),
                                ],
                              ),
                            ),

                            // danger card
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: T.elevated,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: T.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _DangerButton(
                                    T: T,
                                    icon: MdiIcons.logout,
                                    label: "Logout",
                                    onTap: onLogout,
                                  ),
                                  const SizedBox(height: 8),
                                  _DangerButton(
                                    T: T,
                                    icon: MdiIcons.deleteOutline,
                                    label: "Delete account",
                                    onTap: onDelete,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // ✅ Photo sheet (animated) WITH DELETE OPTION
              PhotoSourceSheet(
                open: pickerOpen,
                T: T,
                hasAvatar: user["avatar"] != null, // ✅ Check if avatar exists
                onClose: () => setState(() => pickerOpen = false),
                onPickCamera: () {
                  setState(() => pickerOpen = false);
                  pickImage("camera");
                },
                onPickGallery: () {
                  setState(() => pickerOpen = false);
                  pickImage("gallery");
                },
                onDeleteAvatar: () {
                  setState(() => pickerOpen = false);
                  onDeleteAvatar(); // ✅ This will trigger the ConfirmModal
                },
              ),

              // ✅ Confirm modal for delete avatar
              ConfirmModal(
                open: showDeleteAvatar,
                T: T,
                icon: MdiIcons.deleteOutline,
                title: "Remove Profile Picture?",
                message:
                    "Your profile picture will be removed. You can upload a new one anytime.",
                confirmLabel: "Remove",
                confirmTone: "danger",
                onCancel: () => setState(() => showDeleteAvatar = false),
                onConfirm: () async {
                  setState(() => showDeleteAvatar = false);
                  await _deleteAvatarFromApi();
                },
              ),

              // Confirm modal for logout
              ConfirmModal(
                open: showLogout,
                T: T,
                icon: MdiIcons.logout,
                title: "Logout?",
                message: "You'll need to sign in again to access your account.",
                confirmLabel: "Logout",
                confirmTone: "warning",
                onCancel: () => setState(() => showLogout = false),
                onConfirm: () async {
                  setState(() => showLogout = false);
                  // Print current token from AuthService
                  final token = AuthService.getCurrentToken();
                  final tokenType = AuthService.getCurrentTokenType();
                  final payload = AuthService.getCurrentPayload();

                  if (payload != null) {
                    print('\n📋 Current Payload:');
                    payload.forEach((key, value) {
                      print('   $key: $value');
                    });

                    // Print expiry info
                    if (payload.containsKey('exp')) {
                      final exp = payload['exp'] as int;
                      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                      final diff = exp - now;
                      final hours = diff ~/ 3600;
                      final minutes = (diff % 3600) ~/ 60;
                      print('   ⏰ Expires in: ${hours}h ${minutes}m');
                    }
                  }

                  try {
                    final sp = await SharedPreferences.getInstance();
                    final spToken = sp.getString("token");
                    final spTokenType = sp.getString("token_type");
                  } catch (e) {
                    print('❌ Error accessing SharedPreferences: $e');
                  }

                  try {
                    await AuthService.logoutUser();
                    setState(() {
                      user = {
                        "name": "",
                        "role": "",
                        "email": "",
                        "phone": "",
                        "avatar": null,
                      };
                      stats.clear();
                    });
                  } catch (e) {
                    _showErrorSnackbar("Logout failed: $e");
                    return;
                  }

                  if (!mounted) return;
                  await Future.delayed(const Duration(milliseconds: 100));
                  try {
                    context.go('/login');
                  } catch (e) {
                    try {
                      context.push('/login');
                    } catch (e2) {
                      try {
                        final possibleRoutes = ['/login'];

                        for (final route in possibleRoutes) {
                          try {
                            context.go(route);
                            break;
                          } catch (_) {
                            continue;
                          }
                        }
                      } catch (e3) {
                        _showErrorSnackbar(
                          "Cannot navigate. Please restart app.",
                        );
                      }
                    }
                  }
                },
              ),

              // Confirm modal for delete account
              ConfirmModal(
                open: showDelete,
                T: T,
                icon: MdiIcons.deleteOutline,
                title: "Delete account?",
                message:
                    "This permanently removes your account and all data. This action cannot be undone.",
                confirmLabel: "Delete",
                confirmTone: "danger",
                onCancel: () => setState(() => showDelete = false),
                onConfirm: () async {
                  setState(() => showDelete = false);
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchUserData,
          backgroundColor: T.primary,
          child: Icon(MdiIcons.refresh, color: T.onPrimary),
        ),
      ),
    );
  }
}

/* ---------------- Widgets ---------------- */

class _Header extends StatelessWidget {
  const _Header({required this.T});
  final Tokens T;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 36),
          Text(
            "Profile",
            style: TextStyle(
              color: T.onBackground,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.T,
    required this.imageUrl,
    required this.userName,
    required this.onTapCamera,
  });

  final Tokens T;
  final String? imageUrl;
  final String userName;
  final VoidCallback onTapCamera;

  @override
  Widget build(BuildContext context) {
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glow (LinearGradient overlay)
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFFF093FB),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Avatar - Show image if available, otherwise show letter
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 3),
                color: imageUrl == null
                    ? const Color(0xFF667EEA)
                    : Colors.transparent,
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          // Camera button
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onTapCamera,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.40),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RowIconText extends StatelessWidget {
  const RowIconText({
    super.key,
    required this.T,
    required this.icon,
    required this.text,
  });
  final Tokens T;
  final IconData icon;
  final dynamic text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: T.muted),
        const SizedBox(width: 6),
        SizedBox(
          width: 140,
          child: Text(
            (text ?? "").toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: T.onBackground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class Kpi extends StatelessWidget {
  const Kpi({
    super.key,
    required this.C,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final Tokens C;
  final IconData icon;
  final String label;
  final int value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
        boxShadow: [
          BoxShadow(
            color: tint.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: 8),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: C.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: C.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.T,
    required this.child,
  });
  final String title;
  final Tokens T;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: T.onBackground,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: T.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.T,
    required this.icon,
    required this.label,
    this.sub,
    this.right,
    this.onTap,
    this.last = false,
  });

  final Tokens T;
  final IconData icon;
  final String label;
  final String? sub;
  final Widget? right;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: T.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: T.border),
                ),
                child: Icon(icon, size: 18, color: T.onBackground),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: T.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if ((sub ?? "").isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        style: TextStyle(color: T.muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (right != null)
                right!
              else
                Icon(MdiIcons.chevronRight, color: T.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.T,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Tokens T;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: T.border),
          boxShadow: [
            BoxShadow(
              color: T.error.withOpacity(0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: T.error),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: T.error,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- PhotoSourceSheet WITH DELETE OPTION ---------------- */

class PhotoSourceSheet extends StatefulWidget {
  const PhotoSourceSheet({
    super.key,
    required this.open,
    required this.onClose,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onDeleteAvatar,
    required this.T,
    required this.hasAvatar,
  });

  final bool open;
  final VoidCallback onClose;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onDeleteAvatar;
  final Tokens T;
  final bool hasAvatar;

  @override
  State<PhotoSourceSheet> createState() => _PhotoSourceSheetState();
}

class _PhotoSourceSheetState extends State<PhotoSourceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;
  late final Animation<double> fade;
  late final Animation<Offset> slide;
  late final Animation<double> scale;

  static const double SHEET_LIFT = 92;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    fade = CurvedAnimation(parent: c, curve: Curves.easeOutQuad);

    scale = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack));

    slide = Tween<Offset>(
      begin: const Offset(0, 1.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant PhotoSourceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open) {
      c.forward();
    } else {
      c.reverse();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();
    final T = widget.T;

    final double safeBottom = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Backdrop
        FadeTransition(
          opacity: fade,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withOpacity(0.38)),
          ),
        ),

        // Sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      0,
                      14,
                      SHEET_LIFT + safeBottom,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: T.elevated,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: T.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle (center)
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 46,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: T.border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),

                          // Title + Close
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Profile Picture",
                                      style: TextStyle(
                                        color: T.onBackground,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Choose an action",
                                      style: TextStyle(
                                        color: T.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: widget.onClose,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: T.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: T.border),
                                  ),
                                  child: Icon(
                                    MdiIcons.close,
                                    size: 18,
                                    color: T.onBackground,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ✅ Camera option
                          _PickerRow(
                            T: T,
                            icon: MdiIcons.cameraOutline,
                            title: "Take Photo",
                            subtitle: "Use camera to take a new photo",
                            onTap: widget.onPickCamera,
                          ),
                          const SizedBox(height: 10),

                          // ✅ Gallery option
                          _PickerRow(
                            T: T,
                            icon: MdiIcons.imageMultipleOutline,
                            title: "Choose from Gallery",
                            subtitle: "Select photo from your device",
                            onTap: widget.onPickGallery,
                          ),

                          // ✅ Delete option (only show if avatar exists)
                          if (widget.hasAvatar) ...[
                            const SizedBox(height: 10),
                            _DeleteRow(
                              T: T,
                              icon: MdiIcons.deleteOutline,
                              title: "Remove Photo",
                              subtitle: "Delete current profile picture",
                              onTap: widget.onDeleteAvatar,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.T,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Tokens T;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: T.border),
          ),
          child: Row(
            children: [
              // icon square
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: T.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: T.border),
                ),
                child: Icon(icon, size: 18, color: T.onBackground),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: T.onBackground,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: T.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(MdiIcons.chevronRight, color: T.muted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteRow extends StatelessWidget {
  const _DeleteRow({
    required this.T,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Tokens T;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: T.error.withOpacity(0.3)),
            color: T.error.withOpacity(0.05),
          ),
          child: Row(
            children: [
              // icon square (with error color)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: T.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: T.error.withOpacity(0.3)),
                ),
                child: Icon(icon, size: 18, color: T.error),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: T.error,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: T.error.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(MdiIcons.chevronRight, color: T.error, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- ConfirmModal ---------------- */

class ConfirmModal extends StatefulWidget {
  const ConfirmModal({
    super.key,
    required this.open,
    required this.onCancel,
    required this.onConfirm,
    required this.T,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmTone,
    this.cancelLabel = "Cancel",
  });

  final bool open;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;
  final Tokens T;
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final String confirmTone; // primary/info/warning/danger

  @override
  State<ConfirmModal> createState() => _ConfirmModalState();
}

class _ConfirmModalState extends State<ConfirmModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;
  late final Animation<double> fade;
  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    fade = CurvedAnimation(parent: c, curve: Curves.easeOut);
    scale = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant ConfirmModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open) {
      c.forward();
    } else {
      c.reset();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    final T = widget.T;

    final toneMap = {
      "primary": {"bg": T.primary, "fg": T.onPrimary, "bd": T.primary},
      "info": {"bg": T.info, "fg": T.onPrimary, "bd": T.info},
      "warning": {"bg": T.warning, "fg": T.onPrimary, "bd": T.warning},
      "danger": {"bg": T.error, "fg": T.onPrimary, "bd": T.error},
    };
    final tone = toneMap[widget.confirmTone] ?? toneMap["primary"]!;

    return Stack(
      children: [
        FadeTransition(
          opacity: fade,
          child: GestureDetector(
            onTap: widget.onCancel,
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: T.elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: T.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: T.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: T.border),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: tone["bg"] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: T.onBackground,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.message.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: T.muted, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: widget.onCancel,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: T.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: T.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  MdiIcons.close,
                                  size: 16,
                                  color: T.onBackground,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.cancelLabel,
                                  style: TextStyle(
                                    color: T.onBackground,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            await widget.onConfirm();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: tone["bg"] as Color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tone["bd"] as Color),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  MdiIcons.check,
                                  size: 16,
                                  color: tone["fg"] as Color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.confirmLabel,
                                  style: TextStyle(
                                    color: tone["fg"] as Color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- Placeholders ---------------- */

Future<bool> isAuthenticated() async {
  return await AuthService.isAuthenticated();
}

Future<void> logoutUser() async {
  await AuthService.logoutUser();
}
