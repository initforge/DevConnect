/// API Endpoints - Centralized for consistency
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Users
  static const String users = '/api/users';
  static const String usersSearch = '/api/users/search';
  static const String userById = '/api/users/:id';
  static const String userFollow = '/api/users/:id/follow';
  static const String userRepos = '/api/users/:id/repos';

  // Posts
  static const String posts = '/api/posts';
  static const String postById = '/api/posts/:id';
  static const String postLike = '/api/posts/:id/like';
  static const String postBookmark = '/api/posts/:id/bookmark';
  static const String postView = '/api/posts/:id/view';
  static const String postComments = '/api/posts/:id/comments';
  static const String postBookmarked = '/api/posts/bookmarked';

  // Feed types
  static const String feedForYou = '/api/posts?type=foryou';
  static const String feedFollowing = '/api/posts?type=following';
  static const String feedTrending = '/api/posts?type=trending';

  // Comments
  static const String commentById = '/api/posts/:postId/comments/:id';
  static const String commentVote = '/api/comments/:id/vote';

  // Chat
  static const String conversations = '/api/conversations';
  static const String conversationMessages = '/api/conversations/:id/messages';
  static const String conversationRead = '/api/conversations/:id/read';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String notificationsReadAll = '/api/notifications/read-all';
  static const String notificationRead = '/api/notifications/:id/read';

  // Projects
  static const String projects = '/api/projects';
  static const String projectById = '/api/projects/:id';
  static const String projectJoin = '/api/projects/:id/join';

  // Jobs
  static const String jobs = '/api/jobs';
  static const String jobById = '/api/jobs/:id';
  static const String jobApply = '/api/jobs/:id/apply';

  // Leaderboard
  static const String leaderboard = '/api/leaderboard';

  // Analytics
  static const String analytics = '/api/analytics';
  static const String analyticsMe = '/api/analytics/me';

  // AI Features
  static const String aiCodeReview = '/api/ai/code-review';
  static const String aiExplain = '/api/ai/explain';
  static const String aiMentorshipMatch = '/api/ai/mentorship-match';

  // Playground
  static const String codeRun = '/api/code/run';

  // Media
  static const String mediaUpload = '/api/media/upload';
  static const String mediaById = '/api/media/:id';
}
