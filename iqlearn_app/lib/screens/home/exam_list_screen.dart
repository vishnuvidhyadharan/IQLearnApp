import 'package:flutter/material.dart';
import '../../models/exam.dart';
import '../../models/user_exam_progress.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/question_loader_service.dart';
import '../../widgets/exam_card.dart';
import '../exam/exam_screen.dart';

class ExamListScreen extends StatefulWidget {
  final String category;

  const ExamListScreen({super.key, required this.category});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService.instance;
  final _questionLoader = QuestionLoaderService();
  
  List<Exam> _exams = [];
  Map<int, UserExamProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _refreshExams() async {
    // 1. Check for updates from GitHub
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking for updates...'), duration: Duration(seconds: 1)),
      );
      
      await _questionLoader.loadQuestionsFromFile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exams updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating exams: $e')),
        );
      }
    }

    // 2. Reload from DB
    await _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exams = await _dbService.getExamsByCategory(widget.category);
      final userId = _authService.currentUser?.id;

      if (userId != null) {
        final allProgress = await _dbService.getAllProgressForUser(userId);
        final progressMap = <int, UserExamProgress>{};
        for (var progress in allProgress) {
          progressMap[progress.examId] = progress;
        }
        
        setState(() {
          _exams = exams;
          _progressMap = progressMap;
        });
      } else {
        setState(() {
          _exams = exams;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exams: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startExam(Exam exam, {bool isReviewMode = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamScreen(exam: exam, isReviewMode: isReviewMode),
      ),
    ).then((_) => _loadExams()); // Refresh when returning
  }

  Future<void> _handleCompletedExamTap(Exam exam) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.topic),
        content: const Text('You have already completed this exam. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'review'),
            child: const Text('Review Exam'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'retake'),
            child: const Text('Retake Exam'),
          ),
        ],
      ),
    );

    if (choice == 'review') {
      _startExam(exam, isReviewMode: true);
    } else if (choice == 'retake') {
      final confirmRetake = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Retake Exam'),
          content: const Text(
            'This will reset your previous score and answers for this exam.\n'
            'Are you sure you want to retake it?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retake', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmRetake == true) {
        setState(() => _isLoading = true);
        try {
          final userId = _authService.currentUser?.id;
          if (userId != null) {
            await _dbService.deleteProgress(userId, exam.id!);
            await _dbService.deleteUserAnswers(userId, exam.id!);
            await _loadExams(); // Refresh UI to show as not started
            if (mounted) {
              _startExam(exam);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error resetting exam: $e')),
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showUpdateDialog(Exam exam, String status) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'An update is available for "${exam.topic}".\n\n'
          'Updating will reset your progress for this exam.\n'
          '${status == 'completed' ? 'You can choose to review your completed exam (old version) or update to the new version.' : 'Do you want to continue?'}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          if (status == 'completed')
            TextButton(
              onPressed: () => Navigator.pop(context, 'review'),
              child: const Text('Review Old'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'update'),
            child: const Text('Update', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (choice == 'review') {
      _startExam(exam, isReviewMode: true);
    } else if (choice == 'update') {
      setState(() => _isLoading = true);
      try {
        // Pass current category to prevent cross-category updates
        final error = await _questionLoader.updateSpecificExam(exam.topic, category: widget.category);
        if (error == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exam updated successfully')),
            );
          }
          await _loadExams();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update exam: $error')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating exam: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshExams,
              child: _exams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No exams available in ${widget.category}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Debug Log Display
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                QuestionLoaderService.debugLog.toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        final progress = _progressMap[exam.id!];
                        final status = progress?.status ?? 'not_started';
                        final completedQuestions = progress?.completedQuestions ?? 0;
                        final score = progress?.score;

                        return ExamCard(
                          topic: exam.topic,
                          totalQuestions: exam.totalQuestions,
                          completedQuestions: completedQuestions,
                          status: status,
                          score: score,
                          isUpdateAvailable: exam.isUpdateAvailable,
                          onTap: () {
                            if (exam.isUpdateAvailable) {
                              _showUpdateDialog(exam, status);
                            } else if (status == 'completed') {
                              _handleCompletedExamTap(exam);
                            } else {
                              _startExam(exam);
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
