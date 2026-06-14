import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:quran/quran.dart' as quran;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';

class RecitationTestScreen extends StatefulWidget {
  final int surahNumber;

  const RecitationTestScreen({
    super.key,
    required this.surahNumber,
  });

  @override
  State<RecitationTestScreen> createState() => _RecitationTestScreenState();
}

class _RecitationTestScreenState extends State<RecitationTestScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  late String _fullSurahText;
  late String _surahName;
  late int _verseCount;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _surahName = quran.getSurahName(widget.surahNumber);
    _verseCount = quran.getVerseCount(widget.surahNumber);
    _fullSurahText = _buildFullSurahText();
  }

  String _buildFullSurahText() {
    final buffer = StringBuffer();
    for (int i = 1; i <= _verseCount; i++) {
      buffer.write(quran.getVerse(widget.surahNumber, i));
      buffer.write(' ');
      buffer.write(quran.getVerseEndSymbol(i));
      buffer.write(' ');
    }
    return _removeTashkeel(buffer.toString().trim());
  }

  String _removeTashkeel(String text) {
    return text.replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u0652]'), '');
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (_) {},
        onError: (_) {},
      );
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _recognizedText = val.recognizedWords;
          }),
          listenOptions: stt.SpeechListenOptions(localeId: 'ar_SA'),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reconnaissance vocale indisponible sur cet appareil.')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Returns a score percentage: ratio of correctly recognized words
  double _calculateScore() {
    if (_recognizedText.isEmpty) return 0;
    final originalWords =
        _fullSurahText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final recognizedWords =
        _recognizedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (recognizedWords.isEmpty) return 0;
    int correct = 0;
    for (int i = 0; i < recognizedWords.length && i < originalWords.length; i++) {
      if (recognizedWords[i] == originalWords[i]) correct++;
    }
    return (correct / originalWords.length) * 100;
  }

  List<TextSpan> _buildComparisonSpans() {
    if (_recognizedText.isEmpty) {
      return [
        TextSpan(
          text: 'Appuyez sur le micro et commencez à réciter.',
          style: TextStyle(color: AppColors.warmGray, fontSize: 16),
        ),
      ];
    }

    final originalWords =
        _fullSurahText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final recognizedWords =
        _recognizedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final spans = <TextSpan>[];

    for (int i = 0; i < recognizedWords.length; i++) {
      final rWord = recognizedWords[i];
      final isCorrect = i < originalWords.length && rWord == originalWords[i];
      spans.add(TextSpan(
        text: '$rWord ',
        style: TextStyle(
          color: isCorrect ? AppColors.emerald : AppColors.error,
          fontWeight: isCorrect ? FontWeight.normal : FontWeight.bold,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vérificateur de Récitation'),
            Text(
              'Sourate $_surahName ($_verseCount versets)',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Full Surah text
            AeemgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book, color: AppColors.brightGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Texte de la Sourate',
                        style: AppTypography.h3,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Build verse-by-verse with tashkeel (original text)
                  ...List.generate(_verseCount, (i) {
                    final ayahNum = i + 1;
                    final verseText = quran.getVerse(widget.surahNumber, ayahNum);
                    final endSymbol = quran.getVerseEndSymbol(ayahNum);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '$verseText $endSymbol',
                        style: AppTypography.quranArabic(size: 22).copyWith(height: 2.0),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Score display when text is recognized
            if (_recognizedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: score >= 70
                      ? AppColors.emerald.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: score >= 70 ? AppColors.emerald : AppColors.error,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      score >= 70 ? Icons.check_circle : Icons.cancel,
                      color: score >= 70 ? AppColors.emerald : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Score : ${score.toStringAsFixed(0)}%',
                      style: AppTypography.h3.copyWith(
                        color: score >= 70 ? AppColors.emerald : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Votre Récitation', style: AppTypography.h2),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warmGray.withValues(alpha: 0.2)),
              ),
              child: RichText(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: AppTypography.quranArabic(size: 22).copyWith(
                    color: AppColors.white,
                    height: 2.0,
                  ),
                  children: _buildComparisonSpans(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 12, color: AppColors.emerald),
                const SizedBox(width: 4),
                Text('Correct', style: AppTypography.caption),
                const SizedBox(width: 16),
                const Icon(Icons.circle, size: 12, color: AppColors.error),
                const SizedBox(width: 4),
                Text('Erreur', style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? AppColors.error : AppColors.brightGreen,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? AppColors.error : AppColors.brightGreen)
                          .withValues(alpha: 0.4),
                      blurRadius: _isListening ? 20 : 8,
                      spreadRadius: _isListening ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: AppColors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isListening ? 'Écoute en cours...' : 'Appuyez pour réciter',
              style: AppTypography.bodySmall,
            ),
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                onPressed: () => setState(() => _recognizedText = ''),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réinitialiser'),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
