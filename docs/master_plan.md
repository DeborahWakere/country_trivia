# Country Trivia — Master Plan & Architecture

## 1. Overview

A Flutter trivia game where the user is shown a country flag and must pick the correct country name from 4 options. The game uses a 3-attempt scoring system (10 / 8 / 5 points) and reveals the correct answer after all attempts are exhausted.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.13.1) |
| State Management | **Provider** (ChangeNotifier pattern) |
| HTTP Client | `http` package |
| Architecture | **MVVM** (Model – View – ViewModel) |
| Testing | `flutter_test`, `mocktail` (for unit/widget tests) |

---

## 3. Data Sources

### 3.1 Country Data API
- **Endpoint:** `GET https://restcountries.com/v3.1/all?fields=name,cca2`
- **Response:** JSON array of country objects
- **Key fields:**
  - `name.common` — display name (e.g. "Germany")
  - `cca2` — 2-letter ISO code (e.g. "DE")

### 3.2 Flag Images
- **URL pattern:** `https://flagcdn.com/w320/{cca2_lowercase}.png`
- **Example:** `https://flagcdn.com/w320/de.png`

---

## 4. MVVM Architecture

```
lib/
├── main.dart                          # App entry, Provider setup
├── app.dart                           # MaterialApp + theme
│
├── models/
│   └── country.dart                   # Country data model
│
├── services/
│   └── country_service.dart           # HTTP API calls (Repository)
│
├── viewmodels/
│   └── quiz_viewmodel.dart            # Quiz game logic & state
│
├── views/
│   ├── home_view.dart                 # Home / start screen
│   └── quiz_view.dart                 # Main quiz screen
│
└── widgets/
    ├── flag_display.dart              # Flag image widget
    ├── option_button.dart             # Answer option button
    ├── score_board.dart               # Score display
    └── result_overlay.dart            # Correct/wrong feedback overlay
```

### 4.1 Layer Responsibilities

| Layer | Responsibility |
|---|---|
| **Model** | Plain Dart classes representing data (`Country`). Immutable, JSON (de)serializable. |
| **Service** | Handles all network I/O. Fetches country list from REST API. No UI knowledge. |
| **ViewModel** | Holds game state, business logic (scoring, attempt tracking, answer generation). Exposes state via `ChangeNotifier`. |
| **View** | Pure UI. Listens to ViewModel via `Consumer`/`context.watch`. No business logic. |
| **Widgets** | Reusable, stateless UI components. |

---

## 5. Data Models

### 5.1 `Country`
```dart
class Country {
  final String name;    // name.common
  final String code;    // cca2 (ISO 3166-1 alpha-2)

  const Country({required this.name, required this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] as String,
      code: json['cca2'] as String,
    );
  }

  String get flagUrl => 'https://flagcdn.com/w320/${code.toLowerCase()}.png';
}
```

### 5.2 `QuizOption`
```dart
class QuizOption {
  final Country country;
  final bool isCorrect;

  const QuizOption({required this.country, required this.isCorrect});
}
```

### 5.3 `GameStatus` (enum)
```dart
enum GameStatus { loading, ready, answeredCorrect, answeredWrong, gameOver }
```

---

## 6. ViewModel — `QuizViewModel`

### 6.1 State Fields
```dart
class QuizViewModel extends ChangeNotifier {
  // Dependencies
  final CountryService _countryService;

  // State
  GameStatus _status = GameStatus.loading;
  List<Country> _allCountries = [];
  Country? _currentCountry;
  List<QuizOption> _options = [];
  int _score = 0;
  int _attemptsLeft = 3;
  int _currentQuestionIndex = 0;
  int _totalQuestions = 10;          // configurable
  String? _feedbackMessage;
  bool _selectedCorrectly = false;
}
```

### 6.2 Scoring Logic
| Attempt | Points |
|---|---|
| 1st (first try) | 10 |
| 2nd | 8 |
| 3rd | 5 |
| Failed (all 3 used) | 0 |

```dart
static const List<int> _pointsTable = [10, 8, 5];

int get pointsForCurrentAttempt => _pointsTable[3 - _attemptsLeft];
```

### 6.3 Key Methods

| Method | Description |
|---|---|
| `initialize()` | Fetch countries from API, generate first question |
| `generateQuestion()` | Pick random correct country + 3 random distractors, shuffle |
| `selectOption(Country selected)` | Validate answer, update score/attempts, advance or reveal |
| `nextQuestion()` | Move to next question or end game |
| `resetGame()` | Reset all state for a new game |

### 6.4 Question Generation Algorithm
1. Pick a random country from `_allCountries` as the correct answer.
2. Pick 3 distinct random countries (different from correct) as distractors.
3. Combine into 4 options and shuffle.
4. Display flag of the correct country.

---

## 7. Views

### 7.1 `HomeView`
- App title / logo
- "Start Game" button
- Brief instructions
- High score display (optional, from `SharedPreferences`)

### 7.2 `QuizView`
- **Top bar:** Score, Question counter (e.g. "3/10"), Attempts remaining (hearts/dots)
- **Flag image:** Centered, loaded from `flagcdn.com` with loading/error states
- **Options grid:** 2×2 grid of `OptionButton` widgets
- **Feedback:** Color-coded overlay (green = correct, red = wrong)
- **Reveal:** After 3 failed attempts, highlight correct answer in green

### 7.3 `OptionButton`
- Displays country name
- States: default, selected-correct (green), selected-wrong (red), disabled
- Shows check/cross icon after selection

---

## 8. Service Layer — `CountryService`

```dart
class CountryService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';
  final http.Client _client;

  CountryService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Country>> fetchCountries() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/all?fields=name,cca2'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load countries: ${response.statusCode}');
    }
  }
}
```

---

## 9. Provider Setup

```dart
// main.dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => QuizViewModel(countryService: CountryService())..initialize(),
      child: const CountryTriviaApp(),
    ),
  );
}
```

---

## 10. UI/UX Design

### 10.1 Theme
- **Primary color:** Deep indigo / blue
- **Background:** Light gradient (white to light blue)
- **Correct answer:** Green (`Colors.green`)
- **Wrong answer:** Red (`Colors.red`)
- **Font:** Default Material 3 typography

### 10.2 Layout (Quiz Screen)
```
┌─────────────────────────────┐
│  Score: 45    Q: 3/10  ♥♥♥  │  ← Top bar
├─────────────────────────────┤
│                             │
│        ┌───────────┐        │
│        │           │        │
│        │   FLAG    │        │  ← Flag image (w320)
│        │           │        │
│        └───────────┘        │
│                             │
│   Which country is this?    │  ← Prompt text
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │ Option A │ │ Option B │  │  ← 2×2 grid
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │ Option C │ │ Option D │  │
│  └──────────┘ └──────────┘  │
│                             │
└─────────────────────────────┘
```

### 10.3 Animations
- Flag fade-in on new question
- Option button tap scale animation
- Score increment animation
- Slide transition between questions

---

## 11. Error Handling

| Scenario | Handling |
|---|---|
| API fetch failure | Show error dialog with retry button |
| Flag image load failure | Show placeholder icon (flag outline) |
| Network timeout | Timeout after 10s, show retry |
| Empty country list | Show error state |

---

## 12. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  http: ^1.2.2
  shared_preferences: ^2.3.2    # For high score persistence (optional)

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  flutter_lints: ^6.0.0
```

---

## 13. Testing Strategy

### 13.1 Unit Tests
- `Country.fromJson` parsing
- `QuizViewModel` scoring logic (10/8/5/0)
- Question generation (4 unique options, 1 correct)
- Attempt tracking and game-over flow

### 13.2 Widget Tests
- `HomeView` renders correctly
- `QuizView` shows flag + 4 options
- Tapping correct option updates score
- Tapping wrong option decrements attempts
- Game over reveals correct answer

### 13.3 Mock Strategy
- Use `mocktail` to mock `http.Client`
- Provide fixture JSON for country data
- No real network calls in tests

---

## 14. Game Flow

```
┌──────────┐     ┌──────────────┐     ┌─────────────┐
│  Splash  │────▶│   HomeView   │────▶│  QuizView   │
│  Screen  │     │  (Start Btn) │     │  (Game)     │
└──────────┘     └──────────────┘     └──────┬──────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
                    ▼                        ▼                        ▼
            ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
            │  Correct     │        │  Wrong       │        │  3 Attempts  │
            │  (10/8/5 pts)│        │  (try again) │        │  Exhausted   │
            └──────┬───────┘        └──────┬───────┘        └──────┬───────┘
                   │                       │                        │
                   ▼                       ▼                        ▼
            ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
            │  Next        │        │  Decrement   │        │  Reveal      │
            │  Question    │        │  Attempts    │        │  Answer      │
            └──────────────┘        └──────────────┘        └──────┬───────┘
                                                                   │
                                                                   ▼
                                                            ┌──────────────┐
                                                            │  Next        │
                                                            │  Question    │
                                                            └──────────────┘
```

---

## 15. Future Enhancements

| Feature | Description |
|---|---|
| Difficulty levels | Easy (3 options), Medium (4), Hard (6) |
| Timed mode | 15 seconds per question |
| Categories | Filter by region (Africa, Europe, etc.) |
| Streak bonus | Multiplier for consecutive correct answers |
| Leaderboard | Online leaderboard via Firebase |
| Sound effects | Correct/wrong answer sounds |
| Animations | Confetti on correct answer |
| Haptics | Vibration on wrong answer |
| Offline mode | Cache country data locally |
| Dark mode | Theme toggle |

---

## 16. Ticket Breakdown & Execution Plan

### Dependency Graph

```
T001 (deps)
  │
  ├──▶ T002 (Country model)     ──┐
  ├──▶ T003 (QuizOption model)  ──┤
  ├──▶ T004 (GameStatus enum)   ──┼──▶ T006 (QuizViewModel) ──┬──▶ T010 (FlagDisplay)    ──┐
  └──▶ T005 (CountryService)    ──┘                            ├──▶ T011 (OptionButton)   ──┤
                                                               ├──▶ T012 (ScoreBoard)     ──┼──▶ T014 (HomeView) ──┐
                                                               └──▶ T013 (ResultOverlay)  ──┘                    ├──▶ T016 (App+main) ──▶ T017 (Error handling)
                                                                                                                    └──▶ T015 (QuizView) ──┘
T006 (QuizViewModel) ──┬──▶ T018 (Mock client)
                        ├──▶ T019 (Model unit tests)
                        └──▶ T020 (ViewModel unit tests)

T010–T013 (Widgets) ──▶ T021 (QuizView widget tests)
T014 (HomeView)      ──▶ T022 (HomeView widget tests)

T016 (App complete)  ──▶ T023 (Animations)
                       ──▶ T024 (High score persistence)
```

---

### Phase 1 — Foundation (Sequential start, then parallel)

| Ticket | Title | Depends On | Parallel Group | Files |
|---|---|---|---|---|
| **T001** | Add dependencies to `pubspec.yaml` | — | **A** (solo) | `pubspec.yaml` |
| **T002** | Create `Country` model | T001 | **B** (parallel) | `lib/models/country.dart` |
| **T003** | Create `QuizOption` model | T001 | **B** (parallel) | `lib/models/quiz_option.dart` |
| **T004** | Create `GameStatus` enum | T001 | **B** (parallel) | `lib/models/game_status.dart` |
| **T005** | Create `CountryService` | T001, T002 | **B** (parallel) | `lib/services/country_service.dart` |

**Execution:** T001 → then T002, T003, T004, T005 in parallel.

---

### Phase 2 — ViewModel (Parallel with Phase 3 widgets)

| Ticket | Title | Depends On | Parallel Group | Files |
|---|---|---|---|---|
| **T006** | Implement `QuizViewModel` — core state, scoring, question generation, game flow | T002, T003, T004, T005 | **C** (solo) | `lib/viewmodels/quiz_viewmodel.dart` |

**Execution:** T006 can start as soon as Phase 1 is done. It defines the contract that Phase 3 widgets consume.

---

### Phase 3 — Reusable Widgets (Parallel with Phase 2)

| Ticket | Title | Depends On | Parallel Group | Files |
|---|---|---|---|---|
| **T007** | Create `FlagDisplay` widget | T006 (contract) | **D** (parallel) | `lib/widgets/flag_display.dart` |
| **T008** | Create `OptionButton` widget | T006 (contract) | **D** (parallel) | `lib/widgets/option_button.dart` |
| **T009** | Create `ScoreBoard` widget | T006 (contract) | **D** (parallel) | `lib/widgets/score_board.dart` |
| **T010** | Create `ResultOverlay` widget | T006 (contract) | **D** (parallel) | `lib/widgets/result_overlay.dart` |

**Execution:** T007–T010 can all run in parallel with each other and with T006, as long as the ViewModel's public API (getters, methods) is agreed upon first.

---

### Phase 4 — Views & App Shell (Parallel)

| Ticket | Title | Depends On | Parallel Group | Files |
|---|---|---|---|---|
| **T011** | Create `HomeView` | T006, T009 | **E** (parallel) | `lib/views/home_view.dart` |
| **T012** | Create `QuizView` | T006, T007, T008, T009, T010 | **E** (parallel) | `lib/views/quiz_view.dart` |
| **T013** | Create `app.dart` + theme | T006 | **E** (parallel) | `lib/app.dart` |
| **T014** | Wire up `main.dart` with Provider | T006, T013 | **E** (parallel) | `lib/main.dart` |

**Execution:** T011–T014 in parallel. T012 depends on all widgets being done.

---

### Phase 5 — Testing (Parallel)

| Ticket | Title | Depends On | Parallel Group | Files |
|---|---|---|---|---|
| **T015** | Create mock HTTP client + fixture JSON | T005 | **F** (parallel) | `test/mocks/mock_client.dart`, `test/fixtures/countries.json` |
| **T016** | Write `Country` model unit tests | T002, T015 | **F** (parallel) | `test/unit/country_test.dart` |
| **T017** | Write `QuizViewModel` unit tests | T006, T015 | **F** (parallel) | `test/unit/quiz_viewmodel_test.dart` |
| **T018** | Write `QuizView` widget tests | T012, T015 | **F** (parallel) | `test/widget/quiz_view_test.dart` |
| **T019** | Write `HomeView` widget tests | T011, T015 | **F** (parallel) | `test/widget/home_view_test.dart` |

**Execution:** T015 first (others depend on it), then T016–T019 in parallel.

---

### Phase 6 — Polish (Parallel)

| Ticket | Title | Depends On | Parallel Group | Files |
|---|---|---|---|---|
| **T020** | Error handling + edge cases | T014 | **G** (parallel) | Multiple files |
| **T021** | Animations + transitions | T014 | **G** (parallel) | `lib/views/quiz_view.dart`, `lib/widgets/` |
| **T022** | High score persistence (SharedPreferences) | T014 | **G** (parallel) | `lib/viewmodels/quiz_viewmodel.dart`, `lib/views/home_view.dart` |

**Execution:** T020–T022 in parallel after app is fully wired.

---

### Parallel Execution Summary

```
Time ──────────────────────────────────────────────────────────────────▶

Group A:  [T001]
              │
Group B:      [T002] [T003] [T004] [T005]        ← 4 tickets in parallel
                          │
Group C:                  [T006]                  ← ViewModel (solo)
                          │
Group D:      [T007] [T008] [T009] [T010]        ← 4 widgets in parallel
                          │
Group E:      [T011] [T012] [T013] [T014]        ← 4 views in parallel
                          │
Group F:      [T015]                              ← Mock first
                  │
              [T016] [T017] [T018] [T019]        ← 4 test suites in parallel
                          │
Group G:      [T020] [T021] [T022]              ← 3 polish tickets in parallel
```

**Key:** Tickets in the same group can be executed in parallel. Groups execute sequentially (A → B → C → D → E → F → G), except Group C and Group D can overlap since widgets only need the ViewModel contract, not the implementation.

---

### Ticket Details

#### T001 — Add dependencies
- [ ] Add `provider: ^6.1.2` to `dependencies`
- [ ] Add `http: ^1.2.2` to `dependencies`
- [ ] Add `shared_preferences: ^2.3.2` to `dependencies`
- [ ] Add `mocktail: ^1.0.4` to `dev_dependencies`
- [ ] Run `flutter pub get`
- [ ] Verify project compiles

---

#### T002 — Create `Country` model
- [ ] Create `lib/models/country.dart`
- [ ] Implement `Country` class with `name`, `code` fields
- [ ] Implement `Country.fromJson()` factory
- [ ] Add `flagUrl` getter
- [ ] Add `toString()`, `==`, `hashCode` for value equality

---

#### T003 — Create `QuizOption` model
- [ ] Create `lib/models/quiz_option.dart`
- [ ] Implement `QuizOption` class with `country`, `isCorrect` fields
- [ ] Add `const` constructor

---

#### T004 — Create `GameStatus` enum
- [ ] Create `lib/models/game_status.dart`
- [ ] Define enum: `loading`, `ready`, `answeredCorrect`, `answeredWrong`, `gameOver`

---

#### T005 — Create `CountryService`
- [ ] Create `lib/services/country_service.dart`
- [ ] Implement `CountryService` with injectable `http.Client`
- [ ] Implement `fetchCountries()` — GET request to REST API
- [ ] Add error handling for non-200 status codes
- [ ] Add 10-second timeout

---

#### T006 — Implement `QuizViewModel`
- [ ] Create `lib/viewmodels/quiz_viewmodel.dart`
- [ ] Implement all state fields (score, attempts, countries, options, etc.)
- [ ] Implement `initialize()` — fetch countries, generate first question
- [ ] Implement `generateQuestion()` — random correct + 3 distractors, shuffle
- [ ] Implement `_usedCountryCodes` Set to track answered flags
- [ ] Implement `selectOption()` — validate, update score/attempts
- [ ] Implement `nextQuestion()` — advance or end game
- [ ] Implement `resetGame()` — reset all state
- [ ] Implement scoring: `[10, 8, 5]` points table
- [ ] Add `notifyListeners()` calls on all state changes

---

#### T007 — Create `FlagDisplay` widget
- [ ] Create `lib/widgets/flag_display.dart`
- [ ] Implement `FlagDisplay` stateless widget
- [ ] Use `Image.network` with `flagUrl`
- [ ] Add loading indicator (`CircularProgressIndicator`)
- [ ] Add error fallback (flag outline icon)
- [ ] Add fade-in animation on image load

---

#### T008 — Create `OptionButton` widget
- [ ] Create `lib/widgets/option_button.dart`
- [ ] Implement `OptionButton` stateless widget
- [ ] Add states: default, correct (green), wrong (red), disabled
- [ ] Add `onTap` callback
- [ ] Add check/cross icon after selection
- [ ] Add tap scale animation

---

#### T009 — Create `ScoreBoard` widget
- [ ] Create `lib/widgets/score_board.dart`
- [ ] Implement `ScoreBoard` stateless widget
- [ ] Display score, question counter (e.g. "3/10")
- [ ] Display attempts remaining (hearts or dots)
- [ ] Add score increment animation

---

#### T010 — Create `ResultOverlay` widget
- [ ] Create `lib/widgets/result_overlay.dart`
- [ ] Implement `ResultOverlay` stateless widget
- [ ] Green overlay for correct answer
- [ ] Red overlay for wrong answer
- [ ] Auto-dismiss after delay
- [ ] "Next" button after correct answer

---

#### T011 — Create `HomeView`
- [ ] Create `lib/views/home_view.dart`
- [ ] Implement `HomeView` stateless widget
- [ ] Add app title/logo
- [ ] Add "Start Game" button → navigates to `QuizView`
- [ ] Add brief instructions
- [ ] Add high score display (if available)

---

#### T012 — Create `QuizView`
- [ ] Create `lib/views/quiz_view.dart`
- [ ] Implement `QuizView` stateless widget
- [ ] Use `Consumer<QuizViewModel>` or `context.watch`
- [ ] Layout: ScoreBoard → FlagDisplay → prompt → 2×2 OptionButton grid
- [ ] Handle answer selection
- [ ] Show `ResultOverlay` on correct/wrong
- [ ] Reveal correct answer after 3 failed attempts
- [ ] Navigate to results screen on game over

---

#### T013 — Create `app.dart` + theme
- [ ] Create `lib/app.dart`
- [ ] Implement `CountryTriviaApp` stateless widget
- [ ] Configure `MaterialApp` with theme
- [ ] Set up routing (Home → Quiz)
- [ ] Apply color scheme (indigo primary, green/red semantic)

---

#### T014 — Wire up `main.dart`
- [ ] Update `lib/main.dart`
- [ ] Add `ChangeNotifierProvider` wrapping `CountryTriviaApp`
- [ ] Inject `CountryService` into `QuizViewModel`
- [ ] Call `initialize()` on ViewModel creation
- [ ] Remove default counter app code

---

#### T015 — Create mock HTTP client + fixtures
- [ ] Create `test/mocks/mock_client.dart`
- [ ] Implement `MockClient` using `mocktail`
- [ ] Create `test/fixtures/countries.json` with 10+ sample countries
- [ ] Add helper to generate mock responses

---

#### T016 — Write `Country` model unit tests
- [ ] Create `test/unit/country_test.dart`
- [ ] Test `Country.fromJson()` with valid JSON
- [ ] Test `Country.fromJson()` with missing fields
- [ ] Test `flagUrl` getter produces correct URL
- [ ] Test equality and hashCode

---

#### T017 — Write `QuizViewModel` unit tests
- [ ] Create `test/unit/quiz_viewmodel_test.dart`
- [ ] Test initial state (loading, 0 score, 3 attempts)
- [ ] Test `initialize()` loads countries and generates question
- [ ] Test `generateQuestion()` produces 4 unique options
- [ ] Test `generateQuestion()` marks country as used
- [ ] Test `selectOption()` with correct answer → +10 points
- [ ] Test `selectOption()` with wrong answer → attempts decrement
- [ ] Test second correct answer → +8 points
- [ ] Test third correct answer → +5 points
- [ ] Test all 3 attempts exhausted → 0 points, reveal answer
- [ ] Test `nextQuestion()` advances question index
- [ ] Test `resetGame()` resets all state
- [ ] Test no duplicate countries across questions

---

#### T018 — Write `QuizView` widget tests
- [ ] Create `test/widget/quiz_view_test.dart`
- [ ] Pump `QuizView` with mock ViewModel
- [ ] Verify flag image is displayed
- [ ] Verify 4 option buttons are rendered
- [ ] Tap correct option → verify score updates
- [ ] Tap wrong option → verify attempts decrement
- [ ] Verify correct answer revealed after 3 wrong attempts
- [ ] Verify game over state after all questions

---

#### T019 — Write `HomeView` widget tests
- [ ] Create `test/widget/home_view_test.dart`
- [ ] Pump `HomeView`
- [ ] Verify title and start button render
- [ ] Tap start button → verify navigation to QuizView

---

#### T020 — Error handling + edge cases
- [ ] Handle API fetch failure in ViewModel (show error state)
- [ ] Add retry mechanism on error
- [ ] Handle flag image load failure in `FlagDisplay`
- [ ] Handle empty country list
- [ ] Handle network timeout
- [ ] Add loading states throughout

---

#### T021 — Animations + transitions
- [ ] Add flag fade-in on new question
- [ ] Add option button tap scale animation
- [ ] Add score increment animation
- [ ] Add slide transition between questions
- [ ] Add confetti or celebration on correct answer (optional)

---

#### T022 — High score persistence
- [ ] Add `shared_preferences` to ViewModel
- [ ] Save high score on game over
- [ ] Load high score on app start
- [ ] Display high score on `HomeView`
- [ ] Add "New High Score!" celebration

---

## 17. File-by-File Implementation Checklist

- [ ] `pubspec.yaml` — add `provider`, `http`, `shared_preferences`, `mocktail`
- [ ] `lib/models/country.dart` — Country model with JSON parsing
- [ ] `lib/models/quiz_option.dart` — QuizOption model
- [ ] `lib/models/game_status.dart` — GameStatus enum
- [ ] `lib/services/country_service.dart` — HTTP service with error handling
- [ ] `lib/viewmodels/quiz_viewmodel.dart` — Full game logic
- [ ] `lib/widgets/flag_display.dart` — Flag image with loading/error states
- [ ] `lib/widgets/option_button.dart` — Answer option button
- [ ] `lib/widgets/score_board.dart` — Score and progress display
- [ ] `lib/widgets/result_overlay.dart` — Feedback overlay
- [ ] `lib/views/home_view.dart` — Start screen
- [ ] `lib/views/quiz_view.dart` — Main quiz screen
- [ ] `lib/app.dart` — MaterialApp with theme
- [ ] `lib/main.dart` — Provider setup and app entry
- [ ] `test/unit/quiz_viewmodel_test.dart` — ViewModel unit tests
- [ ] `test/unit/country_test.dart` — Model unit tests
- [ ] `test/widget/quiz_view_test.dart` — QuizView widget tests
- [ ] `test/widget/home_view_test.dart` — HomeView widget tests
- [ ] `test/mocks/mock_client.dart` — Mock HTTP client
