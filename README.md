# IQ Learn

IQ Learn is a comprehensive Flutter-based quiz and exam application designed to help users master various subjects through interactive tests. It features a robust exam engine, progress tracking, and smart content updates.

## Features

*   **Categorized Exams:** Browse exams by categories such as History, Geography, Chemistry, and more.
*   **Smart Updates:** The app automatically detects content changes in exam files and updates them without losing your progress unless necessary.
*   **Offline & Remote Support:** Comes with bundled questions for offline use and supports fetching new/updated exams from a remote source (GitHub).
*   **Progress Tracking:** Tracks your scores, completed questions, and time spent on each exam.
*   **Review & Retake:** Review your answers after completing an exam or choose to retake it to improve your score.
*   **AI Integration:** (In Progress) Integration with Groq AI to provide detailed explanations for questions.

## Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.10.3 or higher)
*   Dart SDK
*   Android Studio / VS Code with Flutter extensions

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/vishnuvidhyadharan/IQLearnApp.git
    cd IQLearnApp/iqlearn_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## Adding New Exams

You can add new exams by creating simple text files.

### File Format (`.txt`)

Create a text file (e.g., `physics_test.txt`) with the following format:

```text
Topic: Physics Basics

1. What is the unit of force?
A. Joule
B. Newton
C. Watt
D. Pascal
Ans: B

2. What is the speed of light?
A. 3x10^8 m/s
B. 3x10^6 m/s
C. 3x10^5 km/s
D. Both A and C
Ans: D
```

### Steps to Add:

1.  Place the `.txt` file in the appropriate folder under `exam_questions/` (e.g., `exam_questions/physics/`).
2.  If adding a new folder, ensure it is listed in `pubspec.yaml` under `assets`.
3.  Update `exam_questions/index.json` if you want it to be discoverable via remote updates.

## Project Structure

*   `lib/models/`: Data models (Exam, Question, User, etc.)
*   `lib/screens/`: UI Screens (Home, Exam, Auth, etc.)
*   `lib/services/`: Business logic and services (Database, Auth, QuestionLoader)
*   `lib/widgets/`: Reusable UI components
*   `exam_questions/`: Text files containing exam data organized by category.

## Technologies Used

*   **Flutter & Dart**
*   **SQLite (sqflite):** Local database for storing exams and progress.
*   **Provider:** State management.
*   **http:** For fetching remote updates.
*   **crypto:** For calculating content hashes to detect updates.

## License

[MIT License](LICENSE)
