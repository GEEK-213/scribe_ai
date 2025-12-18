import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuizView extends StatefulWidget {
  final List<dynamic> questions;

  const QuizView({super.key, required this.questions});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedOption;
  bool _isAnswered = false;

  void _checkAnswer(String option) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      
      // Extract just the letter (A/B/C/D) to compare
      String correctAnswerLetter = widget.questions[_currentIndex]['answer'].toString().split(' ').first;
      String selectedLetter = option.split(' ').first;

      if (selectedLetter == correctAnswerLetter) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _isAnswered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.questions.length) {
      return _buildResultView();
    }

    final currentQuestion = widget.questions[_currentIndex];
    final options = List<String>.from(currentQuestion['options']);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. PROGRESS TEXT
          Text(
            "Question ${_currentIndex + 1} of ${widget.questions.length}",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 2. QUESTION CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
              ],
            ),
            child: Text(
              currentQuestion['question'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          
          const SizedBox(height: 30),

          // 3. OPTIONS LIST
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                bool isCorrect = option.startsWith(currentQuestion['answer'].toString().split(' ').first);
                bool isSelected = _selectedOption == option;

                // Color Logic
                Color borderColor = Colors.grey.shade200;
                Color bgColor = Colors.white;
                if (_isAnswered) {
                  if (isCorrect) {
                    borderColor = Colors.green;
                    bgColor = Colors.green.shade50;
                  } else if (isSelected) {
                    borderColor = Colors.red;
                    bgColor = Colors.red.shade50;
                  }
                }

                return GestureDetector(
                  onTap: () => _checkAnswer(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Text(
                          option.substring(0, 2), // The "A) " part
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            option.substring(2), // The actual text
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        if (_isAnswered && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (_isAnswered && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. NEXT BUTTON
          if (_isAnswered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text("Next Question"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20)]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("Quiz Finished!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "You scored $_score out of ${widget.questions.length}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Lecture"),
            ),
          ],
        ),
      ),
    );
  }
}