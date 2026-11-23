/// Represents a single post in the Jaga Tani community forum.
class CommunityPost {
  /// Unique identifier for this post.
  final String id;

  /// Display name of the post author.
  final String authorName;

  /// Emoji used as the author's avatar placeholder.
  final String authorAvatar;

  /// Short title summarizing the post topic.
  final String title;

  /// Full text body of the post.
  final String content;

  /// Category tag for the post (e.g., 'Irigasi', 'Hama', 'Pupuk').
  final String category;

  /// Total number of likes this post has received.
  final int likesCount;

  /// Total number of comments on this post.
  final int commentsCount;

  /// When this post was published.
  final DateTime timestamp;

  /// List of searchable hashtag-style tags (without the # character).
  final List<String> tags;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    required this.content,
    required this.category,
    required this.likesCount,
    required this.commentsCount,
    required this.timestamp,
    required this.tags,
  });

  // ──────────────────────────── copyWith ───────────────────────────────────

  CommunityPost copyWith({
    String? id,
    String? authorName,
    String? authorAvatar,
    String? title,
    String? content,
    String? category,
    int? likesCount,
    int? commentsCount,
    DateTime? timestamp,
    List<String>? tags,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
    );
  }

  // ──────────────────────────── JSON ───────────────────────────────────────

  /// Serializes this [CommunityPost] to a JSON-compatible [Map].
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'title': title,
      'content': content,
      'category': category,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'timestamp': timestamp.toIso8601String(),
      'tags': tags,
    };
  }

  /// Creates a [CommunityPost] from a JSON [Map].
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      tags: List<String>.from(json['tags'] as List),
    );
  }

  // ─────────────────────────── Display Helpers ─────────────────────────────

  /// Returns a short preview of the content (max 120 characters).
  String get contentPreview {
    if (content.length <= 120) return content;
    return '${content.substring(0, 120)}...';
  }

  /// Returns a formatted relative time string in Bahasa Indonesia.
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    return '${(diff.inDays / 30).floor()} bulan lalu';
  }

  /// Returns the formatted likes count (e.g., 1.2K for values >= 1000).
  String get likesFormatted {
    if (likesCount >= 1000) {
      return '${(likesCount / 1000).toStringAsFixed(1)}K';
    }
    return likesCount.toString();
  }

  @override
  String toString() =>
      'CommunityPost(id: $id, author: $authorName, title: $title, '
      'likes: $likesCount, comments: $commentsCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPost &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
