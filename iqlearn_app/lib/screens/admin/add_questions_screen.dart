import 'package:flutter/material.dart';
import '../../models/exam.dart';
import '../../services/database_service.dart';
import '../../utils/mcq_parser.dart';

class AddQuestionsScreen extends StatefulWidget {
  const AddQuestionsScreen({super.key});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final _dbService = DatabaseService.instance;
  final _inputController = TextEditingController();
  
  bool _isProcessing = false;
  ParseResult? _parseResult;
  bool _showPreview = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _parseQuestions() {
    if (_inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter questions in MCQ format')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = MCQParser.parse(_inputController.text);
      
      setState(() {
        _parseResult = result;
        _showPreview = result.success;
        _isProcessing = false;
      });

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parsing error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveQuestions() async {
    if (_parseResult == null || !_parseResult!.success) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create exam
      final exam = await _dbService.createExam(
        Exam(
          topic: _parseResult!.topic!,
          totalQuestions: _parseResult!.questions!.length,
          createdAt: DateTime.now(),
        ),
      );

      // Create questions
      final questions = _parseResult!.questions!
          .map((pq) => pq.toQuestion(exam.id!))
          .toList();

      await _dbService.createQuestionsBatch(questions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added ${questions.length} questions for "${exam.topic}"',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Questions'),
      ),
      body: _showPreview ? _buildPreview() : _buildInputForm(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'MCQ Format',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Topic: Your Topic Name\n\n'
                      '1. Question text here?\n'
                      'A. Option A\n'
                      'B. Option B\n'
                      'C. Option C\n'
                      'D. Option D\n'
                      'Ans: A\n\n'
                      '2. Next question?\n'
                      'A. Option A\n'
                      '...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Enter Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              hintText: 'Paste your MCQ questions here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            maxLines: 15,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _parseQuestions,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.preview),
            label: const Text('Parse and Preview'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final result = _parseResult!;
    final questions = result.questions!;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Topic: ${result.topic}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${questions.length} questions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Questions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${question.questionNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...['A', 'B', 'C', 'D'].map((option) {
                        final isCorrect = question.correctAnswer == option;
                        final optionText = option == 'A'
                            ? question.optionA
                            : option == 'B'
                                ? question.optionB
                                : option == 'C'
                                    ? question.optionC
                                    : question.optionD;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade100
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCorrect
                                  ? Colors.green.shade700
                                  : Colors.grey.shade300,
                              width: isCorrect ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isCorrect)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                              if (isCorrect) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$option. $optionText',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCorrect
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isCorrect
                                        ? Colors.green.shade900
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Action buttons
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
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showPreview = false;
                      _parseResult = null;
                    });
                  },
                  child: const Text('Back to Edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _saveQuestions,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Questions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
