import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  final Color brandGreen = const Color(0xff00DC00); // ✅ HashforGamers green

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.bold,color: brandGreen),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Info Cards
            _buildInfoCard(
              title: 'Company',
              content: 'Hash for Gamers Private Limited',
              icon: Icons.business_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Support Email',
              content: 'support@hashforgamers.co.in',
              icon: Icons.email_rounded,
              isClickable: true,
              isDark: isDark,
              onTap: () => _launchEmail('support@hashforgamers.co.in'),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Website',
              content: 'www.hashforgamers.com',
              icon: Icons.language_rounded,
              isClickable: true,
              isDark: isDark,
              onTap: () => _launchUrl('https://www.hashforgamers.com'),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Registered Office',
              content: 'Hash for Gamers Pvt. Ltd.\nMumbai, Maharashtra, India',
              icon: Icons.location_on_rounded,
              isMultiLine: true,
              isDark: isDark,
            ),

            const SizedBox(height: 30),

            // About Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: brandGreen.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.sports_esports_rounded,
                      size: 40, color: brandGreen),
                  const SizedBox(height: 12),
                  Text(
                    'About Hash for Gamers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We are building India’s first gaming café booking & rewards platform. '
                        'Our mission is to connect gamers, simplify café bookings, and unlock '
                        'a new era of gaming experiences powered by HashCoins & passes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
    bool isClickable = false,
    bool isMultiLine = false,
    VoidCallback? onTap,
  }) {
    final Color brandGreen = const Color(0xff00DC00);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isClickable ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brandGreen.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brandGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: brandGreen, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      )),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isClickable
                          ? brandGreen
                          : (isDark ? Colors.white : Colors.black87),
                      decoration:
                      isClickable ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: isDark ? Colors.grey[400]! : Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
