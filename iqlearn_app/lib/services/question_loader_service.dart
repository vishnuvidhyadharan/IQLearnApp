import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/exam.dart';
import '../models/question.dart';
import 'database_service.dart';

class QuestionLoaderService {
  final DatabaseService _db = DatabaseService.instance;

  static const String REMOTE_QUESTIONS_URL = 'https://raw.githubusercontent.com/vishnuvidhyadharan/iqlearn/main';

  /// Load questions from remote URL and local files
  Future<void> loadQuestionsFromFile() async {
    try {
      print('QuestionLoaderService: Starting to load questions...');
      
      // Get existing exams to check which ones are already loaded
      final existingExams = await _db.getAllExams();
      final existingTopics = existingExams.map((e) => e.topic.toLowerCase()).toSet();
      print('QuestionLoaderService: Existing topics: $existingTopics');

      // 1. Try to load remote questions first
      await _loadRemoteQuestions(existingTopics);

      // 2. Load local assets as fallback/supplement
      await _loadLocalAssets(existingTopics);
      
    } catch (e) {
      print('QuestionLoaderService: Critical error loading questions: $e');
      rethrow;
    }
  }

  Future<void> _loadRemoteQuestions(Set<String> existingTopics) async {
    try {
      // Add timestamp to bypass GitHub/CDN cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final indexUrl = '$REMOTE_QUESTIONS_URL/index.json?t=$timestamp';
      
      print('QuestionLoaderService: Attempting to load remote questions from $indexUrl');
      final response = await http.get(Uri.parse(indexUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> fileList = json.decode(response.body);
        print('QuestionLoaderService: Found remote files: $fileList');
        
        for (final fileName in fileList) {
          if (fileName is String && fileName.endsWith('.txt')) {
            try {
              final fileUrl = '$REMOTE_QUESTIONS_URL/$fileName?t=$timestamp';
              final fileResponse = await http.get(Uri.parse(fileUrl));
              
              if (fileResponse.statusCode == 200) {
                // Force update: isRemote=true will trigger delete-then-insert
                await _processFileContent(fileResponse.body, fileName, existingTopics, isRemote: true, forceUpdate: true);
              } else {
                print('QuestionLoaderService: Failed to download $fileName: ${fileResponse.statusCode}');
              }
            } catch (e) {
              print('QuestionLoaderService: Error downloading $fileName: $e');
            }
          }
        }
      } else {
        print('QuestionLoaderService: Failed to fetch index.json: ${response.statusCode}');
      }
    } catch (e) {
      print('QuestionLoaderService: Remote loading failed (offline?): $e');
    }
  }

  Future<void> _loadLocalAssets(Set<String> existingTopics) async {
      // Get list of all files in exam_questions folder
      List<String> questionFiles = [];
      
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final assets = manifest.listAssets();
        questionFiles = assets
            .where((String key) => key.startsWith('exam_questions/') && key.endsWith('.txt'))
            .toList();
        print('QuestionLoaderService: Loaded via AssetManifest API: $questionFiles');
      } catch (e) {
        print('QuestionLoaderService: AssetManifest API unavailable or failed ($e). Trying JSON parsing...');
        try {
          final manifestContent = await rootBundle.loadString('AssetManifest.json');
          final Map<String, dynamic> manifestMap = json.decode(manifestContent);
          questionFiles = manifestMap.keys
              .where((String key) => key.startsWith('exam_questions/') && key.endsWith('.txt'))
              .toList();
        } catch (e2) {
          print('QuestionLoaderService: Warning - Could not load AssetManifest.json: $e2');
        }
      }
      
      // Fallback
      if (questionFiles.isEmpty) {
        print('QuestionLoaderService: No files found via manifest, trying fallback files...');
        final potentialFiles = [
          'exam_questions/history_of_india.txt',
          'exam_questions/test_quearion.txt',
          'exam_questions/sample_que.txt'
        ];
        
        for (final file in potentialFiles) {
          try {
            await rootBundle.loadString(file);
            questionFiles.add(file);
          } catch (e) {
            // Ignore missing fallbacks
          }
        }
      }
      
      for (final filePath in questionFiles) {
        try {
          final String fileContent = await rootBundle.loadString(filePath);
          await _processFileContent(fileContent, filePath, existingTopics, forceUpdate: false);
        } catch (e) {
          print('QuestionLoaderService: Error loading local file $filePath: $e');
        }
      }
  }

  String _calculateHash(String content) {
    var bytes = utf8.encode(content);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _processFileContent(String content, String sourceName, Set<String> existingTopics, {bool isRemote = false, bool forceUpdate = false, bool ignoreProgress = false}) async {
    final parsedData = _parseQuestions(content);
    
    if (parsedData != null) {
      final exam = parsedData['exam'] as Exam;
      final questions = parsedData['questions'] as List<Question>;
      final newContentHash = _calculateHash(content);
      
      // If topic exists
      if (existingTopics.contains(exam.topic.toLowerCase())) {
        if (forceUpdate) {
           // Check if there is any progress for this exam
           final existingExams = await _db.getAllExams();
           final existingExam = existingExams.firstWhere((e) => e.topic.toLowerCase() == exam.topic.toLowerCase());
           
           // Check if content has actually changed
           if (existingExam.contentHash == newContentHash) {
             print('QuestionLoaderService: Content unchanged for "${exam.topic}". Skipping update.');
             return;
           }
           
           final hasProgress = await _db.hasProgressForExam(existingExam.id!);
           
           if (hasProgress && !ignoreProgress) {
             print('QuestionLoaderService: Update available for "${exam.topic}" but user has progress. Flagging update.');
             // Flag update available, don't overwrite
             final updatedExam = Exam(
               id: existingExam.id,
               topic: existingExam.topic,
               totalQuestions: existingExam.totalQuestions,
               timeLimitMinutes: existingExam.timeLimitMinutes,
               createdAt: existingExam.createdAt,
               isUpdateAvailable: true,
               contentHash: existingExam.contentHash, // Keep old hash until updated
             );
             await _db.updateExam(updatedExam);
             return;
           } else {
             print('QuestionLoaderService: Updating "${exam.topic}" - overwriting existing data');
             // Delete existing exam (and questions)
             await _db.deleteExamByTopic(exam.topic);
             // Proceed to re-create
           }
        } else {
           print('QuestionLoaderService: Skipping "${exam.topic}" - already loaded');
           return;
        }
      }
      
      final examToSave = Exam(
        topic: exam.topic,
        totalQuestions: exam.totalQuestions,
        timeLimitMinutes: exam.timeLimitMinutes,
        createdAt: exam.createdAt,
        contentHash: newContentHash,
      );
      
      final savedExam = await _db.createExam(examToSave);
      final questionsWithExamId = questions.map((q) => Question(
        examId: savedExam.id!,
        questionNumber: q.questionNumber,
        questionText: q.questionText,
        optionA: q.optionA,
        optionB: q.optionB,
        optionC: q.optionC,
        optionD: q.optionD,
        correctAnswer: q.correctAnswer,
      )).toList();
      
      await _db.createQuestionsBatch(questionsWithExamId);
      existingTopics.add(exam.topic.toLowerCase()); 
      
      print('QuestionLoaderService: Successfully loaded ${questions.length} questions for topic: ${exam.topic} from $sourceName (${isRemote ? "Remote" : "Local"})');
    } else {
       print('QuestionLoaderService: Failed to parse file: $sourceName');
    }
  }

  Map<String, dynamic>? _parseQuestions(String content) {
    final lines = content.split('\n');
    
    if (lines.isEmpty) return null;
    
    String? topic;
    List<Question> questions = [];
    
    int lineIndex = 0;
    
    // Parse topic (first line should be "Topic: <topic_name>")
    if (lines[lineIndex].trim().startsWith('Topic:')) {
      topic = lines[lineIndex].trim().substring(6).trim();
      lineIndex++;
    }
    
    if (topic == null) {
      print('No topic found in file');
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
        if (optionA != null && optionB != null && optionC != null && optionD != null && correctAnswer != null) {
          questions.add(Question(
            examId: 0, // Will be set when saving
            questionNumber: questionNumber,
            questionText: questionText,
            optionA: optionA,
            optionB: optionB,
            optionC: optionC,
            optionD: optionD,
            correctAnswer: correctAnswer,
          ));
          questionNumber++;
        }
      } else {
        lineIndex++;
      }
    }
    
    if (questions.isEmpty) {
      print('No questions found in file');
      return null;
    }
    
    final exam = Exam(
      topic: topic,
      totalQuestions: questions.length,
      timeLimitMinutes: questions.length * 2, // 2 minutes per question
      createdAt: DateTime.now(),
    );
    
    return {
      'exam': exam,
      'questions': questions,
    };
  }

  Future<bool> updateSpecificExam(String topic) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final indexUrl = '$REMOTE_QUESTIONS_URL/index.json?t=$timestamp';
      
      final response = await http.get(Uri.parse(indexUrl));
      if (response.statusCode != 200) return false;
      
      final List<dynamic> fileList = json.decode(response.body);
      
      for (final fileName in fileList) {
        if (fileName is String && fileName.endsWith('.txt')) {
          try {
            final fileUrl = '$REMOTE_QUESTIONS_URL/$fileName?t=$timestamp';
            final fileResponse = await http.get(Uri.parse(fileUrl));
            
            if (fileResponse.statusCode == 200) {
              // Parse just the header to check topic
              final content = fileResponse.body;
              final lines = content.split('\n');
              if (lines.isNotEmpty && lines[0].trim().startsWith('Topic:')) {
                final fileTopic = lines[0].trim().substring(6).trim();
                
                if (fileTopic.toLowerCase() == topic.toLowerCase()) {
                  // Found the file! Force update.
                  final existingExams = await _db.getAllExams();
                  final existingTopics = existingExams.map((e) => e.topic.toLowerCase()).toSet();
                  
                  await _processFileContent(
                    content, 
                    fileName, 
                    existingTopics, 
                    isRemote: true, 
                    forceUpdate: true, 
                    ignoreProgress: true
                  );
                  return true;
                }
              }
            }
          } catch (e) {
            print('Error checking file $fileName: $e');
          }
        }
      }
      return false;
    } catch (e) {
      print('Error updating specific exam: $e');
      return false;
    }
  }
}
