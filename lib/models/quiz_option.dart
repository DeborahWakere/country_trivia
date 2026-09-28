import 'country.dart';

/// Represents a single answer option in the quiz.
class QuizOption {
  /// The country associated with this option.
  final Country country;

  /// Whether this option is the correct answer.
  final bool isCorrect;

  const QuizOption({required this.country, required this.isCorrect});
}
