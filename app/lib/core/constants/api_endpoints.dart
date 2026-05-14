/// API Endpoints - Centralized for consistency
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Users
  static const String users = '/users';
  static const String usersMe = '/users/me';
  static const String usersSearch = '/users/search';
  static const String userById = '/users/:id';
  static const String userFollow = '/users/:id/follow';
  static const String userRepos = '/users/:id/repos';

  // Posts
  static const String posts = '/posts';
  static const String postById = '/posts/:id';
  static const String postLike = '/posts/:id/like';
  static const String postBookmark = '/posts/:id/bookmark';
  static const String postView = '/posts/:id/view';
  static const String postComments = '/posts/:id/comments';
  static const String postBookmarked = '/posts/bookmarked';

  // Feed types
  static const String feedForYou = '/posts?type=foryou';
  static const String feedFollowing = '/posts?type=following';
  static const String feedTrending = '/posts?type=trending';

  // Comments
  static const String commentById = '/posts/:postId/comments/:id';
  static const String commentVote = '/comments/:id/vote';

  // Chat
  static const String conversations = '/conversations';
  static const String conversationMessages = '/conversations/:id/messages';
  static const String conversationRead = '/conversations/:id/read';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationRead = '/notifications/:id/read';

  // Projects
  static const String projects = '/projects';
  static const String projectById = '/projects/:id';
  static const String projectJoin = '/projects/:id/join';

  // Jobs
  static const String jobs = '/jobs';
  static const String jobById = '/jobs/:id';
  static const String jobApply = '/jobs/:id/apply';

  // Leaderboard
  static const String leaderboard = '/leaderboard';
  static const String leaderboardScoring = '/leaderboard/scoring';

  // Analytics
  static const String analytics = '/analytics';
  static const String analyticsMe = '/analytics/me';

  // AI Features
  static const String aiCodeReview = '/ai/code-review';
  static const String aiCodeReviewStream = '/ai/code-review/stream';
  static const String aiExplain = '/ai/explain';
  static const String aiExplainStream = '/ai/explain/stream';
  static const String aiMentorshipMatch = '/ai/mentorship-match';
  static const String aiMentorshipMatchStream = '/ai/mentorship-match/stream';

  // User interactions
  static const String userInteractions = '/users/me/interactions';

  // Playground
  static const String codeRun = '/code/run';

  // Media
  static const String mediaUpload = '/media/upload';
  static const String mediaById = '/media/:id';

}
