import '../models/question.dart';

class MCQParser {
  static ParseResult parse(String input, {String? filename}) {
    try {
      final lines = input.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isEmpty) {
        return ParseResult(success: false, error: 'Input is empty');
      }

      // Extract topic
      String topic = '';
      int searchLimit = lines.length < 50 ? lines.length : 50;
      int topicLineIndex = -1;

      for (int i = 0; i < searchLimit; i++) {
        if (lines[i].toLowerCase().startsWith('topic:')) {
          topic = lines[i].substring(6).trim();
          topicLineIndex = i;
          break;
        }
      }

      if (topic.isEmpty) {
        if (filename != null) {
           // Fallback to filename
           final parts = filename.split('/');
           final fileNameWithExt = parts.last;
           final nameOnly = fileNameWithExt.split('.').first;
           
           topic = nameOnly.split('_').map((word) {
             if (word.isEmpty) return '';
             return word[0].toUpperCase() + word.substring(1);
           }).join(' ');
        } else {
           return ParseResult(success: false, error: 'Topic not found. First line should start with "Topic:" or filename must be provided.');
        }
      } else {
        // If topic found in file, remove that line so we don't parse it as a question
        lines.removeAt(topicLineIndex);
      }

      List<ParsedQuestion> questions = [];
      int currentIndex = 0;

      while (currentIndex < lines.length) {
        // Find question number (e.g., "1.", "2.", etc.)
        if (!lines[currentIndex].trim().matches(RegExp(r'^\d+\.'))) {
          currentIndex++;
          continue;
        }

        String questionLine = lines[currentIndex];
        // Extract question number and text
        final questionMatch = RegExp(r'^(\d+)\.\s*(.+)').firstMatch(questionLine);
        if (questionMatch == null) {
          currentIndex++;
          continue;
        }

        int questionNumber = int.parse(questionMatch.group(1)!);
        String questionText = questionMatch.group(2)!.trim();
        
        currentIndex++;

        // Extract options A, B, C, D
        String optionA = '';
        String optionB = '';
        String optionC = '';
        String optionD = '';
        String correctAnswer = '';

        // Continue reading lines for options and answer
        while (currentIndex < lines.length) {
          String line = lines[currentIndex].trim();
          
          // Check if we've reached the next question
          if (line.matches(RegExp(r'^\d+\.'))) {
            break;
          }

          if (line.startsWith('A.') || line.startsWith('A ')) {
            optionA = line.substring(2).trim();
          } else if (line.startsWith('B.') || line.startsWith('B ')) {
            optionB = line.substring(2).trim();
          } else if (line.startsWith('C.') || line.startsWith('C ')) {
            optionC = line.substring(2).trim();
          } else if (line.startsWith('D.') || line.startsWith('D ')) {
            optionD = line.substring(2).trim();
          } else if (line.toLowerCase().startsWith('ans:') || line.toLowerCase().startsWith('answer:')) {
            final answerPart = line.contains(':') ? line.split(':')[1].trim() : '';
            correctAnswer = answerPart.toUpperCase();
            currentIndex++;
            break;
          }
          
          currentIndex++;
        }

        // Validate question
        if (questionText.isEmpty || optionA.isEmpty || optionB.isEmpty || 
            optionC.isEmpty || optionD.isEmpty || correctAnswer.isEmpty) {
          return ParseResult(
            success: false,
            error: 'Incomplete question at number $questionNumber',
          );
        }

        if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
          return ParseResult(
            success: false,
            error: 'Invalid answer "$correctAnswer" for question $questionNumber. Must be A, B, C, or D.',
          );
        }

        questions.add(ParsedQuestion(
          questionNumber: questionNumber,
          questionText: questionText,
          optionA: optionA,
          optionB: optionB,
          optionC: optionC,
          optionD: optionD,
          correctAnswer: correctAnswer,
        ));
      }

      if (questions.isEmpty) {
        return ParseResult(success: false, error: 'No valid questions found');
      }

      return ParseResult(
        success: true,
        topic: topic,
        questions: questions,
      );
    } catch (e) {
      return ParseResult(success: false, error: 'Parsing error: ${e.toString()}');
    }
  }
}

class ParseResult {
  final bool success;
  final String? error;
  final String? topic;
  final List<ParsedQuestion>? questions;

  ParseResult({
    required this.success,
    this.error,
    this.topic,
    this.questions,
  });
}

class ParsedQuestion {
  final int questionNumber;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;

  ParsedQuestion({
    required this.questionNumber,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
  });

  Question toQuestion(int examId) {
    return Question(
      examId: examId,
      questionNumber: questionNumber,
      questionText: questionText,
      optionA: optionA,
      optionB: optionB,
      optionC: optionC,
      optionD: optionD,
      correctAnswer: correctAnswer,
    );
  }
}

extension StringExtension on String {
  bool matches(RegExp regex) {
    return regex.hasMatch(this);
  }
}
