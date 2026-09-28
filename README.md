# Country Trivia

A Flutter trivia game where players identify countries from their flags.

## How to Play

1. A country flag is displayed
2. Pick the correct country name from 4 options
3. You have 3 attempts per question
4. Scoring: 1st attempt = 10 pts, 2nd = 8 pts, 3rd = 5 pts

## Tech Stack

- **Framework:** Flutter
- **State Management:** Provider (MVVM)
- **API:** REST Countries API
- **Flags:** flagcdn.com

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── models/          # Data models (Country, QuizOption, GameStatus)
├── services/        # API services (CountryService)
├── viewmodels/      # QuizViewModel (game logic)
├── views/           # UI screens (HomeView, QuizView)
└── widgets/         # Reusable UI components
```

See [docs/master_plan.md](docs/master_plan.md) for the full architecture and implementation plan.
