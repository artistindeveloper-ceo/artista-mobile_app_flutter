class ApiConfig {
  static const String baseUrl = 'http://43.205.146.248:8081';  // ← 9090 → 8081

  // Auth
  static const String loginUrl = '$baseUrl/api/v1/auth/login';  // ← v1 add kiya
  static const String refreshTokenUrl = '$baseUrl/api/v1/auth/refresh-token';
  // User v1 endpoints
  static const String getMeUrl = '$baseUrl/api/v1/users/me';
  static const String updateMeUrl = '$baseUrl/api/v1/users/me';
  static const String uploadProfilePhotoUrl = '$baseUrl/api/v1/users/me/profile-photo';
  static const String uploadCoverPhotoUrl = '$baseUrl/api/v1/users/me/cover-photo';
  static const String changePasswordUrl = '$baseUrl/api/v1/users/me/password';
  static const String searchUsersUrl = '$baseUrl/api/v1/users/search';


  // Posts
  static const String feedUrl = '$baseUrl/api/v1/posts/feed';
  static const String exploreUrl = '$baseUrl/api/v1/posts/explore';
  static String likePostUrl(int postId) => '$baseUrl/api/v1/posts/$postId/like';
  static String postCommentsUrl(int postId) => '$baseUrl/api/v1/posts/$postId/comments';

  static String userPostsUrl(int userId) => '$baseUrl/api/v1/posts/users/$userId';
  static String userFollowersCountUrl(int userId) => '$baseUrl/api/v1/users/$userId/followers';
  static String userFollowingCountUrl(int userId) => '$baseUrl/api/v1/users/$userId/following';

  // Follow
  static String followUserUrl(int userId) => '$baseUrl/api/v1/users/$userId/follow';
  static String unfollowUserUrl(int userId) => '$baseUrl/api/v1/users/$userId/follow';
  static String followingUrl(int userId) => '$baseUrl/api/v1/users/$userId/following';
  static String followersUrl(int userId) => '$baseUrl/api/v1/users/$userId/followers';
  static const String pendingRequestsUrl = '$baseUrl/api/v1/follow-requests/pending';
  static String acceptRequestUrl(int id) => '$baseUrl/api/v1/follow-requests/$id/accept';
  static String rejectRequestUrl(int id) => '$baseUrl/api/v1/follow-requests/$id/reject';

  // Messages
  static const String conversationsUrl = '$baseUrl/api/v1/messages/conversations';
  static String conversationMessagesUrl(int id) =>
      '$baseUrl/api/v1/messages/conversations/$id';
  static String markReadUrl(int id) =>
      '$baseUrl/api/v1/messages/conversations/$id/read';
  static String sendMessageUrl(int recipientId) =>
      '$baseUrl/api/v1/messages/users/$recipientId';

// Notifications
  static const String notificationsUrl = '$baseUrl/api/v1/notifications';
  static const String unreadCountUrl = '$baseUrl/api/v1/notifications/unread-count';
  static const String markAllReadUrl = '$baseUrl/api/v1/notifications/mark-all-read';

  // Jam Sessions
  static const String mySessionsUrl = '$baseUrl/api/v1/jam-sessions/mine';
  static const String createSessionUrl = '$baseUrl/api/v1/jam-sessions';
  static String joinSessionUrl(String code) =>
      '$baseUrl/api/v1/jam-sessions/join/$code';
  static String sessionByIdUrl(int id) => '$baseUrl/api/v1/jam-sessions/$id';
  static String sessionParticipantsUrl(int id) =>
      '$baseUrl/api/v1/jam-sessions/$id/participants';
  static String startSessionUrl(int id) =>
      '$baseUrl/api/v1/jam-sessions/$id/start';
  static String endSessionUrl(int id) =>
      '$baseUrl/api/v1/jam-sessions/$id/end';
  static String leaveSessionUrl(int id) =>
      '$baseUrl/api/v1/jam-sessions/$id/leave';

  // Username based
  static String userByUsernameUrl(String username) =>
      '$baseUrl/api/v1/users/$username';

  // Old (keep for backward compat)
  // static String userByIdUrl(int id) => '$baseUrl/api/v2/user/getById/$id';

  static String userByIdUrl(int id) => '$baseUrl/api/v1/users/$id';
  static const String createPostUrl = '$baseUrl/api/v1/posts';


  //get songs in jam session
  static const String publicSongsUrl = '$baseUrl/api/v1/songs/public';
  static const String mySongsUrl = '$baseUrl/api/v1/songs/mine';
// Instruments
  // NOTE: Swagger me ye endpoints "/api/instruments/..." dikh rahe the
  // (v1 prefix ke bina) — baaki sab APIs "/api/v1/..." use karte hain.
  // Agar backend me ye bhi v1 ke andar hai to yahan 'api/instruments'
  // ko 'api/v1/instruments' me badal dena.
  static const String allInstrumentsUrl = '$baseUrl/api/instruments';
  static String instrumentByIdUrl(int id) => '$baseUrl/api/instruments/$id';
  static String userInstrumentsUrl(int userId) =>
      '$baseUrl/api/instruments/user/$userId';
  static String searchInstrumentsUrl(String query) =>
      '$baseUrl/api/instruments/search?query=$query';
  static const String addUserInstrumentUrl =
      '$baseUrl/api/instruments/user/add';

  static const String allCategoriesUrl = '$baseUrl/api/categories';
  static String instrumentTypesByCategoryUrl(int categoryId) =>
      '$baseUrl/api/instrument-types?categoryId=$categoryId';
  static String instrumentsByTypeUrl(int typeId, {int page = 0, int size = 20}) =>
      '$baseUrl/api/instruments/by-type?typeId=$typeId&page=$page&size=$size';
}