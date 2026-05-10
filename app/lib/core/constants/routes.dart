/// DevConnect Route Constants
///
/// Use these constants instead of magic strings throughout the app.
/// This ensures consistency and makes refactoring easier.
class AppRoutes {
  AppRoutes._();

  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';

  // Main Tab Routes
  static const String home = '/home';
  static const String explore = '/explore';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Detail Routes
  static const String postDetail = '/post/:id';
  static const String chatDetail = '/chat/:id';
  static const String userProfile = '/user/:id';

  // Feature Routes
  static const String createPost = '/create-post';
  static const String projects = '/projects';
  static const String jobs = '/jobs';
  static const String leaderboard = '/leaderboard';
  static const String analytics = '/analytics';
  static const String playground = '/playground';
  static const String liveCode = '/live-code';
  static const String mentorship = '/mentorship';
  static const String settings = '/settings';
  static const String search = '/search';

  // Base segments for dynamic route building
  static const String postBase = '/post';
  static const String chatBase = '/chat';
  static const String userBase = '/user';

  // Debug Routes
  static const String shotLab = '/shot-lab';

  // Route name constants (for GoRouter navigation)
  static const String nameLogin = 'login';
  static const String nameRegister = 'register';
  static const String nameOnboarding = 'onboarding';
  static const String nameHome = 'home';
  static const String nameExplore = 'explore';
  static const String nameChatList = 'chatList';
  static const String nameNotifications = 'notifications';
  static const String nameProfile = 'profile';
  static const String namePostDetail = 'postDetail';
  static const String nameCreatePost = 'createPost';
  static const String nameChatScreen = 'chatScreen';
  static const String nameUserProfile = 'userProfile';
  static const String nameProjects = 'projects';
  static const String nameJobs = 'jobs';
  static const String nameLeaderboard = 'leaderboard';
  static const String nameAnalytics = 'analytics';
  static const String namePlayground = 'playground';
  static const String nameLiveCode = 'liveCode';
  static const String nameMentorship = 'mentorship';
  static const String nameSettings = 'settings';
  static const String nameSearch = 'search';
  static const String nameShotLab = 'shotLab';
}
