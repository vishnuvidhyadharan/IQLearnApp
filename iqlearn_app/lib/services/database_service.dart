import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/user.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/user_exam_progress.dart';
import '../models/user_answer.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iqlearn.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // For web platform, use in-memory database
    if (kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      return await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    }
    
    // For mobile platforms (Android/iOS), use native sqflite
    if (Platform.isAndroid || Platform.isIOS) {
      // Use path_provider to get the application directory
      final appDir = await getApplicationDocumentsDirectory();
      final path = join(appDir.path, filePath);

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    }
    
    // For desktop platforms (Linux, Windows, macOS), use sqflite_ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final appDir = await getApplicationDocumentsDirectory();
    final path = join(appDir.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE exams ADD COLUMN category TEXT DEFAULT 'General'");
      } catch (e) {
        print('Migration error (ignoring if column exists): $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';
    const intTypeNullable = 'INTEGER';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textTypeNullable UNIQUE,
        mobile $textTypeNullable UNIQUE,
        name $textTypeNullable,
        groq_api_key $textTypeNullable,
        created_at $textTypeNullable
      )
    ''');

    // Exams table
    await db.execute('''
      CREATE TABLE exams (
        id $idType,
        topic $textType,
        total_questions INTEGER DEFAULT 100,
        time_limit_minutes INTEGER DEFAULT 120,
        created_at $textTypeNullable,
        is_update_available INTEGER DEFAULT 0,
        content_hash $textTypeNullable,
        category TEXT DEFAULT 'General'
      )
    ''');

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id $idType,
        exam_id $intType,
        question_number $intType,
        question_text $textType,
        option_a $textType,
        option_b $textType,
        option_c $textType,
        option_d $textType,
        correct_answer $textType,
        FOREIGN KEY (exam_id) REFERENCES exams(id)
      )
    ''');

    // User Exam Progress table
    await db.execute('''
      CREATE TABLE user_exam_progress (
        id $idType,
        user_id $intType,
        exam_id $intType,
        status TEXT DEFAULT 'not_started',
        completed_questions INTEGER DEFAULT 0,
        score $intTypeNullable,
        started_at $textTypeNullable,
        completed_at $textTypeNullable,
        time_remaining_seconds $intTypeNullable,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (exam_id) REFERENCES exams(id),
        UNIQUE(user_id, exam_id)
      )
    ''');

    // User Answers table
    await db.execute('''
      CREATE TABLE user_answers (
        id $idType,
        user_id $intType,
        exam_id $intType,
        question_id $intType,
        selected_answer $textTypeNullable,
        is_correct INTEGER DEFAULT 0,
        marked_for_review INTEGER DEFAULT 0,
        answered_at $textTypeNullable,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (exam_id) REFERENCES exams(id),
        FOREIGN KEY (question_id) REFERENCES questions(id),
        UNIQUE(user_id, exam_id, question_id)
      )
    ''');
  }

  // ==================== USER CRUD ====================
  
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByMobile(String mobile) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'mobile = ?',
      whereArgs: [mobile],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== EXAM CRUD ====================
  
  Future<Exam> createExam(Exam exam) async {
    final db = await database;
    final id = await db.insert('exams', exam.toMap());
    return Exam(
      id: id,
      topic: exam.topic,
      totalQuestions: exam.totalQuestions,
      timeLimitMinutes: exam.timeLimitMinutes,
      createdAt: exam.createdAt,
      isUpdateAvailable: exam.isUpdateAvailable,
      contentHash: exam.contentHash,
      category: exam.category,
    );
  }

  Future<List<Exam>> getAllExams() async {
    final db = await database;
    final result = await db.query('exams', orderBy: 'created_at DESC');
    return result.map((json) => Exam.fromMap(json)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM exams ORDER BY category ASC');
    return result.map((row) => row['category'] as String).toList();
  }

  Future<List<Exam>> getExamsByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'exams', 
      where: 'category = ?', 
      whereArgs: [category],
      orderBy: 'created_at DESC'
    );
    return result.map((json) => Exam.fromMap(json)).toList();
  }

  Future<Exam?> getExam(int id) async {
    final db = await database;
    final maps = await db.query(
      'exams',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Exam.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExam(Exam exam) async {
    final db = await database;
    return db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(int id) async {
    final db = await database;
    // Also delete related questions, progress, and answers
    await db.delete('questions', where: 'exam_id = ?', whereArgs: [id]);
    await db.delete('user_exam_progress', where: 'exam_id = ?', whereArgs: [id]);
    await db.delete('user_answers', where: 'exam_id = ?', whereArgs: [id]);
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExamByTopic(String topic) async {
    final db = await database;
    final maps = await db.query(
      'exams',
      where: 'topic = ?',
      whereArgs: [topic],
    );
    
    if (maps.isNotEmpty) {
      final id = maps.first['id'] as int;
      await deleteExam(id);
    }
  }

  // ==================== QUESTION CRUD ====================
  
  Future<Question> createQuestion(Question question) async {
    final db = await database;
    final id = await db.insert('questions', question.toMap());
    return Question(
      id: id,
      examId: question.examId,
      questionNumber: question.questionNumber,
      questionText: question.questionText,
      optionA: question.optionA,
      optionB: question.optionB,
      optionC: question.optionC,
      optionD: question.optionD,
      correctAnswer: question.correctAnswer,
    );
  }

  Future<void> createQuestionsBatch(List<Question> questions) async {
    final db = await database;
    final batch = db.batch();
    for (var question in questions) {
      batch.insert('questions', question.toMap());
    }
    await batch.commit();
  }

  Future<List<Question>> getQuestionsByExam(int examId) async {
    final db = await database;
    final result = await db.query(
      'questions',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'question_number ASC',
    );
    return result.map((json) => Question.fromMap(json)).toList();
  }

  Future<Question?> getQuestion(int id) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Question.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    return db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== USER EXAM PROGRESS CRUD ====================
  
  Future<UserExamProgress> createOrUpdateProgress(UserExamProgress progress) async {
    final db = await database;
    
    // Check if progress exists
    final existing = await db.query(
      'user_exam_progress',
      where: 'user_id = ? AND exam_id = ?',
      whereArgs: [progress.userId, progress.examId],
    );

    if (existing.isNotEmpty) {
      // Update existing progress
      await db.update(
        'user_exam_progress',
        progress.toMap(),
        where: 'user_id = ? AND exam_id = ?',
        whereArgs: [progress.userId, progress.examId],
      );
      return progress.copyWith(id: existing.first['id'] as int);
    } else {
      // Create new progress
      final id = await db.insert('user_exam_progress', progress.toMap());
      return progress.copyWith(id: id);
    }
  }

  Future<UserExamProgress?> getProgress(int userId, int examId) async {
    final db = await database;
    final maps = await db.query(
      'user_exam_progress',
      where: 'user_id = ? AND exam_id = ?',
      whereArgs: [userId, examId],
    );
    if (maps.isNotEmpty) {
      return UserExamProgress.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserExamProgress>> getAllProgressForUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_exam_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((json) => UserExamProgress.fromMap(json)).toList();
  }

  Future<int> deleteProgress(int userId, int examId) async {
    final db = await database;
    return await db.delete(
      'user_exam_progress',
      where: 'user_id = ? AND exam_id = ?',
      whereArgs: [userId, examId],
    );
  }

  Future<bool> hasProgressForExam(int examId) async {
    final db = await database;
    final result = await db.query(
      'user_exam_progress',
      where: 'exam_id = ?',
      whereArgs: [examId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ==================== USER ANSWER CRUD ====================
  
  Future<UserAnswer> createOrUpdateAnswer(UserAnswer answer) async {
    final db = await database;
    
    // Check if answer exists
    final existing = await db.query(
      'user_answers',
      where: 'user_id = ? AND exam_id = ? AND question_id = ?',
      whereArgs: [answer.userId, answer.examId, answer.questionId],
    );

    if (existing.isNotEmpty) {
      // Update existing answer
      await db.update(
        'user_answers',
        answer.toMap(),
        where: 'user_id = ? AND exam_id = ? AND question_id = ?',
        whereArgs: [answer.userId, answer.examId, answer.questionId],
      );
      return answer.copyWith(id: existing.first['id'] as int);
    } else {
      // Create new answer
      final id = await db.insert('user_answers', answer.toMap());
      return answer.copyWith(id: id);
    }
  }

  Future<List<UserAnswer>> getAnswersByUserAndExam(int userId, int examId) async {
    final db = await database;
    final result = await db.query(
      'user_answers',
      where: 'user_id = ? AND exam_id = ?',
      whereArgs: [userId, examId],
    );
    return result.map((json) => UserAnswer.fromMap(json)).toList();
  }

  Future<UserAnswer?> getAnswer(int userId, int examId, int questionId) async {
    final db = await database;
    final maps = await db.query(
      'user_answers',
      where: 'user_id = ? AND exam_id = ? AND question_id = ?',
      whereArgs: [userId, examId, questionId],
    );
    if (maps.isNotEmpty) {
      return UserAnswer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAnswer(int userId, int examId, int questionId) async {
    final db = await database;
    return await db.delete(
      'user_answers',
      where: 'user_id = ? AND exam_id = ? AND question_id = ?',
      whereArgs: [userId, examId, questionId],
    );
  }

  Future<int> deleteUserAnswers(int userId, int examId) async {
    final db = await database;
    return await db.delete(
      'user_answers',
      where: 'user_id = ? AND exam_id = ?',
      whereArgs: [userId, examId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
