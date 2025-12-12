import 'package:flutter/material.dart';
import '../../models/exam.dart';
import '../../models/question.dart';
import '../../models/user_answer.dart';
import '../../models/user_exam_progress.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/question_widget.dart';
import 'results_screen.dart';

class ExamScreen extends StatefulWidget {
  final Exam exam;
  final bool isReviewMode;

  const ExamScreen({
    super.key, 
    required this.exam,
    this.isReviewMode = false,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService.instance;
  final GlobalKey<TimerWidgetState> _timerKey = GlobalKey<TimerWidgetState>();

  List<Question> _questions = [];
  Map<int, UserAnswer> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  UserExamProgress? _progress;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final questions = await _dbService.getQuestionsByExam(widget.exam.id!);
      final userId = _authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get or create progress
      var progress = await _dbService.getProgress(userId, widget.exam.id!);
      if (progress == null) {
        progress = await _dbService.createOrUpdateProgress(
          UserExamProgress(
            userId: userId,
            examId: widget.exam.id!,
            status: 'in_progress',
            startedAt: DateTime.now(),
            timeRemainingSeconds: widget.exam.timeLimitMinutes * 60,
          ),
        );
      } else {
        // Update status to in_progress if not already AND NOT in review mode
        if (progress.status != 'in_progress' && !widget.isReviewMode) {
          progress = progress.copyWith(
            status: 'in_progress',
            startedAt: DateTime.now(),
            timeRemainingSeconds: widget.exam.timeLimitMinutes * 60,
          );
          await _dbService.createOrUpdateProgress(progress);
        }
      }

      // Load existing answers
      final existingAnswers = await _dbService.getAnswersByUserAndExam(
        userId,
        widget.exam.id!,
      );
      final answersMap = <int, UserAnswer>{};
      for (var answer in existingAnswers) {
        answersMap[answer.questionId] = answer;
      }

      setState(() {
        _questions = questions;
        _answers = answersMap;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exam: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveAnswer(String selectedAnswer) async {
    if (widget.isReviewMode) return; // Disable answering in review mode

    final userId = _authService.currentUser?.id;
    if (userId == null || _questions.isEmpty) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = selectedAnswer == currentQuestion.correctAnswer;

    final answer = UserAnswer(
      userId: userId,
      examId: widget.exam.id!,
      questionId: currentQuestion.id!,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      markedForReview: _answers[currentQuestion.id!]?.markedForReview ?? false,
      answeredAt: DateTime.now(),
    );

    await _dbService.createOrUpdateAnswer(answer);
    
    setState(() {
      _answers[currentQuestion.id!] = answer;
    });

    // Update progress
    await _updateProgress();
  }

  Future<void> _toggleMarkForReview(bool marked) async {
    if (widget.isReviewMode) return; // Disable marking in review mode

    final userId = _authService.currentUser?.id;
    if (userId == null || _questions.isEmpty) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final existingAnswer = _answers[currentQuestion.id!];

    final answer = existingAnswer?.copyWith(markedForReview: marked) ??
        UserAnswer(
          userId: userId,
          examId: widget.exam.id!,
          questionId: currentQuestion.id!,
          markedForReview: marked,
        );

    await _dbService.createOrUpdateAnswer(answer);
    
    setState(() {
      _answers[currentQuestion.id!] = answer;
    });
  }

  Future<void> _updateProgress() async {
    if (widget.isReviewMode) return; // Don't update progress in review mode

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final completedCount = _answers.values
        .where((answer) => answer.selectedAnswer != null)
        .length;

    final updatedProgress = _progress!.copyWith(
      completedQuestions: completedCount,
      timeRemainingSeconds: _timerKey.currentState?.remainingSeconds,
    );

    await _dbService.createOrUpdateProgress(updatedProgress);
    setState(() {
      _progress = updatedProgress;
    });
  }

  Future<void> _submitExam() async {
    if (widget.isReviewMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam'),
        content: const Text('Are you sure you want to submit the exam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Calculate score
    int score = 0;
    for (var answer in _answers.values) {
      if (answer.isCorrect == true) {
        score++;
      }
    }

    // Update progress as completed
    final finalProgress = _progress!.copyWith(
      status: 'completed',
      completedQuestions: _answers.length,
      score: score,
      completedAt: DateTime.now(),
      timeRemainingSeconds: _timerKey.currentState?.remainingSeconds,
    );

    await _dbService.createOrUpdateProgress(finalProgress);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            exam: widget.exam,
            score: score,
            totalQuestions: _questions.length,
          ),
        ),
      );
    }
  }

  void _onTimerExpired() {
    if (!widget.isReviewMode) {
      _submitExam();
    }
  }

  bool get _canSubmit {
    return _answers.values
        .where((answer) => answer.selectedAnswer != null)
        .length == _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.topic)),
        body: const Center(
          child: Text('No questions available for this exam'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final currentAnswer = _answers[currentQuestion.id!];

    return WillPopScope(
      onWillPop: () async {
        if (widget.isReviewMode) return true; // Allow exit in review mode

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Exam'),
            content: const Text(
              'Your progress will be saved. Do you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isReviewMode ? 'Review: ${widget.exam.topic}' : widget.exam.topic),
          actions: [
            if (!widget.isReviewMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TimerWidget(
                  key: _timerKey,
                  initialSeconds: _progress?.timeRemainingSeconds ??
                      widget.exam.timeLimitMinutes * 60,
                  onTimerExpired: _onTimerExpired,
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Answered: ${_answers.values.where((a) => a.selectedAnswer != null).length}/${_questions.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                child: QuestionWidget(
                  question: currentQuestion,
                  selectedAnswer: currentAnswer?.selectedAnswer,
                  markedForReview: currentAnswer?.markedForReview ?? false,
                  onAnswerSelected: widget.isReviewMode ? (_) {} : _saveAnswer, // Disable selection
                  onMarkForReview: widget.isReviewMode ? (_) {} : _toggleMarkForReview, // Disable marking
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                  if (_currentQuestionIndex < _questions.length - 1)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ),
                  if (_currentQuestionIndex == _questions.length - 1 && _canSubmit && !widget.isReviewMode)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitExam,
                        icon: const Icon(Icons.check),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
