class API {
  static const String BASE_URL = "https://room.24x7techelp.com";

  // 🔐 AUTH
  static const String LOGIN = "/auth/login/";
  static const String REGISTER = "/auth/register/";
  static const String LOGOUT = "/auth/logout";

  // 🏠 ROOMS
  static const String ROOMS = "/rooms/";
  static const String CREATE_ROOM = "/rooms/"; // ✅ backward compatible
  static const String OWNER_ROOMS = "/rooms/owner";
  static const String SUGGEST = "/suggest";

  // ✅ ROOM BY ID
  static String getRoomByIdUrl(String id) => "/rooms/$id";
  static String getUpdateRoomUrl(String id) => "/rooms/$id";
  static String getDeleteRoomUrl(String id) => "/rooms/$id";

  // ✅ IMAGES
  static String getRoomImagesUrl(String roomId) => "/rooms/$roomId/images";
  static String getRoomImageByIdUrl(String roomId, String imageNo) =>
      "/rooms/$roomId/images/$imageNo";
  static String getUpdateRoomImageUrl(String roomId, String imageNo) =>
      "/rooms/$roomId/images/$imageNo";
  static String getDeleteRoomImageUrl(String roomId, String imageNo) =>
      "/rooms/$roomId/images/$imageNo";

  // ✅ VIDEO
  static String getRoomVideoUrl(String roomId) => "/rooms/$roomId/video";
  static String getDeleteRoomVideoUrl(String roomId) => "/rooms/$roomId/video";

  // 👤 USER
  static const String USER_ME = "/users/me";
  static const String USER_AVATAR = "/users/me/avatar";
  static const String USER_AVATAR_DELETE = "/users/me/avatar";

  // 📌 SUPPORT / FAQ
  static const String SUPPORT_PUBLIC = "/support/public";
  static const String FAQ_PUBLIC = "/faq/public";
}
