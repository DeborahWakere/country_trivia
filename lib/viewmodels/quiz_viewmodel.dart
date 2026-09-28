import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../models/game_status.dart';
import '../models/quiz_option.dart';
import '../services/country_service.dart';

/// ViewModel that manages all quiz game logic and state.
///
/// Follows the MVVM pattern — exposes state via [ChangeNotifier]
/// and contains no UI dependencies.
class QuizViewModel extends ChangeNotifier {
  final CountryService countryService;
  final Random _random = Random();

  /// Points awarded per attempt: 1st = 10, 2nd = 8, 3rd = 5.
  static const List<int> _pointsTable = [10, 8, 5];

  /// Total questions per game.
  static const int questionCount = 10;

  /// Maximum attempts per question.
  static const int maxAttempts = 3;

  // ── State ──────────────────────────────────────────────────────────

  GameStatus _status = GameStatus.loading;
  List<Country> _allCountries = [];
  final Set<String> _usedCountryCodes = {};
  Country? _currentCountry;
  List<QuizOption> _options = [];
  int _score = 0;
  int _attemptsLeft = maxAttempts;
  int _currentQuestionIndex = 0;
  String? _feedbackMessage;
  bool _selectedCorrectly = false;

  // ── Getters ────────────────────────────────────────────────────────

  GameStatus get status => _status;
  Country? get currentCountry => _currentCountry;
  List<QuizOption> get options => List.unmodifiable(_options);
  int get score => _score;
  int get attemptsLeft => _attemptsLeft;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => questionCount;
  String? get feedbackMessage => _feedbackMessage;
  bool get selectedCorrectly => _selectedCorrectly;
  bool get isGameOver => _status == GameStatus.gameOver;
  bool get isLoading => _status == GameStatus.loading;

  /// Points that will be awarded if the user answers correctly
  /// on the current attempt.
  int get pointsForCurrentAttempt {
    final attemptNumber = maxAttempts - _attemptsLeft;
    return _pointsTable[attemptNumber.clamp(0, _pointsTable.length - 1)];
  }

  // ── Lifecycle ──────────────────────────────────────────────────────

  QuizViewModel({required this.countryService});

  /// Fetches countries from the API and generates the first question.
  Future<void> initialize() async {
    _status = GameStatus.loading;
    notifyListeners();

    try {
      _allCountries = await countryService.fetchCountries();
      _usedCountryCodes.clear();
      _score = 0;
      _currentQuestionIndex = 0;
      _attemptsLeft = maxAttempts;
      _generateQuestion();
    } catch (e) {
      _status = GameStatus.loading;
      _feedbackMessage = 'Failed to load countries. Please try again.';
      notifyListeners();
    }
  }

  // ── Question Generation ────────────────────────────────────────────

  /// Generates a new question with 4 options (1 correct + 3 distractors).
  ///
  /// Tracks used countries via [_usedCountryCodes] to prevent repeats.
  void _generateQuestion() {
    if (_allCountries.isEmpty) {
      _status = GameStatus.loading;
      notifyListeners();
      return;
    }

    // Filter out already-used countries
    final available = _allCountries
        .where((c) => !_usedCountryCodes.contains(c.code))
        .toList();

    // If pool is exhausted, reset and start over
    if (available.length < 4) {
      _usedCountryCodes.clear();
      available.addAll(_allCountries);
    }

    // Pick correct answer
    final correct = available[_random.nextInt(available.length)];
    _usedCountryCodes.add(correct.code);

    // Pick 3 distractors from remaining countries
    final distractors = available.where((c) => c.code != correct.code).toList();
    distractors.shuffle(_random);

    // Build options list
    final options = <QuizOption>[
      QuizOption(country: correct, isCorrect: true),
      ...distractors.take(3).map((c) => QuizOption(country: c, isCorrect: false)),
    ];
    options.shuffle(_random);

    _currentCountry = correct;
    _options = options;
    _attemptsLeft = maxAttempts;
    _selectedCorrectly = false;
    _feedbackMessage = null;
    _status = GameStatus.ready;
    notifyListeners();
  }

  // ── Answer Handling ────────────────────────────────────────────────

  /// Processes the user's answer selection.
  ///
  /// If correct: awards points and advances to next question.
  /// If wrong: decrements attempts; reveals answer when exhausted.
  void selectOption(Country selected) {
    if (_status == GameStatus.answeredCorrect ||
        _status == GameStatus.answeredWrong) {
      return; // Already answered, ignore
    }

    final isCorrect = selected.code == _currentCountry?.code;

    if (isCorrect) {
      _selectedCorrectly = true;
      _score += pointsForCurrentAttempt;
      _feedbackMessage = 'Correct! +$pointsForCurrentAttempt points';
      _status = GameStatus.answeredCorrect;
    } else {
      _attemptsLeft--;
      if (_attemptsLeft <= 0) {
        _feedbackMessage =
            'Out of attempts! The answer is ${_currentCountry?.name}';
        _status = GameStatus.answeredWrong;
      } else {
        _feedbackMessage = 'Wrong! Try again.';
        _status = GameStatus.answeredWrong;
      }
    }

    notifyListeners();
  }

  // ── Navigation ─────────────────────────────────────────────────────

  /// Advances to the next question or ends the game.
  void nextQuestion() {
    _currentQuestionIndex++;

    if (_currentQuestionIndex >= questionCount) {
      _status = GameStatus.gameOver;
      _feedbackMessage = null;
      notifyListeners();
    } else {
      _generateQuestion();
    }
  }

  // ── Game Reset ─────────────────────────────────────────────────────

  /// Resets all state for a new game.
  void resetGame() {
    _score = 0;
    _currentQuestionIndex = 0;
    _attemptsLeft = maxAttempts;
    _usedCountryCodes.clear();
    _selectedCorrectly = false;
    _feedbackMessage = null;
    _generateQuestion();
  }
}
