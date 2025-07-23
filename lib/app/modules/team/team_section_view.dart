import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamSection extends StatelessWidget {
  final List<Map<String, String>> profiles = [
    {
      'title': 'Backend Developer',
      'description': 'Flask (Python)',
      'buttonText': 'Apply'
    },
    {
      'title': 'Frontend Developer',
      'description': 'Flutter (Dart)',
      'buttonText': 'Apply'
    },
    {
      'title': 'AWS Specialist',
      'description': 'Cloud Infrastructure',
      'buttonText': 'Apply'
    },
    {
      'title': 'Database Expert',
      'description': 'PostgreSQL & Optimization',
      'buttonText': 'Apply'
    },
    {
      'title': 'UI/UX Designer',
      'description': 'Figma & Prototyping',
      'buttonText': 'Apply'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAREER OPPORTUNITIES',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110, // Fixed height for scrolling
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final cardColor = _getRandomColor();
              return GestureDetector(
                onTap: () => _openForm(context, profile['title']!, cardColor),
                child: _buildProfileCard(profile['title']!,
                    profile['description']!, profile['buttonText']!, cardColor),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
      String title, String description, String buttonText, Color color) {
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {}, // Add functionality if needed
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: GoogleFonts.inter(
                      color: color, fontWeight: FontWeight.bold),
                ),
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
      MaterialPageRoute(
        builder: (context) =>
            TeamFormScreen(title: title, backgroundColor: backgroundColor),
      ),
    );
  }

  Color _getRandomColor() {
    final random = Random();
    final colors = [
      Colors.red[800],
      Colors.blue[800],
      Colors.green[800],
      Colors.purple[800],
      Colors.orange[800],
      Colors.cyan[800],
      Colors.amber[800],
    ];
    return colors[random.nextInt(colors.length)]!;
  }
}

class TeamFormScreen extends StatelessWidget {
  final String title;
  final Color backgroundColor;

  TeamFormScreen({required this.title, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply for $title',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Why are you a good fit?',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Submit logic
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: backgroundColor,
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.inter(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
