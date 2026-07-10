// alarm_sound_service.dart
//
// Membunyikan suara alarm/sirine keras berulang lewat speaker HP
// selama SOS aktif. Butuh file audio di assets/sounds/sos_alarm.mp3
// (lihat SETUP_INSTRUCTIONS.md).

import 'package:audioplayers/audioplayers.dart';

class AlarmSoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Future<void> startAlarm({
    String assetPath = 'sounds/sos_alarm.mp3',
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      _isPlaying = false;
      rethrow;
    }
  }

  Future<void> stopAlarm() async {
    _isPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
