import 'dart:convert';
import 'package:dio/dio.dart';

class QuoteService {
  final String apiUrl = "https://ultima.rest/api/random";
  final Dio _dio = Dio();

  Future<Quote> fetchQuote() async {
    final response = await _dio.get(apiUrl);

    if (response.statusCode == 200) {
      final data = response.data is String
          ? json.decode(response.data as String)
          : response.data;
      return Quote.fromJson(data);
    } else {
      throw Exception('Failed to load quote');
    }
  }
}

class Quote {
  final String quote;
  final String character;

  Quote({required this.quote, required this.character});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      quote: json['quote'],
      character: json['character'],
    );
  }
}
