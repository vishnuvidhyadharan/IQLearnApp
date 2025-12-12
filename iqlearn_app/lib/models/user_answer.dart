class UserAnswer {
  final int? id;
  final int userId;
  final int examId;
  final int questionId;
  final String? selectedAnswer;
  final bool? isCorrect;
  final bool markedForReview;
  final DateTime? answeredAt;

  UserAnswer({
    this.id,
    required this.userId,
    required this.examId,
    required this.questionId,
    this.selectedAnswer,
    this.isCorrect,
    this.markedForReview = false,
    this.answeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'exam_id': examId,
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'is_correct': isCorrect == true ? 1 : 0,
      'marked_for_review': markedForReview ? 1 : 0,
      'answered_at': answeredAt?.toIso8601String(),
    };
  }

  factory UserAnswer.fromMap(Map<String, dynamic> map) {
    return UserAnswer(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      examId: map['exam_id'] as int,
      questionId: map['question_id'] as int,
      selectedAnswer: map['selected_answer'] as String?,
      isCorrect: map['is_correct'] == 1,
      markedForReview: map['marked_for_review'] == 1,
      answeredAt: map['answered_at'] != null
          ? DateTime.parse(map['answered_at'] as String)
          : null,
    );
  }

  UserAnswer copyWith({
    int? id,
    int? userId,
    int? examId,
    int? questionId,
    String? selectedAnswer,
    bool? isCorrect,
    bool? markedForReview,
    DateTime? answeredAt,
  }) {
    return UserAnswer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      questionId: questionId ?? this.questionId,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      markedForReview: markedForReview ?? this.markedForReview,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
