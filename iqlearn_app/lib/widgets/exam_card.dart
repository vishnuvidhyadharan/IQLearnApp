import 'package:flutter/material.dart';

class ExamCard extends StatelessWidget {
  final String topic;
  final int totalQuestions;
  final int completedQuestions;
  final String status; // not_started, in_progress, completed
  final VoidCallback onTap;
  final bool isUpdateAvailable;
  final int? score;

  const ExamCard({
    super.key,
    required this.topic,
    required this.totalQuestions,
    required this.completedQuestions,
    required this.status,
    required this.onTap,
    this.isUpdateAvailable = false,
    this.score,
  });

  Color get _backgroundColor {
    if (status == 'completed') {
      return Colors.lightGreen.shade100;
    } else {
      return Colors.lightBlue.shade100;
    }
  }

  Color get _borderColor {
    if (status == 'completed') {
      return Colors.green.shade400;
    } else {
      return Colors.blue.shade400;
    }
  }

  IconData get _icon {
    if (status == 'completed') {
      return Icons.check_circle;
    } else if (status == 'in_progress') {
      return Icons.play_circle;
    } else {
      return Icons.assignment;
    }
  }

  Color get _iconColor {
    if (status == 'completed') {
      return Colors.green.shade700;
    } else {
      return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderColor, width: 2),
      ),
      color: _backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _icon,
                    size: 32,
                    color: _iconColor,
                  ),
                  if (isUpdateAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (status == 'completed')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        score != null ? 'Score: $score/$totalQuestions' : 'Done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                topic,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$totalQuestions Questions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalQuestions > 0 ? completedQuestions / totalQuestions : 0,
                backgroundColor: Colors.grey.shade300,
                color: status == 'completed' ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                '$completedQuestions/$totalQuestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
