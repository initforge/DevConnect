import 'models.dart';

/// Dữ liệu bootstrap dùng để seed SQLite local-first cho app.
class SeedData {
  SeedData._();

  // ===== USERS =====
  static final users = [
    User(
      id: 'u1',
      username: 'minhdev',
      displayName: 'Minh Nguyễn',
      email: 'minh@dev.com',
      bio: 'Flutter & NestJS developer. Yêu clean code.',
      skills: ['Flutter', 'Dart', 'NestJS', 'PostgreSQL'],
      followerCount: 1250,
      followingCount: 340,
      postCount: 48,
      reputation: 3200,
      isOnline: true,
      createdAt: DateTime(2025, 1),
    ),
    User(
      id: 'u2',
      username: 'anhtran',
      displayName: 'Anh Trần',
      email: 'anh@dev.com',
      bio: 'Backend engineer. Đam mê distributed systems.',
      skills: ['Go', 'Kubernetes', 'PostgreSQL', 'Redis'],
      followerCount: 890,
      followingCount: 210,
      postCount: 35,
      reputation: 2800,
      isOnline: true,
      isMentor: true,
      createdAt: DateTime(2025, 2),
    ),
    User(
      id: 'u3',
      username: 'linhpham',
      displayName: 'Linh Phạm',
      email: 'linh@dev.com',
      bio: 'AI/ML researcher. Python, PyTorch.',
      skills: ['Python', 'PyTorch', 'TensorFlow', 'FastAPI'],
      followerCount: 2100,
      followingCount: 180,
      postCount: 62,
      reputation: 4500,
      isOnline: false,
      isMentor: true,
      createdAt: DateTime(2024, 11),
    ),
    User(
      id: 'u4',
      username: 'ducle',
      displayName: 'Đức Lê',
      email: 'duc@dev.com',
      bio: 'React & Next.js. UI/UX enthusiast.',
      skills: ['React', 'TypeScript', 'Next.js', 'Tailwind'],
      followerCount: 650,
      followingCount: 420,
      postCount: 27,
      reputation: 1800,
      isOnline: true,
      createdAt: DateTime(2025, 3),
    ),
    User(
      id: 'u5',
      username: 'thuyle',
      displayName: 'Thủy Lê',
      email: 'thuy@dev.com',
      bio: 'DevOps engineer. Docker, CI/CD, monitoring.',
      skills: ['Docker', 'AWS', 'Terraform', 'GitHub Actions'],
      followerCount: 430,
      followingCount: 150,
      postCount: 19,
      reputation: 1200,
      isOnline: false,
      createdAt: DateTime(2025, 4),
    ),
    User(
      id: 'u6',
      username: 'namvo',
      displayName: 'Nam Võ',
      email: 'nam@dev.com',
      bio: 'Mobile dev. Flutter + Swift.',
      skills: ['Flutter', 'Swift', 'Firebase', 'Dart'],
      followerCount: 780,
      followingCount: 290,
      postCount: 41,
      reputation: 2400,
      isOnline: true,
      createdAt: DateTime(2025, 1),
    ),
  ];

  static User get currentUser => users[0];

  // ===== POSTS =====
  static final posts = [
    Post(
      id: 'p1',
      author: users[0],
      title: 'Riverpod 3.0: Quản lý state đúng cách trong Flutter',
      content:
          '## Tại sao Riverpod?\n\nProvider cũ có nhiều hạn chế...\n\n```dart\nfinal counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {\n  return CounterNotifier();\n});\n```\n\nRiverpod 3.0 giới thiệu code generation giúp giảm boilerplate đáng kể.',
      type: PostType.article,
      tags: ['Flutter', 'Riverpod', 'State Management'],
      viewCount: 1240,
      likeCount: 89,
      commentCount: 23,
      bookmarkCount: 45,
      isLikedByMe: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Post(
      id: 'p2',
      author: users[1],
      title: 'Go Concurrency Pattern: Fan-Out / Fan-In',
      content:
          '```go\nfunc fanOut(ch <-chan int, n int) []<-chan int {\n  channels := make([]<-chan int, n)\n  for i := 0; i < n; i++ {\n    channels[i] = worker(ch)\n  }\n  return channels\n}\n```\n\nPattern này giúp xử lý song song hiệu quả.',
      type: PostType.snippet,
      tags: ['Go', 'Concurrency', 'Patterns'],
      viewCount: 890,
      likeCount: 67,
      commentCount: 15,
      bookmarkCount: 32,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Post(
      id: 'p3',
      author: users[2],
      title: 'TIL: PyTorch 2.0 compile() tăng tốc 2x',
      content:
          'Hôm nay tìm ra `torch.compile()` giúp model chạy nhanh gấp đôi mà không cần đổi code!\n\n```python\nmodel = torch.compile(model)\n```\n\nChỉ 1 dòng, inference time giảm từ 45ms → 22ms trên V100.',
      type: PostType.til,
      tags: ['Python', 'PyTorch', 'Performance'],
      viewCount: 2300,
      likeCount: 156,
      commentCount: 41,
      bookmarkCount: 78,
      isBookmarkedByMe: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Post(
      id: 'p4',
      author: users[3],
      title: 'Next.js 15 Server Actions: Nên dùng khi nào?',
      content:
          '## Server Actions vs API Routes\n\nServer Actions tốt cho form mutations, nhưng không phải silver bullet...\n\n### Nên dùng:\n- Form submit\n- Simple mutations\n\n### Không nên:\n- Complex business logic\n- File uploads lớn',
      type: PostType.question,
      tags: ['Next.js', 'React', 'Server Actions'],
      viewCount: 670,
      likeCount: 34,
      commentCount: 28,
      bookmarkCount: 12,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Post(
      id: 'p5',
      author: users[4],
      title: 'CI/CD Pipeline hoàn chỉnh với GitHub Actions + Docker',
      content:
          '## Pipeline Architecture\n\n```yaml\non:\n  push:\n    branches: [main]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: npm test\n  deploy:\n    needs: test\n    steps:\n      - run: docker build -t app .\n      - run: docker push registry/app\n```',
      type: PostType.article,
      tags: ['DevOps', 'Docker', 'GitHub Actions', 'CI/CD'],
      viewCount: 1560,
      likeCount: 112,
      commentCount: 36,
      bookmarkCount: 67,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Post(
      id: 'p6',
      author: users[5],
      title: 'Custom Painter trong Flutter: Vẽ biểu đồ từ đầu',
      content:
          '```dart\nclass ChartPainter extends CustomPainter {\n  @override\n  void paint(Canvas canvas, Size size) {\n    final paint = Paint()\n      ..color = Colors.blue\n      ..strokeWidth = 2;\n    // vẽ grid, data points, lines\n  }\n}\n```',
      type: PostType.snippet,
      tags: ['Flutter', 'CustomPainter', 'Charts'],
      viewCount: 430,
      likeCount: 28,
      commentCount: 8,
      bookmarkCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    ),
    Post(
      id: 'p7',
      author: users[2],
      title: 'Dự án: Chatbot hỗ trợ code review bằng Gemini',
      content:
          '## Mô tả\nChatbot sử dụng Gemini API để review code tự động.\n\n## Tech Stack\n- Python + FastAPI\n- Gemini 2.0 Flash\n- Docker\n\n## Tìm thành viên\nCần 1-2 bạn biết React để làm frontend.',
      type: PostType.project,
      tags: ['AI', 'Gemini', 'Python', 'Code Review'],
      viewCount: 890,
      likeCount: 54,
      commentCount: 19,
      bookmarkCount: 23,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // ===== COMMENTS =====
  static final comments = [
    Comment(
      id: 'c1',
      author: users[1],
      content:
          'Bài viết rất chi tiết! Mình đang chuyển từ Provider sang Riverpod, đúng lúc cần.',
      upvotes: 12,
      replyCount: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Comment(
      id: 'c2',
      author: users[3],
      content: 'Code generation có ảnh hưởng build time không nhỉ?',
      upvotes: 5,
      replyCount: 1,
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    Comment(
      id: 'c3',
      author: users[4],
      content: 'Mình dùng Riverpod 2 năm rồi. 3.0 thật sự là game changer! 🔥',
      upvotes: 8,
      replyCount: 0,
      isBest: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // ===== CONVERSATIONS =====
  static final conversations = [
    Conversation(
      id: 'conv1',
      otherUser: users[1],
      lastMessage: 'Check code review mình gửi nhé!',
      unreadCount: 2,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Conversation(
      id: 'conv2',
      otherUser: users[2],
      lastMessage: 'Cảm ơn bạn đã giải thích 🙏',
      unreadCount: 0,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Conversation(
      id: 'conv3',
      otherUser: users[3],
      lastMessage: 'Deploy lên staging rồi nha',
      unreadCount: 1,
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Conversation(
      id: 'conv4',
      otherUser: users[5],
      lastMessage: 'Flutter 3.29 update gì hay không?',
      unreadCount: 0,
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // ===== MESSAGES (for conv1) =====
  static final messages = [
    Message(
      id: 'm1',
      senderId: 'u2',
      content: 'Mình vừa refactor xong module Auth',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Message(
      id: 'm2',
      senderId: 'u1',
      content: 'Có gì khác so với bản cũ?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
    ),
    Message(
      id: 'm3',
      senderId: 'u2',
      content: 'Đây, xem đoạn này:',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    Message(
      id: 'm4',
      senderId: 'u2',
      content:
          '@Injectable()\nexport class AuthService {\n  async login(dto: LoginDto) {\n    const user = await this.userRepo.findByEmail(dto.email);\n    if (!user) throw new UnauthorizedException();\n    const valid = await bcrypt.compare(dto.password, user.passwordHash);\n    return this.generateTokens(user);\n  }\n}',
      type: MessageType.code,
      codeLanguage: 'typescript',
      createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
    ),
    Message(
      id: 'm5',
      senderId: 'u1',
      content: 'Clean! 👍 Password hashing dùng bcrypt 12 rounds?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    Message(
      id: 'm6',
      senderId: 'u2',
      content: 'Đúng rồi, 12 rounds. Check code review mình gửi nhé!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  // ===== NOTIFICATIONS =====
  static final notifications = [
    AppNotification(
      id: 'n1',
      type: 'LIKE',
      title: 'Thích bài viết',
      body: 'Anh Trần thích bài viết "Riverpod 3.0"',
      fromUser: users[1],
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    AppNotification(
      id: 'n2',
      type: 'COMMENT',
      title: 'Bình luận mới',
      body: 'Đức Lê bình luận: "Code generation có ảnh hưởng..."',
      fromUser: users[3],
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    AppNotification(
      id: 'n3',
      type: 'FOLLOW',
      title: 'Người theo dõi mới',
      body: 'Thủy Lê bắt đầu theo dõi bạn',
      fromUser: users[4],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n4',
      type: 'MENTION',
      title: 'Được nhắc đến',
      body: 'Linh Phạm nhắc đến bạn trong "Chatbot AI"',
      fromUser: users[2],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n5',
      type: 'LIKE',
      title: 'Thích bài viết',
      body: 'Nam Võ và 3 người khác thích bài "Riverpod 3.0"',
      fromUser: users[5],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 'n6',
      type: 'BEST_ANSWER',
      title: 'Câu trả lời hay nhất!',
      body: 'Câu trả lời của bạn được chọn là tốt nhất',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
  ];

  // ===== PROJECTS =====
  static final projects = [
    Project(
      id: 'proj1',
      owner: users[2],
      title: 'AI Code Reviewer',
      description: 'Bot review code tự động bằng Gemini API',
      techStack: ['Python', 'FastAPI', 'React', 'Docker'],
      status: 'LOOKING_FOR_MEMBERS',
      memberCount: 2,
      maxMembers: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Project(
      id: 'proj2',
      owner: users[0],
      title: 'DevConnect Mobile',
      description: 'Mạng xã hội cho lập trình viên',
      techStack: ['Flutter', 'NestJS', 'PostgreSQL', 'Redis'],
      status: 'ACTIVE',
      memberCount: 3,
      maxMembers: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Project(
      id: 'proj3',
      owner: users[3],
      title: 'Open Source Dashboard',
      description: 'Dashboard analytics cho dự án open source',
      techStack: ['Next.js', 'TypeScript', 'D3.js', 'Supabase'],
      status: 'LOOKING_FOR_MEMBERS',
      memberCount: 1,
      maxMembers: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Project(
      id: 'proj4',
      owner: users[4],
      title: 'K8s Auto-Scaler',
      description: 'Tool auto-scale pods dựa trên metrics custom',
      techStack: ['Go', 'Kubernetes', 'Prometheus', 'Grafana'],
      status: 'ACTIVE',
      memberCount: 4,
      maxMembers: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  // ===== JOBS =====
  static final jobs = [
    Job(
      id: 'j1',
      company: 'TechCorp VN',
      title: 'Senior Flutter Developer',
      location: 'Hồ Chí Minh',
      remote: true,
      salaryRange: '\$1,500 - \$2,500',
      techStack: ['Flutter', 'Dart', 'Firebase'],
      experience: '3-5 năm',
      matchPercent: 92,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Job(
      id: 'j2',
      company: 'StartupX',
      title: 'Backend Engineer (NestJS)',
      location: 'Hà Nội',
      remote: true,
      salaryRange: '\$1,200 - \$2,000',
      techStack: ['NestJS', 'TypeScript', 'PostgreSQL', 'Redis'],
      experience: '2-4 năm',
      matchPercent: 78,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Job(
      id: 'j3',
      company: 'AI Solutions',
      title: 'ML Engineer Intern',
      location: 'Remote',
      remote: true,
      salaryRange: '\$500 - \$800',
      techStack: ['Python', 'PyTorch', 'Docker'],
      experience: 'Thực tập',
      matchPercent: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Job(
      id: 'j4',
      company: 'FinTech Pro',
      title: 'Full-Stack Developer',
      location: 'Đà Nẵng',
      remote: false,
      salaryRange: '\$1,000 - \$1,800',
      techStack: ['React', 'Node.js', 'MongoDB'],
      experience: '1-3 năm',
      matchPercent: 60,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  // ===== LEADERBOARD =====
  static final leaderboard = [
    LeaderboardEntry(rank: 1, user: users[2], points: 4500, rankChange: 0),
    LeaderboardEntry(rank: 2, user: users[0], points: 3200, rankChange: 1),
    LeaderboardEntry(rank: 3, user: users[1], points: 2800, rankChange: -1),
    LeaderboardEntry(rank: 4, user: users[5], points: 2400, rankChange: 2),
    LeaderboardEntry(rank: 5, user: users[3], points: 1800, rankChange: 0),
    LeaderboardEntry(rank: 6, user: users[4], points: 1200, rankChange: -1),
  ];

  // ===== TRENDING TAGS =====
  static const trendingTags = [
    'Flutter',
    'React',
    'AI',
    'Docker',
    'Python',
    'TypeScript',
    'NestJS',
    'Go',
    'Kubernetes',
    'PostgreSQL',
  ];

  // ===== INTERESTS (for onboarding) =====
  static const languages = [
    'Dart',
    'Python',
    'JavaScript',
    'TypeScript',
    'Go',
    'Rust',
    'Java',
    'Kotlin',
    'Swift',
    'C++',
    'C#',
    'PHP',
    'Ruby',
  ];
  static const frameworks = [
    'Flutter',
    'React',
    'Next.js',
    'NestJS',
    'Django',
    'FastAPI',
    'Spring Boot',
    'Express',
    'Vue.js',
    'Angular',
    'Laravel',
    'Rails',
  ];
  static const topics = [
    'AI/ML',
    'DevOps',
    'Mobile',
    'Web',
    'Backend',
    'Frontend',
    'Database',
    'Security',
    'Cloud',
    'System Design',
    'Clean Code',
    'Open Source',
  ];
}
