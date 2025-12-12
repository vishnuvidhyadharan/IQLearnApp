import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/exam.dart';
import '../../models/question.dart';
import '../../models/user_answer.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/groq_service.dart';

class ResultsScreen extends StatefulWidget {
  final Exam exam;
  final int score;
  final int totalQuestions;

  const ResultsScreen({
    super.key,
    required this.exam,
    required this.score,
    required this.totalQuestions,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _dbService = DatabaseService.instance;
  final _authService = AuthService();
  final _groqService = GroqService();

  bool _showingReview = false;
  bool _showOnlyIncorrect = false;
  List<Question> _questions = [];
  Map<int, UserAnswer> _answersMap = {};
  final Map<int, String> _explanations = {};
  final Map<int, bool> _loadingExplanations = {};

  @override
  void initState() {
    super.initState();
    _initializeGroq();
  }

  void _initializeGroq() {
    final apiKey = _authService.currentUser?.groqApiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      _groqService.initialize(apiKey);
    }
  }

  Future<void> _loadQuestionsAndAnswers() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final questions = await _dbService.getQuestionsByExam(widget.exam.id!);
    final answers = await _dbService.getAnswersByUserAndExam(
      userId,
      widget.exam.id!,
    );

    final answersMap = <int, UserAnswer>{};
    for (var answer in answers) {
      answersMap[answer.questionId] = answer;
    }

    setState(() {
      _questions = questions;
      _answersMap = answersMap;
      _showingReview = true;
    });
  }

  Future<void> _getExplanation(Question question) async {
    if (!_groqService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add your Groq API key in the profile to use explanations.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _loadingExplanations[question.id!] = true;
    });

    try {
      final explanation = await _groqService.getExplanation(question: question);

      setState(() {
        _explanations[question.id!] = explanation;
        _loadingExplanations[question.id!] = false;
      });
    } catch (e) {
      setState(() {
        _loadingExplanations[question.id!] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting explanation: $e')),
        );
      }
    }
  }

  double get _percentage => (widget.score / widget.totalQuestions) * 100;

  Color get _scoreColor {
    if (_percentage >= 80) return Colors.green;
    if (_percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String get _resultMessage {
    if (_percentage >= 80) return 'Excellent! 🎉';
    if (_percentage >= 60) return 'Good Job! 👍';
    if (_percentage >= 40) return 'Keep Practicing! 💪';
    return 'Need More Practice! 📚';
  }

  List<Question> get _filteredQuestions {
    if (!_showOnlyIncorrect) return _questions;

    return _questions.where((question) {
      final answer = _answersMap[question.id!];
      // Include if answer is missing (unanswered) OR incorrect
      return answer == null ||
          answer.selectedAnswer == null ||
          answer.isCorrect == false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingReview) {
      return _buildReviewScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _resultMessage,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _scoreColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Score circle
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: [
                            PieChartSectionData(
                              value: widget.score.toDouble(),
                              color: Colors.green,
                              title: '${widget.score}',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: (widget.totalQuestions - widget.score)
                                  .toDouble(),
                              color: Colors.red,
                              title: '${widget.totalQuestions - widget.score}',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Score text
                    Text(
                      '${widget.score} / ${widget.totalQuestions}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        color: _scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Review buttons
            ElevatedButton.icon(
              onPressed: () {
                _loadQuestionsAndAnswers();
                setState(() {
                  _showOnlyIncorrect = true;
                });
              },
              icon: const Icon(Icons.error_outline),
              label: const Text('Review Incorrect Answers'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                _loadQuestionsAndAnswers();
                setState(() {
                  _showOnlyIncorrect = false;
                });
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Review All Questions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Back to home button
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    final questionsToShow = _filteredQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(_showOnlyIncorrect ? 'Incorrect Answers' : 'All Questions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showingReview = false;
            });
          },
        ),
      ),
      body: questionsToShow.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'No incorrect answers!',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questionsToShow.length,
              itemBuilder: (context, index) {
                final question = questionsToShow[index];
                final answer = _answersMap[question.id!];
                final isCorrect = answer?.isCorrect ?? false;
                final userAnswer = answer?.selectedAnswer;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and status
                        Row(
                          children: [
                            Text(
                              'Question ${question.questionNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Question text
                        Text(
                          question.questionText,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Options
                        ...['A', 'B', 'C', 'D'].map((option) {
                          final isUserAnswer = userAnswer == option;
                          final isCorrectAnswer =
                              question.correctAnswer == option;

                          Color? backgroundColor;
                          Color? textColor;

                          if (isCorrectAnswer) {
                            backgroundColor = Colors.green.shade100;
                            textColor = Colors.green.shade900;
                          } else if (isUserAnswer && !isCorrect) {
                            backgroundColor = Colors.red.shade100;
                            textColor = Colors.red.shade900;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: backgroundColor ?? Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCorrectAnswer
                                    ? Colors.green
                                    : (isUserAnswer && !isCorrect)
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: (isCorrectAnswer || isUserAnswer)
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isCorrectAnswer)
                                  const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 20,
                                  )
                                else if (isUserAnswer && !isCorrect)
                                  const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                if (isCorrectAnswer ||
                                    (isUserAnswer && !isCorrect))
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$option. ${question.options[option]}',
                                    style: TextStyle(
                                      color: textColor ?? Colors.black87,
                                      fontWeight:
                                          (isCorrectAnswer || isUserAnswer)
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // Explain button
                        OutlinedButton.icon(
                          onPressed: () => _getExplanation(question),
                          icon: _loadingExplanations[question.id!] == true
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lightbulb_outline),
                          label: const Text('Explain'),
                        ),

                        // Explanation
                        if (_explanations.containsKey(question.id!))
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _explanations[question.id!]!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
