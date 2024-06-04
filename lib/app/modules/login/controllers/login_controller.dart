import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../utils/widgets/quote_service.dart';
class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final quote = ''.obs;
  final character = ''.obs;

  final QuoteService _quoteService = QuoteService();

  @override
  void onInit() {
    super.onInit();
    fetchQuote();
  }

  void fetchQuote() async {
    try {
      final fetchedQuote = await _quoteService.fetchQuote();
      quote.value = fetchedQuote.quote;
      character.value = fetchedQuote.character;
    } catch (e) {
      quote.value = 'Failed to load quote';
      character.value = '';
    }
  }

  void login() {
    final email = emailController.text;
    final password = passwordController.text;
    // Implement your login logic here
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
