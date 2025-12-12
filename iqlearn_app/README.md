# IQ Learn - MCQ Examination App

A comprehensive Flutter-based learning application that provides MCQ (Multiple Choice Question) examinations with AI-powered explanations and chat functionality.

## Features

### 🔐 Authentication
- OTP-based login using email or mobile number
- Secure session management
- Auto-login on app restart

### 📚 Exam Management
- Color-coded exam list:
  - **Light Blue**: Not started or in progress
  - **Light Green**: Completed
- Progress tracking (e.g., 45/100 questions answered)
- Tiled/grid layout for easy browsing

### ⏱️ Exam Taking
- Countdown timer displayed in top-right corner
- Color-coded timer warnings (red < 5 min, orange < 10 min)
- Radio button options for answers
- Mark questions for review
- Auto-save progress
- Navigation between questions
- Auto-submit when timer expires

### 📊 Results & Review
- Visual score display with pie chart
- Review all questions or only incorrect ones
- Side-by-side comparison of user answer vs correct answer
- AI-powered explanations for each question

### 🤖 AI Integration
- Gemini AI for question explanations
- General chat interface
- User-configurable API key in profile

### 👤 User Profile
- View user information
- Manage Gemini API key
- Secure storage of credentials

### 🔧 Admin Features
- Add question sets in MCQ text format
- Preview questions before saving
- Batch upload to database

## Installation

### Prerequisites

1. **Flutter SDK** (3.0 or higher)
   ```bash
   flutter doctor
   ```

2. **Firebase Account** (for OTP authentication)
   - Create a project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Phone Authentication and Email Link Authentication

3. **Gemini API Key** (for AI features)
   - Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Setup Steps

1. **Clone or navigate to the project**
   ```bash
   cd /home/vishnu/IQLearn/iqlearn_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   For Android:
   ```bash
   # Download google-services.json from Firebase Console
   # Place it in android/app/
   ```
   
   For iOS:
   ```bash
   # Download GoogleService-Info.plist from Firebase Console
   # Place it in ios/Runner/
   ```

4. **Enable Firebase in main.dart**
   
   Open `lib/main.dart` and uncomment:
   ```dart
   await Firebase.initializeApp();
   ```

5. **Configure Firebase Authentication**
   
   In Firebase Console:
   - Enable Phone Authentication
   - Enable Email Link Authentication
   - Add authorized domains
   - Configure dynamic links for email verification

6. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### For Users

1. **Login**
   - Choose email or mobile authentication
   - Enter your email/phone number
   - Verify with OTP

2. **Browse Exams**
   - View available exams on home screen
   - Blue cards = not started/in progress
   - Green cards = completed

3. **Take an Exam**
   - Tap an exam card to start
   - Answer questions using radio buttons
   - Mark questions for review if needed
   - Submit when done or when timer expires

4. **View Results**
   - See your score and percentage
   - Review incorrect answers
   - Get AI explanations for any question

5. **Add API Key**
   - Go to Profile
   - Enter your Gemini API key
   - Use AI features (explanations & chat)

6. **Chat with AI**
   - Tap chat icon in home screen
   - Ask questions on any topic
   - Get instant AI responses

### For Admins

1. **Add Questions**
   - Tap the "Add Exam" button on home screen
   - Paste questions in MCQ format:
     ```
     Topic: Your Topic Name

     1. Question text?
     A. Option A
     B. Option B
     C. Option C
     D. Option D
     Ans: A

     2. Next question?
     ...
     ```
   - Preview parsed questions
   - Save to database

## MCQ Format

Questions must follow this exact format:

```
Topic: Subject Name

1. Question text here?
A. First option
B. Second option
C. Third option
D. Fourth option
Ans: A

2. Next question text?
A. First option
B. Second option
C. Third option
D. Fourth option
Ans: B
```

**Important:**
- Start with `Topic:` followed by the topic name
- Number questions sequentially (1., 2., 3., etc.)
- Options must be labeled A, B, C, D
- Answer must be specified as `Ans:` followed by the letter
- Leave blank lines between questions for better readability

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── exam.dart
│   ├── question.dart
│   ├── user_exam_progress.dart
│   └── user_answer.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── auth_service.dart
│   └── gemini_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── otp_verification_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── exam/
│   │   ├── exam_screen.dart
│   │   └── results_screen.dart
│   ├── chat/
│   │   └── chat_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── admin/
│       └── add_questions_screen.dart
├── widgets/                  # Reusable widgets
│   ├── exam_card.dart
│   ├── timer_widget.dart
│   └── question_widget.dart
└── utils/                    # Utilities
    └── mcq_parser.dart
```

## Database Schema

### Tables

1. **users**
   - id, email, mobile, name, gemini_api_key, created_at

2. **exams**
   - id, topic, total_questions, time_limit_minutes, created_at

3. **questions**
   - id, exam_id, question_number, question_text, option_a, option_b, option_c, option_d, correct_answer

4. **user_exam_progress**
   - id, user_id, exam_id, status, completed_questions, score, started_at, completed_at, time_remaining_seconds

5. **user_answers**
   - id, user_id, exam_id, question_id, selected_answer, is_correct, marked_for_review, answered_at

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **SQLite**: Local database (sqflite)
- **Firebase Authentication**: OTP verification
- **Google Gemini AI**: Question explanations and chat
- **Provider**: State management
- **FL Chart**: Data visualization

## Troubleshooting

### Firebase Issues
- Make sure you've added google-services.json (Android) or GoogleService-Info.plist (iOS)
- Verify Firebase project configuration
- Check that authentication methods are enabled

### OTP Not Received
- Verify phone number format includes country code (e.g., +91)
- Check Firebase Console for authentication logs
- Ensure you're not in test mode with quota limits

### Gemini API Errors
- Verify API key is correct
- Check API key hasn't exceeded quota
- Ensure internet connection is stable

### Database Errors
- Clear app data and restart
- Check permissions for file storage
- Verify database schema is created correctly

## Future Enhancements

- [ ] Offline mode for exams
- [ ] Leaderboards and achievements
- [ ] Multiple language support
- [ ] Dark mode
- [ ] Export results as PDF
- [ ] Question difficulty levels
- [ ] Timed practice mode
- [ ] Social sharing of scores

## License

This project is for educational purposes.

## Support

For issues or questions, please contact the developer.
