import 'package:flutter/material.dart';
import '../../models/question.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool markedForReview;
  final Function(String) onAnswerSelected;
  final Function(bool) onMarkForReview;

  const QuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    required this.markedForReview,
    required this.onAnswerSelected,
    required this.onMarkForReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            ...['A', 'B', 'C', 'D'].map((option) {
              final isSelected = selectedAnswer == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onAnswerSelected(option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade100
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade300,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$option. ${question.options[option]}',
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Mark for review checkbox
            Row(
              children: [
                Checkbox(
                  value: markedForReview,
                  onChanged: (value) => onMarkForReview(value ?? false),
                ),
                const Text(
                  'Mark for Review',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
