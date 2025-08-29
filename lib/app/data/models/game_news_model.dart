class NewsArticle {
  final String title;
  final String deck;
  final String imageUrl;
  final String siteUrl;

  NewsArticle({
    required this.title,
    required this.deck,
    required this.imageUrl,
    required this.siteUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final imageMap = json['image'] as Map<String, dynamic>?;

    return NewsArticle(
      title: json['title'] ?? 'No Title',
      deck: json['deck'] ?? '',
      imageUrl: imageMap?['original'] ?? imageMap?['square_small'] ?? '', // Keep whatever is available
      siteUrl: json['site_detail_url'] ?? '',
    );
  }
}
