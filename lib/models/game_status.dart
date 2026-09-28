/// Represents the current state of the quiz game.
enum GameStatus {
  /// Fetching countries from the API.
  loading,

  /// Ready to display a question.
  ready,

  /// User selected the correct answer.
  answeredCorrect,

  /// User selected a wrong answer.
  answeredWrong,

  /// All questions have been answered.
  gameOver,
}
