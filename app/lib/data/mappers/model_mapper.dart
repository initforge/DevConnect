import '../../core/models/models.dart';

/// Unified mappers for converting between API JSON, DB rows, and Domain models
class ModelMappers {
  ModelMappers._();

  // ==================== User Mappers ====================

  static User userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName:
          json['displayName']?.toString() ??
          json['display_name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      avatarUrl:
          json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      skills: _parseStringList(json['skills']),
      followerCount: _parseInt(json['followerCount'] ?? json['follower_count']),
      followingCount: _parseInt(
        json['followingCount'] ?? json['following_count'],
      ),
      postCount: _parseInt(json['postCount'] ?? json['post_count']),
      reputation: _parseInt(json['reputation']),
      isOnline: _parseBool(json['isOnline'] ?? json['is_online']),
      isMentor: _parseBool(json['isMentor'] ?? json['is_mentor']),
      isFollowedByMe: _parseBool(
        json['isFollowedByMe'] ?? json['is_followed_by_me'],
      ),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static Map<String, dynamic> userToRow(User user) {
    return {
      'id': user.id,
      'username': user.username,
      'display_name': user.displayName,
      'email': user.email,
      'avatar_url': user.avatarUrl,
      'bio': user.bio,
      'skills': user.skills.join('|'),
      'follower_count': user.followerCount,
      'following_count': user.followingCount,
      'post_count': user.postCount,
      'reputation': user.reputation,
      'is_online': user.isOnline ? 1 : 0,
      'is_mentor': user.isMentor ? 1 : 0,
      'is_followed_by_me': user.isFollowedByMe ? 1 : 0,
      'created_at': user.createdAt.toIso8601String(),
    };
  }

  static User userFromRow(Map<String, Object?> row) {
    return User(
      id: row['id']?.toString() ?? '',
      username: row['username']?.toString() ?? '',
      displayName: row['display_name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      avatarUrl: row['avatar_url']?.toString(),
      bio: row['bio']?.toString(),
      skills: _parseDbStringList(row['skills']?.toString()),
      followerCount: row['follower_count'] as int? ?? 0,
      followingCount: row['following_count'] as int? ?? 0,
      postCount: row['post_count'] as int? ?? 0,
      reputation: row['reputation'] as int? ?? 0,
      isOnline: (row['is_online'] as int?) == 1,
      isMentor: (row['is_mentor'] as int?) == 1,
      isFollowedByMe: (row['is_followed_by_me'] as int?) == 1,
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // ==================== Post Mappers ====================

  static Post postFromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>? ?? {};
    return Post(
      id: json['id']?.toString() ?? '',
      author: userFromJson(authorJson),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: _parsePostType(json['type']),
      tags: _parseStringList(json['tags']),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      viewCount: _parseInt(json['viewCount'] ?? json['view_count']),
      likeCount: _parseInt(json['likeCount'] ?? json['like_count']),
      commentCount: _parseInt(json['commentCount'] ?? json['comment_count']),
      bookmarkCount: _parseInt(json['bookmarkCount'] ?? json['bookmark_count']),
      isLikedByMe: _parseBool(json['isLikedByMe'] ?? json['is_liked_by_me']),
      isBookmarkedByMe: _parseBool(
        json['isBookmarkedByMe'] ?? json['is_bookmarked_by_me'],
      ),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      highlightedTitle: json['highlightedTitle']?.toString(),
      highlightedContent: json['highlightedContent']?.toString(),
    );
  }

  static Map<String, dynamic> postToRow(Post post) {
    return {
      'id': post.id,
      'author_id': post.author.id,
      'title': post.title,
      'content': post.content,
      'type': post.type.name,
      'tags': post.tags.join('|'),
      'image_url': post.imageUrl,
      'view_count': post.viewCount,
      'like_count': post.likeCount,
      'comment_count': post.commentCount,
      'bookmark_count': post.bookmarkCount,
      'is_liked_by_me': post.isLikedByMe ? 1 : 0,
      'is_bookmarked_by_me': post.isBookmarkedByMe ? 1 : 0,
      'created_at': post.createdAt.toIso8601String(),
    };
  }

  static Post postFromRow(Map<String, Object?> row, User author) {
    return Post(
      id: row['id']?.toString() ?? '',
      author: author,
      title: row['title']?.toString() ?? '',
      content: row['content']?.toString() ?? '',
      type: _parsePostType(row['type']?.toString()),
      tags: _parseDbStringList(row['tags']?.toString()),
      imageUrl: row['image_url']?.toString(),
      viewCount: row['view_count'] as int? ?? 0,
      likeCount: row['like_count'] as int? ?? 0,
      commentCount: row['comment_count'] as int? ?? 0,
      bookmarkCount: row['bookmark_count'] as int? ?? 0,
      isLikedByMe: (row['is_liked_by_me'] as int?) == 1,
      isBookmarkedByMe: (row['is_bookmarked_by_me'] as int?) == 1,
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // ==================== Comment Mappers ====================

  static Comment commentFromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>? ?? {};
    return Comment(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
      author: userFromJson(authorJson),
      content: json['content']?.toString() ?? '',
      depth: _parseInt(json['depth']),
      upvotes: _parseInt(json['upvotes']),
      replyCount: _parseInt(json['replyCount'] ?? json['reply_count']),
      isBest: _parseBool(json['isBest'] ?? json['is_best']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static Map<String, dynamic> commentToRow(Comment comment, String postId) {
    return {
      'id': comment.id,
      'post_id': postId,
      'parent_id': comment.parentId,
      'author_id': comment.author.id,
      'content': comment.content,
      'depth': comment.depth,
      'upvotes': comment.upvotes,
      'reply_count': comment.replyCount,
      'is_best': comment.isBest ? 1 : 0,
      'created_at': comment.createdAt.toIso8601String(),
    };
  }

  // ==================== Conversation Mappers ====================

  static Conversation conversationFromJson(Map<String, dynamic> json) {
    final userJson =
        json['otherUser'] as Map<String, dynamic>? ??
        json['other_user'] as Map<String, dynamic>? ??
        {};
    return Conversation(
      id: json['id']?.toString() ?? '',
      otherUser: userFromJson(userJson),
      lastMessage:
          json['lastMessage']?.toString() ??
          json['last_message']?.toString() ??
          '',
      unreadCount: _parseInt(json['unreadCount'] ?? json['unread_count']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  // ==================== Notification Mappers ====================

  static AppNotification notificationFromJson(Map<String, dynamic> json) {
    final userJson =
        json['fromUser'] as Map<String, dynamic>? ??
        json['from_user'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      fromUser: userJson != null ? userFromJson(userJson) : null,
      isRead: _parseBool(json['isRead'] ?? json['is_read']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      mergedCount:
          _parseInt(
            json['mergedCount'] ?? json['merged_count'],
          ).clamp(1, 1 << 31).toInt(),
    );
  }

  // ==================== Project Mappers ====================

  static Project projectFromJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'] as Map<String, dynamic>? ?? {};
    return Project(
      id: json['id']?.toString() ?? '',
      owner: userFromJson(ownerJson),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      techStack: _parseStringList(json['techStack'] ?? json['tech_stack']),
      status: json['status']?.toString() ?? 'LOOKING_FOR_MEMBERS',
      memberCount: _parseInt(json['memberCount'] ?? json['member_count']),
      maxMembers: _parseInt(json['maxMembers'] ?? json['max_members']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static Map<String, dynamic> projectToRow(Project project) {
    return {
      'id': project.id,
      'owner_id': project.owner.id,
      'title': project.title,
      'description': project.description,
      'tech_stack': project.techStack.join('|'),
      'status': project.status,
      'member_count': project.memberCount,
      'max_members': project.maxMembers,
      'created_at': project.createdAt.toIso8601String(),
    };
  }

  // ==================== Job Mappers ====================

  static Job jobFromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      remote: _parseBool(json['remote']),
      salaryRange:
          json['salaryRange']?.toString() ??
          json['salary_range']?.toString() ??
          '',
      techStack: _parseStringList(json['techStack'] ?? json['tech_stack']),
      experience: json['experience']?.toString() ?? '',
      matchPercent: _parseInt(json['matchPercent'] ?? json['match_percent']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  static Map<String, dynamic> jobToRow(Job job) {
    return {
      'id': job.id,
      'company': job.company,
      'title': job.title,
      'location': job.location,
      'remote': job.remote ? 1 : 0,
      'salary_range': job.salaryRange,
      'tech_stack': job.techStack.join('|'),
      'experience': job.experience,
      'match_percent': job.matchPercent,
      'created_at': job.createdAt.toIso8601String(),
    };
  }

  // ==================== Helper Methods ====================

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String)
      return value.split('|').where((e) => e.isNotEmpty).toList();
    return [];
  }

  static List<String> _parseDbStringList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split('|').where((e) => e.isNotEmpty).toList();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static PostType _parsePostType(dynamic value) {
    final str = value?.toString().toLowerCase() ?? '';
    return PostType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => PostType.article,
    );
  }
}
