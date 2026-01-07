import 'package:flutter_test/flutter_test.dart';
import 'package:iqlearn_app/utils/mcq_parser.dart';

void main() {
  group('MCQParser Tests', () {
    test('Parses standard file with Topic at the beginning', () {
      final content = '''
Topic: General Knowledge

1. What is the capital of France?
A. London
B. Paris
C. Berlin
D. Madrid
Ans: B
''';
      final result = MCQParser.parse(content);
      expect(result.success, isTrue);
      expect(result.topic, equals('General Knowledge'));
      expect(result.questions?.length, equals(1));
      expect(result.questions?.first.questionText, equals('What is the capital of France?'));
    });

    test('Parses file with Topic after some introductory text', () {
      final content = '''
Introduction to History
This is a sample file.

Topic: History

1. Who was the first President of USA?
A. Lincoln
B. Washington
C. Jefferson
D. Adams
Ans: B
''';
      final result = MCQParser.parse(content);
      expect(result.success, isTrue);
      expect(result.topic, equals('History'));
      expect(result.questions?.length, equals(1));
    });

    test('Falls back to filename when Topic is missing', () {
      final content = '''
Introduction to Chemistry
No topic line here.

1. What is H2O?
A. Gold
B. Silver
C. Water
D. Iron
Ans: C
''';
      final result = MCQParser.parse(content, filename: 'exam_questions/chemistry/basic_chemistry.txt');
      expect(result.success, isTrue);
      expect(result.topic, equals('Basic Chemistry'));
      expect(result.questions?.length, equals(1));
    });

    test('Fails when Topic is missing and no filename provided', () {
      final content = '''
Introduction to Physics
No topic line here.

1. What is E=mc^2?
A. Newton's Law
B. Einstein's Theory
C. Boyle's Law
D. Ohm's Law
Ans: B
''';
      final result = MCQParser.parse(content);
      expect(result.success, isFalse);
      expect(result.error, contains('Topic not found'));
    });
  });
}
