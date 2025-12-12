class Exam {
  final int? id;
  final String topic;
  final int totalQuestions;
  final int timeLimitMinutes;
  final DateTime? createdAt;
  final bool isUpdateAvailable;
  final String? contentHash;

  Exam({
    this.id,
    required this.topic,
    this.totalQuestions = 100,
    this.timeLimitMinutes = 120,
    this.createdAt,
    this.isUpdateAvailable = false,
    this.contentHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'total_questions': totalQuestions,
      'time_limit_minutes': timeLimitMinutes,
      'created_at': createdAt?.toIso8601String(),
      'is_update_available': isUpdateAvailable ? 1 : 0,
      'content_hash': contentHash,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int?,
      topic: map['topic'] as String,
      totalQuestions: map['total_questions'] as int? ?? 100,
      timeLimitMinutes: map['time_limit_minutes'] as int? ?? 120,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      isUpdateAvailable: (map['is_update_available'] as int? ?? 0) == 1,
      contentHash: map['content_hash'] as String?,
    );
  }
}
