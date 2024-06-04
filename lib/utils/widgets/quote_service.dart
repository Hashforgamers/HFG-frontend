import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuoteService {
  final String apiUrl = "https://ultima.rest/api/random";

  Future<Quote> fetchQuote() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
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
