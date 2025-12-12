class UserExamProgress {
  final int? id;
  final int userId;
  final int examId;
  final String status; // not_started, in_progress, completed
  final int completedQuestions;
  final int? score;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? timeRemainingSeconds;

  UserExamProgress({
    this.id,
    required this.userId,
    required this.examId,
    this.status = 'not_started',
    this.completedQuestions = 0,
    this.score,
    this.startedAt,
    this.completedAt,
    this.timeRemainingSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'exam_id': examId,
      'status': status,
      'completed_questions': completedQuestions,
      'score': score,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'time_remaining_seconds': timeRemainingSeconds,
    };
  }

  factory UserExamProgress.fromMap(Map<String, dynamic> map) {
    return UserExamProgress(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      examId: map['exam_id'] as int,
      status: map['status'] as String? ?? 'not_started',
      completedQuestions: map['completed_questions'] as int? ?? 0,
      score: map['score'] as int?,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      timeRemainingSeconds: map['time_remaining_seconds'] as int?,
    );
  }

  UserExamProgress copyWith({
    int? id,
    int? userId,
    int? examId,
    String? status,
    int? completedQuestions,
    int? score,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeRemainingSeconds,
  }) {
    return UserExamProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      status: status ?? this.status,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      score: score ?? this.score,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
    );
  }
}
