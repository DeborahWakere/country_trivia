import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/country_service.dart';
import 'viewmodels/quiz_viewmodel.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => QuizViewModel(
        countryService: CountryService(),
      )..initialize(),
      child: const CountryTriviaApp(),
    ),
  );
}
