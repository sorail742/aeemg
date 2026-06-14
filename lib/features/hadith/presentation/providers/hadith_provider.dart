import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/hadith_service.dart';
import '../../data/models/hadith_model.dart';

final hadithServiceProvider = Provider<HadithService>((ref) {
  return HadithService();
});

final hadithsInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.read(hadithServiceProvider);
  await service.loadHadiths();
});

final allHadithsProvider = Provider<List<Hadith>>((ref) {
  final service = ref.watch(hadithServiceProvider);
  // Returns empty until initialization completes
  return service.getAllHadiths();
});

final hadithCategoriesProvider = Provider<List<String>>((ref) {
  final service = ref.watch(hadithServiceProvider);
  return service.getCategories();
});
