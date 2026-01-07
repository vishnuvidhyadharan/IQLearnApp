import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/exam.dart';
import '../models/question.dart';
import 'database_service.dart';

class QuestionLoaderService {
  final DatabaseService _db = DatabaseService.instance;

  static const String REMOTE_QUESTIONS_URL =
      'https://raw.githubusercontent.com/vishnuvidhyadharan/IQLearnApp/master/iqlearn_app/exam_questions';

  // Static log for on-device debugging
  static StringBuffer debugLog = StringBuffer();

  void _log(String message) {
    print(message);
    debugLog.writeln(
      '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} $message',
    );
  }

  /// Load questions using index.json as the master list
  Future<void> loadQuestionsFromFile() async {
    final existingExams = await _db.getAllExams();
    final existingTopics = existingExams
        .map((e) => e.topic.toLowerCase())
        .toSet();

    List<dynamic> masterList = [];
    bool isRemoteIndex = false;

    // 1. Try to fetch Master List from Remote
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final indexUrl = '$REMOTE_QUESTIONS_URL/index.json?t=$timestamp';
      _log('QuestionLoaderService: Fetching master list from $indexUrl');

      final response = await http
          .get(Uri.parse(indexUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        masterList = json.decode(response.body);
        isRemoteIndex = true;
        _log('QuestionLoaderService: Loaded Remote Master List: $masterList');
      }
    } catch (e) {
      _log('QuestionLoaderService: Remote index fetch failed: $e');
    }

    // 2. Fallback to Local Master List if Remote failed
    if (masterList.isEmpty) {
      try {
        _log(
          'QuestionLoaderService: Loading Local Master List from exam_questions/index.json',
        );
        final localIndexContent = await rootBundle.loadString(
          'exam_questions/index.json',
        );
        masterList = json.decode(localIndexContent);
        _log('QuestionLoaderService: Loaded Local Master List: $masterList');
      } catch (e) {
        _log('QuestionLoaderService: Local index load failed: $e');
        // Final fallback: Hardcoded list (just in case)
        masterList = [
          "exam_questions/history/history_of_india.txt",
          "exam_questions/history/newtest.txt",
          "exam_questions/history/sample_que.txt",
          "exam_questions/geography/test7.txt",
          "exam_questions/chemistry/test.txt",
        ];
      }
    }

    // 3. Process each file in the Master List
    for (final fileName in masterList) {
      if (fileName is String && fileName.endsWith('.txt')) {
        await _processFileFromMasterList(
          fileName,
          existingTopics,
          isRemoteIndex,
        );
      }
    }
  }

  Future<void> _processFileFromMasterList(
    String fileName,
    Set<String> existingTopics,
    bool isRemoteIndex,
  ) async {
    String? content;
    bool isRemoteContent = false;
    final category = _extractCategory(fileName);

    // A. Try Remote Download (if index was remote or just try anyway)
    // A. Try Remote Download (ONLY if index was remote)
    if (isRemoteIndex) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        // Fix: Handle potential double "exam_questions/" if present in both Base URL and File Name
        String cleanFileName = fileName;
        if (REMOTE_QUESTIONS_URL.endsWith('exam_questions') &&
            fileName.startsWith('exam_questions/')) {
          cleanFileName = fileName.substring('exam_questions/'.length);
        }

        final fileUrl = '$REMOTE_QUESTIONS_URL/$cleanFileName?t=$timestamp';
        // _log('Downloading from: $fileUrl'); // Optional: Uncomment for verbose URL debugging

        final response = await http
            .get(Uri.parse(fileUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          content = response.body;
          isRemoteContent = true;
          _log('QuestionLoaderService: Downloaded $fileName from Remote');
        } else {
          _log(
            'QuestionLoaderService: HTTP ${response.statusCode} for $fileName',
          );
        }
      } catch (e) {
        _log('QuestionLoaderService: Failed to download $fileName: $e');
      }
    } else {
      _log(
        'QuestionLoaderService: Skipping remote download for $fileName (Offline Mode)',
      );
    }

    // B. Fallback to Local Asset
    if (content == null) {
      try {
        content = await rootBundle.loadString(fileName);
        _log('QuestionLoaderService: Loaded $fileName from Local Assets');
      } catch (e) {
        _log('QuestionLoaderService: Failed to load local asset $fileName: $e');
      }
    }

    // C. Process Content
    if (content != null) {
      await _processFileContent(
        content,
        fileName,
        existingTopics,
        isRemote: isRemoteContent,
        forceUpdate: isRemoteContent, // Force update if it came from remote
        category: category,
      );
    }
  }

  String _calculateHash(String content) {
    var bytes = utf8.encode(content);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _extractCategory(String filePath) {
    // Format: exam_questions/<category>/<filename>
    final parts = filePath.split('/');
    if (parts.length >= 3 && parts[0] == 'exam_questions') {
      // Capitalize first letter
      final category = parts[1];
      return category[0].toUpperCase() + category.substring(1);
    }
    return 'General';
  }

  Future<void> _processFileContent(
    String content,
    String sourceName,
    Set<String> existingTopics, {
    bool isRemote = false,
    bool forceUpdate = false,
    bool ignoreProgress = false,
    String category = 'General',
  }) async {
    final parsedData = _parseQuestions(content, sourceName);

    if (parsedData != null) {
      final exam = parsedData['exam'] as Exam;
      final questions = parsedData['questions'] as List<Question>;
      final newContentHash = _calculateHash(content);

      // If topic exists
      if (existingTopics.contains(exam.topic.toLowerCase())) {
        if (forceUpdate) {
          // Check if there is any progress for this exam
          final existingExams = await _db.getAllExams();
          final existingExam = existingExams.firstWhere(
            (e) => e.topic.toLowerCase() == exam.topic.toLowerCase(),
          );

          // Check if content has actually changed
          if (existingExam.contentHash == newContentHash) {
            _log(
              'QuestionLoaderService: Content unchanged for "${exam.topic}". Skipping update.',
            );
            return;
          }

          final hasProgress = await _db.hasProgressForExam(existingExam.id!);

          if (hasProgress && !ignoreProgress) {
            _log(
              'QuestionLoaderService: Update available for "${exam.topic}" but user has progress. Flagging update.',
            );
            // Flag update available, don't overwrite
            final updatedExam = Exam(
              id: existingExam.id,
              topic: existingExam.topic,
              totalQuestions: existingExam.totalQuestions,
              timeLimitMinutes: existingExam.timeLimitMinutes,
              createdAt: existingExam.createdAt,
              isUpdateAvailable: true,
              contentHash:
                  existingExam.contentHash, // Keep old hash until updated
              category: category,
            );
            await _db.updateExam(updatedExam);
            return;
          } else {
            _log(
              'QuestionLoaderService: Updating "${exam.topic}" - overwriting existing data',
            );
            // Delete existing exam (and questions)
            await _db.deleteExamByTopic(exam.topic);
            // Proceed to re-create
          }
        } else {
          _log(
            'QuestionLoaderService: Skipping "${exam.topic}" - already loaded',
          );
          return;
        }
      }

      final examToSave = Exam(
        topic: exam.topic,
        totalQuestions: exam.totalQuestions,
        timeLimitMinutes: exam.timeLimitMinutes,
        createdAt: exam.createdAt,
        contentHash: newContentHash,
        category: category,
      );

      final savedExam = await _db.createExam(examToSave);
      final questionsWithExamId = questions
          .map(
            (q) => Question(
              examId: savedExam.id!,
              questionNumber: q.questionNumber,
              questionText: q.questionText,
              optionA: q.optionA,
              optionB: q.optionB,
              optionC: q.optionC,
              optionD: q.optionD,
              correctAnswer: q.correctAnswer,
            ),
          )
          .toList();

      await _db.createQuestionsBatch(questionsWithExamId);
      existingTopics.add(exam.topic.toLowerCase());

      _log(
        'QuestionLoaderService: Successfully loaded ${questions.length} questions for topic: ${exam.topic} from $sourceName (Category: $category)',
      );
    } else {
      _log('QuestionLoaderService: Failed to parse file: $sourceName');
    }
  }

  Map<String, dynamic>? _parseQuestions(String content, String sourceName) {
    final lines = content.split('\n');

    if (lines.isEmpty) return null;

    String? topic;
    List<Question> questions = [];

    int lineIndex = 0;

    // Parse topic (search in first 50 lines)
    int searchLimit = lines.length < 50 ? lines.length : 50;
    for (int i = 0; i < searchLimit; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty && line.startsWith('Topic:')) {
        topic = line.substring(6).trim();
        lineIndex = i + 1;
        break;
      }
    }

    // Fallback: Use filename as topic if not found
    if (topic == null) {
      _log('No "Topic:" line found in $sourceName. Using filename as topic.');
      // Extract filename from path (e.g., "exam_questions/chemistry/test.txt" -> "test")
      final parts = sourceName.split('/');
      final fileNameWithExt = parts.last;
      final fileName = fileNameWithExt.split('.').first;

      // Capitalize and format
      topic = fileName
          .split('_')
          .map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          })
          .join(' ');

      // Reset lineIndex to 0 to scan for questions from the beginning
      lineIndex = 0;
    }

    if (topic == null || topic.isEmpty) {
      _log('Failed to determine topic for file: $sourceName');
      return null;
    }

    int questionNumber = 1;

    while (lineIndex < lines.length) {
      final line = lines[lineIndex].trim();

      // Skip empty lines
      if (line.isEmpty) {
        lineIndex++;
        continue;
      }

      // Check if this is a question line (starts with number followed by dot)
      final questionMatch = RegExp(r'^(\d+)\.\s+(.+)').firstMatch(line);
      if (questionMatch != null) {
        final questionText = questionMatch.group(2)!;

        // Parse options (next 4 lines should be A, B, C, D)
        lineIndex++;
        String? optionA, optionB, optionC, optionD;

        for (int i = 0; i < 4 && lineIndex < lines.length; i++) {
          final optionLine = lines[lineIndex].trim();
          if (optionLine.startsWith('A.')) {
            optionA = optionLine.substring(2).trim();
          } else if (optionLine.startsWith('B.')) {
            optionB = optionLine.substring(2).trim();
          } else if (optionLine.startsWith('C.')) {
            optionC = optionLine.substring(2).trim();
          } else if (optionLine.startsWith('D.')) {
            optionD = optionLine.substring(2).trim();
          }
          lineIndex++;
        }

        // Parse answer (next line should be "Ans: <letter>")
        String? correctAnswer;
        if (lineIndex < lines.length) {
          final ansLine = lines[lineIndex].trim();
          if (ansLine.startsWith('Ans:')) {
            correctAnswer = ansLine.substring(4).trim();
          }
          lineIndex++;
        }

        // Create question if all parts are present
        if (optionA != null &&
            optionB != null &&
            optionC != null &&
            optionD != null &&
            correctAnswer != null) {
          questions.add(
            Question(
              examId: 0, // Will be set when saving
              questionNumber: questionNumber,
              questionText: questionText,
              optionA: optionA,
              optionB: optionB,
              optionC: optionC,
              optionD: optionD,
              correctAnswer: correctAnswer,
            ),
          );
          questionNumber++;
        }
      } else {
        lineIndex++;
      }
    }

    if (questions.isEmpty) {
      _log('No questions found in file');
      return null;
    }

    final exam = Exam(
      topic: topic,
      totalQuestions: questions.length,
      timeLimitMinutes: questions.length * 2, // 2 minutes per question
      createdAt: DateTime.now(),
    );

    return {'exam': exam, 'questions': questions};
  }

  Future<String?> updateSpecificExam(String topic, {String? category}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final indexUrl = '$REMOTE_QUESTIONS_URL/index.json?t=$timestamp';

      _log('Checking update for "$topic" from $indexUrl');

      final response = await http.get(Uri.parse(indexUrl));
      if (response.statusCode != 200)
        return 'Failed to fetch index: ${response.statusCode}';

      final List<dynamic> fileList = json.decode(response.body);

      for (final fileName in fileList) {
        if (fileName is String && fileName.endsWith('.txt')) {
          // If category is specified, skip files not in that category
          if (category != null) {
            final fileCategory = _extractCategory(fileName);
            if (fileCategory.toLowerCase() != category.toLowerCase()) {
              continue;
            }
          }

          try {
            // Fix: Handle potential double "exam_questions/"
            String cleanFileName = fileName;
            if (REMOTE_QUESTIONS_URL.endsWith('exam_questions') &&
                fileName.startsWith('exam_questions/')) {
              cleanFileName = fileName.substring('exam_questions/'.length);
            }

            final fileUrl = '$REMOTE_QUESTIONS_URL/$cleanFileName?t=$timestamp';
            final fileResponse = await http.get(Uri.parse(fileUrl));

            if (fileResponse.statusCode == 200) {
              final content = fileResponse.body;
              final lines = content.split('\n');

              // Find topic line (skip empty lines)
              String? fileTopic;
              for (final line in lines) {
                if (line.trim().isNotEmpty) {
                  if (line.trim().startsWith('Topic:')) {
                    fileTopic = line.trim().substring(6).trim();
                  }
                  break; // Stop after first non-empty line
                }
              }

              if (fileTopic != null &&
                  fileTopic.toLowerCase() == topic.toLowerCase()) {
                // Found the file! Force update.
                _log('Found matching file: $fileName for topic: $topic');
                final existingExams = await _db.getAllExams();
                final existingTopics = existingExams
                    .map((e) => e.topic.toLowerCase())
                    .toSet();
                final category = _extractCategory(fileName);

                await _processFileContent(
                  content,
                  fileName,
                  existingTopics,
                  isRemote: true,
                  forceUpdate: true,
                  ignoreProgress: true,
                  category: category,
                );
                return null; // Success (null error)
              }
            }
          } catch (e) {
            _log('Error checking file $fileName: $e');
          }
        }
      }
      return 'Exam file not found on server for topic: "$topic"';
    } catch (e) {
      _log('Error updating specific exam: $e');
      return 'Error: $e';
    }
  }
}
