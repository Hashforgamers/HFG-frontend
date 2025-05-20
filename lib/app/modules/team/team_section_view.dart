// Optimized TeamSection code with unchanged UI
import 'dart:math';
import 'package:flutter/material.dart';

class TeamSection extends StatelessWidget {
  TeamSection({super.key});

  final List<Map<String, String>> profiles = const [
    {'title': 'Backend Developer', 'description': 'Flask (Python)', 'buttonText': 'Apply'},
    {'title': 'Frontend Developer', 'description': 'Flutter (Dart)', 'buttonText': 'Apply'},
    {'title': 'AWS Specialist', 'description': 'Cloud Infrastructure', 'buttonText': 'Apply'},
    {'title': 'Database Expert', 'description': 'PostgreSQL & Optimization', 'buttonText': 'Apply'},
    {'title': 'UI/UX Designer', 'description': 'Figma & Prototyping', 'buttonText': 'Apply'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CAREER OPPORTUNITIES',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final color = _getRandomColor();
              return GestureDetector(
                onTap: () => _openForm(context, profile['title']!, color),
                child: _buildProfileCard(profile['title']!, profile['description']!, profile['buttonText']!, color),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(String title, String description, String buttonText, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 130,
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(buttonText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, String title, Color backgroundColor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamFormScreen(title: title, backgroundColor: backgroundColor)),
    );
  }

  Color _getRandomColor() {
    final random = Random();
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[random.nextInt(colors.length)].shade800;
  }
}

class TeamFormScreen extends StatelessWidget {
  final String title;
  final Color backgroundColor;

  const TeamFormScreen({super.key, required this.title, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.black),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply for $title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _buildTextField('Your Name'),
            const SizedBox(height: 20),
            _buildTextField('Your Email'),
            const SizedBox(height: 20),
            _buildTextField('Why are you a good fit?', maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: backgroundColor,
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}