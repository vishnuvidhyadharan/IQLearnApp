import 'dart:async';
import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onTimerExpired;

  const TimerWidget({
    super.key,
    required this.initialSeconds,
    required this.onTimerExpired,
  });

  @override
  State<TimerWidget> createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        widget.onTimerExpired();
      }
    });
  }

  int get remainingSeconds => _remainingSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds < 300) {
      // Less than 5 minutes
      return Colors.red;
    } else if (_remainingSeconds < 600) {
      // Less than 10 minutes
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _timerColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: _timerColor, size: 20),
          const SizedBox(width: 8),
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _timerColor,
            ),
          ),
        ],
      ),
    );
  }
}
