import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;

import 'models/quran_models.dart';

class QuranAudioService extends ChangeNotifier {
  QuranAudioService() : _player = AudioPlayer() {
    _player.playerStateStream.listen((state) {
      notifyListeners();
    });
    _player.currentIndexStream.listen((index) {
      if (_currentTarget != null && _currentTarget!.isSurah && index != null) {
        _currentTarget = QuranAudioTarget(
          surahNumber: _currentTarget!.surahNumber,
          ayahNumber: index + 1,
          isSurah: true,
        );
        notifyListeners();
      }
    });
  }

  final AudioPlayer _player;
  QuranAudioTarget? _currentTarget;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  QuranAudioTarget? get currentTarget => _currentTarget;
  bool get isPlaying => _player.playing;

  static const reciters = [
    ReciterInfo(id: 'arAlafasy', label: 'Mishary Al-Afasy'),
    ReciterInfo(id: 'arHusary', label: 'Mahmoud Khalil Al-Husary'),
    ReciterInfo(id: 'arAhmedAjamy', label: 'Ahmed Al-Ajamy'),
    ReciterInfo(id: 'arHudhaify', label: 'Ali Al-Hudhaify'),
    ReciterInfo(id: 'arMaherMuaiqly', label: 'Maher Al Muaiqly'),
    ReciterInfo(id: 'arMuhammadAyyoub', label: 'Muhammad Ayyoub'),
    ReciterInfo(id: 'arMuhammadJibreel', label: 'Muhammad Jibreel'),
    ReciterInfo(id: 'arMinshawi', label: 'Mohamed Siddiq Al-Minshawi'),
    ReciterInfo(id: 'arShaatree', label: 'Abu Bakr Ash-Shaatree'),
  ];

  static q.Reciter reciterFromId(String id) {
    return q.Reciter.values.firstWhere(
      (r) => r.name == id,
      orElse: () => q.Reciter.arAlafasy,
    );
  }

  Future<void> playSurah(int surahNumber, String reciterId) async {
    final reciter = reciterFromId(reciterId);
    final count = q.getVerseCount(surahNumber);
    final sources = <AudioSource>[];
    for (int i = 1; i <= count; i++) {
      sources.add(AudioSource.uri(Uri.parse(q.getAudioURLByVerse(surahNumber, i, reciter: reciter))));
    }
    
    _currentTarget = QuranAudioTarget(
      surahNumber: surahNumber,
      ayahNumber: 1, // Start at 1st ayah
      isSurah: true,
    );
    notifyListeners();
    
    await _player.setAudioSources(sources);
    await _player.play();
  }

  Future<void> playAyah(int surahNumber, int ayahNumber, String reciterId) async {
    final reciter = reciterFromId(reciterId);
    final url = q.getAudioURLByVerse(
      surahNumber,
      ayahNumber,
      reciter: reciter,
    );
    _currentTarget = QuranAudioTarget(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      isSurah: false,
    );
    notifyListeners();
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekForward() async {
    final newPos = _player.position + const Duration(seconds: 15);
    await _player.seek(newPos);
  }

  Future<void> seekBackward() async {
    var newPos = _player.position - const Duration(seconds: 15);
    if (newPos < Duration.zero) newPos = Duration.zero;
    await _player.seek(newPos);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> stop() async {
    _currentTarget = null;
    notifyListeners();
    await _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
