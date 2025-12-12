import 'package:flutter/material.dart';
import '../../models/exam.dart';
import '../../models/user_exam_progress.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/question_loader_service.dart';
import '../../widgets/exam_card.dart';
import '../exam/exam_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _dbService = DatabaseService.instance;
  final _questionLoader = QuestionLoaderService();
  
  List<Exam> _exams = [];
  Map<int, UserExamProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadExams();
  }

  Future<void> _initializeAndLoadExams() async {
    // Load questions from file on first launch
    try {
      await _questionLoader.loadQuestionsFromFile();
    } catch (e) {
      print('Error loading questions from file: $e');
    }
    
    // Load exams from database
    await _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exams = await _dbService.getAllExams();
      final userId = _authService.currentUser?.id;

      if (userId != null) {
        final allProgress = await _dbService.getAllProgressForUser(userId);
        final progressMap = <int, UserExamProgress>{};
        for (var progress in allProgress) {
          progressMap[progress.examId] = progress;
        }
        
        setState(() {
          _exams = exams;
          print("aaaaaaaaaa: ${_exams.length}");
          _progressMap = progressMap;
        });
      } else {
        setState(() {
          _exams = exams;
          print("bbbbbbbbb: ${_exams.length}");
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

  void _startExam(Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamScreen(exam: exam),
      ),
    ).then((_) => _loadExams()); // Refresh when returning
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _refreshExams() async {
    // 1. Check for updates from GitHub/Files
    try {
      await _questionLoader.loadQuestionsFromFile();
    } catch (e) {
      print('Error refreshing questions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
    
    // 2. Reload from database
    await _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IQ Learn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Chat with AI',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => _loadExams());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
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
                            'No exams available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
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

                        return ExamCard(
                          topic: exam.topic,
                          totalQuestions: exam.totalQuestions,
                          completedQuestions: completedQuestions,
                          status: status,
                          isUpdateAvailable: exam.isUpdateAvailable,
                          onTap: () {
                            if (exam.isUpdateAvailable) {
                              _showUpdateDialog(exam);
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamScreen(exam: exam, isReviewMode: true),
        ),
      );
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

  Future<void> _showUpdateDialog(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'An update is available for "${exam.topic}".\n\n'
          'Updating will reset your progress for this exam.\n'
          'Do you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final success = await _questionLoader.updateSpecificExam(exam.topic);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exam updated successfully')),
            );
          }
          await _loadExams();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update exam')),
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
}
