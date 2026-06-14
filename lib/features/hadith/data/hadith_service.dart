import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/hadith_model.dart';

class HadithService {
  List<Hadith> _allHadiths = [];

  Future<void> loadHadiths() async {
    if (_allHadiths.isNotEmpty) return;
    
    final jsonString = await rootBundle.loadString('assets/data/hadiths.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    _allHadiths = jsonList.map((e) => Hadith.fromJson(e)).toList();
  }

  List<Hadith> getAllHadiths() => _allHadiths;

  List<String> getCategories() {
    final categories = _allHadiths.map((h) => h.category).toSet().toList();
    return categories;
  }

  List<Hadith> searchHadiths(String query) {
    if (query.trim().isEmpty) return _allHadiths;
    final term = query.toLowerCase().trim();
    
    return _allHadiths.where((h) {
      return h.text.toLowerCase().contains(term) ||
             h.category.toLowerCase().contains(term) ||
             h.source.toLowerCase().contains(term) ||
             h.id.toString() == term;
    }).toList();
  }
}
