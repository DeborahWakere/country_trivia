import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/country.dart';

/// Service responsible for fetching country data from the REST API.
class CountryService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

  final http.Client _client;

  CountryService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches all countries with their names and ISO codes.
  ///
  /// Throws an [Exception] if the request fails or times out.
  Future<List<Country>> fetchCountries() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/all?fields=name,cca2'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((json) => Country.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load countries: HTTP ${response.statusCode}',
      );
    }
  }
}
