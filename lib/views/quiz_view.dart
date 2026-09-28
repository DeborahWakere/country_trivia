import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_status.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../widgets/flag_display.dart';
import '../widgets/option_button.dart';
import '../widgets/result_overlay.dart';
import '../widgets/score_board.dart';

/// Main quiz screen displaying flag, options, and score.
class QuizView extends StatelessWidget {
  const QuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Trivia'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<QuizViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.isGameOver) {
            return _buildGameOver(context, viewModel);
          }

          return _buildQuizContent(context, viewModel);
        },
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizViewModel viewModel) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Score board
                ScoreBoard(
                  score: viewModel.score,
                  currentQuestion: viewModel.currentQuestionIndex + 1,
                  totalQuestions: viewModel.totalQuestions,
                  attemptsLeft: viewModel.attemptsLeft,
                ),
                const SizedBox(height: 24),

                // Flag
                if (viewModel.currentCountry != null)
                  FlagDisplay(flagUrl: viewModel.currentCountry!.flagUrl),
                const SizedBox(height: 24),

                // Prompt
                Text(
                  'Which country is this?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Options grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: viewModel.options.length,
                    itemBuilder: (context, index) {
                      final option = viewModel.options[index];
                      final isAnswered = viewModel.status ==
                              GameStatus.answeredCorrect ||
                          viewModel.status == GameStatus.answeredWrong;

                      return OptionButton(
                        label: option.country.name,
                        isCorrect: option.isCorrect,
                        isSelected: isAnswered &&
                            (option.isCorrect ||
                                viewModel.selectedCorrectly == false),
                        isDisabled: isAnswered && !option.isCorrect,
                        onTap: () {
                          viewModel.selectOption(option.country);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Result overlay
        if (viewModel.status == GameStatus.answeredCorrect ||
            (viewModel.status == GameStatus.answeredWrong &&
                viewModel.attemptsLeft <= 0))
          ResultOverlay(
            isCorrect: viewModel.selectedCorrectly,
            message: viewModel.feedbackMessage ?? '',
            showNext: true,
            onNext: () {
              viewModel.nextQuestion();
            },
          ),
      ],
    );
  }

  Widget _buildGameOver(BuildContext context, QuizViewModel viewModel) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: Colors.amber.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Game Over!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Final Score',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${viewModel.score}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    viewModel.resetGame();
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay_rounded, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
