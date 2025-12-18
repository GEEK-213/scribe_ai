import 'package:flutter/material.dart';

class QuizView extends StatefulWidget {
  final List<dynamic> questions;

  const QuizView({super.key, required this.questions});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  int _correctOptionIndex = -1; 

  @override
  void initState() {
    super.initState();
    _determineCorrectAnswer();
  }

  void _determineCorrectAnswer() {
    final question = widget.questions[_currentIndex];
    final rawAnswer = question['answer'].toString().trim().toUpperCase();
    final options = List<String>.from(question['options']);

    // Reset default
    _correctOptionIndex = 0;

    // Strategy 1: Match text
    for (int i = 0; i < options.length; i++) {
      if (options[i].toUpperCase().trim() == rawAnswer) {
        setState(() => _correctOptionIndex = i);
        return;
      }
    }

    // Strategy 2: Match Letter (A, B, C...)
    if (rawAnswer.length == 1) {
      int letterIndex = rawAnswer.codeUnitAt(0) - 65; 
      if (letterIndex >= 0 && letterIndex < options.length) {
        setState(() => _correctOptionIndex = letterIndex);
        return;
      }
    }
    
    // Strategy 3: Handle "Option A"
    if (rawAnswer.startsWith("OPTION ")) {
       String letter = rawAnswer.split(" ").last;
       int letterIndex = letter.codeUnitAt(0) - 65;
       if (letterIndex >= 0 && letterIndex < options.length) {
         setState(() => _correctOptionIndex = letterIndex);
         return;
       }
    }
  }

  void _answerQuestion(int optionIndex) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = optionIndex;
      if (optionIndex == _correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _isAnswered = false;
      _selectedOptionIndex = null;
    });
    if (_currentIndex < widget.questions.length) {
      _determineCorrectAnswer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.questions.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            Text("Quiz Completed!", style: Theme.of(context).textTheme.headlineMedium),
            Text("Score: $_score / ${widget.questions.length}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _score = 0;
                  _isAnswered = false;
                  _determineCorrectAnswer();
                });
              },
              child: const Text("Restart Quiz"),
            )
          ],
        ),
      );
    }

    final question = widget.questions[_currentIndex];
    final options = List<String>.from(question['options']);

    // --- SCROLLABLE FIX ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Colors.blue),
          ),
          const SizedBox(height: 20),
          Text("Question ${_currentIndex + 1}",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(question['question'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          ...List.generate(options.length, (index) {
            final letter = String.fromCharCode(65 + index);
            Color color = Colors.white;
            Color borderColor = Colors.grey;

            if (_isAnswered) {
              if (index == _correctOptionIndex) {
                color = Colors.green.shade100;
                borderColor = Colors.green;
              } else if (index == _selectedOptionIndex) {
                color = Colors.red.shade100;
                borderColor = Colors.red;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _answerQuestion(index),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: borderColor.withOpacity(0.2),
                        child: Text(letter, 
                            style: TextStyle(color: borderColor, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(options[index])),
                      if (_isAnswered && index == _correctOptionIndex)
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (_isAnswered && index == _selectedOptionIndex && index != _correctOptionIndex)
                        const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 20), 

          if (_isAnswered)
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
              child: Text(_currentIndex == widget.questions.length - 1
                  ? "Finish"
                  : "Next Question"),
            ),
        ],
      ),
    );
  }
}