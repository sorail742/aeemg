class Hadith {
  final int id;
  final String category;
  final String text;
  final String source;

  const Hadith({
    required this.id,
    required this.category,
    required this.text,
    required this.source,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as int,
      category: json['category'] as String,
      text: json['text'] as String,
      source: json['source'] as String,
    );
  }
}
