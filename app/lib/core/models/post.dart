import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'post.g.dart';

/// Types of posts available on the platform.
enum PostType {
  @JsonValue('article')
  article,
  @JsonValue('snippet')
  snippet,
  @JsonValue('til')
  til,
  @JsonValue('question')
  question,
  @JsonValue('project')
  project,
  @JsonValue('discussion')
  discussion,
}

@JsonSerializable()
class Post extends Equatable {
  final String id;
  final User author;
  final String title;
  final String content;
  @JsonKey(fromJson: _postTypeFromJson, toJson: _postTypeToJson)
  final PostType type;
  final List<String> tags;
  @JsonKey(name: 'imageUrl')
  final String? imageUrl;
  @JsonKey(name: 'viewCount')
  final int viewCount;
  @JsonKey(name: 'likeCount')
  final int likeCount;
  @JsonKey(name: 'commentCount')
  final int commentCount;
  @JsonKey(name: 'bookmarkCount')
  final int bookmarkCount;
  @JsonKey(name: 'isLikedByMe')
  final bool isLikedByMe;
  @JsonKey(name: 'isBookmarkedByMe')
  final bool isBookmarkedByMe;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  final String? highlightedTitle;
  final String? highlightedContent;

  const Post({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    this.type = PostType.article,
    this.tags = const [],
    this.imageUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.bookmarkCount = 0,
    this.isLikedByMe = false,
    this.isBookmarkedByMe = false,
    required this.createdAt,
    this.highlightedTitle,
    this.highlightedContent,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({
    String? id,
    User? author,
    String? title,
    String? content,
    PostType? type,
    List<String>? tags,
    String? imageUrl,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? bookmarkCount,
    bool? isLikedByMe,
    bool? isBookmarkedByMe,
    DateTime? createdAt,
    String? highlightedTitle,
    String? highlightedContent,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isBookmarkedByMe: isBookmarkedByMe ?? this.isBookmarkedByMe,
      createdAt: createdAt ?? this.createdAt,
      highlightedTitle: highlightedTitle ?? this.highlightedTitle,
      highlightedContent: highlightedContent ?? this.highlightedContent,
    );
  }

  @override
  List<Object?> get props => [id];
}

PostType _postTypeFromJson(dynamic value) {
  if (value is String) {
    return PostType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostType.article,
    );
  }
  return PostType.article;
}

String _postTypeToJson(PostType type) => type.name;
