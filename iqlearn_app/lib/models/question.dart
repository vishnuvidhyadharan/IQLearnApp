class Question {
  final int? id;
  final int examId;
  final int questionNumber;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;

  Question({
    this.id,
    required this.examId,
    required this.questionNumber,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'question_number': questionNumber,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      examId: map['exam_id'] as int,
      questionNumber: map['question_number'] as int,
      questionText: map['question_text'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      correctAnswer: map['correct_answer'] as String,
    );
  }

  Map<String, String> get options => {
        'A': optionA,
        'B': optionB,
        'C': optionC,
        'D': optionD,
      };
}
