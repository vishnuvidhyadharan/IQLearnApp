import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';
import 'groq_service.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _db = DatabaseService.instance;
  
  User? _currentUser;

  User? get currentUser => _currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      _currentUser = await _db.getUser(userId);
      
      // Initialize Groq service if key exists
      if (_currentUser?.groqApiKey != null) {
        GroqService().initialize(_currentUser!.groqApiKey!);
      }
      
      return _currentUser != null;
    }
    return false;
  }

  // Create user profile with name and email
  Future<bool> createUserProfile({
    required String name,
    required String email,
  }) async {
    try {
      // Check if user with this email already exists
      var user = await _db.getUserByEmail(email);
      
      if (user == null) {
        // Create new user
        user = await _db.createUser(User(
          email: email,
          name: name,
          createdAt: DateTime.now(),
        ));
      }

      // Set as current user
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id!);
      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _currentUser = null;
  }

  // Update user's Groq API key
  Future<void> updateApiKey(String apiKey) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(groqApiKey: apiKey);
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      // Initialize Groq service
      GroqService().initialize(apiKey);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? name, String? email}) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
      );
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
    }
  }
}
