import 'package:flutter/material.dart';

/// Displays the current score, question progress, and remaining attempts.
class ScoreBoard extends StatelessWidget {
  /// Current score.
  final int score;

  /// Current question number (1-based).
  final int currentQuestion;

  /// Total number of questions.
  final int totalQuestions;

  /// Number of attempts remaining.
  final int attemptsLeft;

  /// Maximum attempts per question.
  final int maxAttempts;

  const ScoreBoard({
    super.key,
    required this.score,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.attemptsLeft,
    this.maxAttempts = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          _buildStat(
            context,
            icon: Icons.stars_rounded,
            label: 'Score',
            value: '$score',
            color: Colors.amber.shade700,
          ),

          // Question progress
          _buildStat(
            context,
            icon: Icons.quiz_outlined,
            label: 'Question',
            value: '$currentQuestion/$totalQuestions',
            color: theme.colorScheme.primary,
          ),

          // Attempts remaining
          _buildAttempts(context),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildAttempts(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxAttempts, (index) {
            final isActive = index < attemptsLeft;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.favorite_rounded,
                size: 24,
                color: isActive
                    ? Colors.red.shade400
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Attempts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
