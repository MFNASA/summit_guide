// flashlight_sos_service.dart
//
// Membuat lampu flash HP berkedip mengikuti pola kode Morse "SOS"
// ( ... --- ... ) secara berulang sampai dihentikan.

import 'dart:async';
import 'package:torch_light/torch_light.dart';

class _Signal {
  final bool torchOn;
  final int durationMs;
  const _Signal(this.torchOn, this.durationMs);
}

class FlashlightSosService {
  static const int _dot = 200; // durasi titik
  static const int _dash = 600; // durasi garis
  static const int _gap = 200; // jeda antar simbol dalam 1 huruf
  static const int _letterGap = 600; // jeda antar huruf
  static const int _wordGap = 1400; // jeda antar pengulangan SOS

  bool _running = false;
  bool get isFlashing => _running;

  List<_Signal> _buildSosPattern() {
    final pattern = <_Signal>[];

    void addLetter(List<bool> symbols) {
      for (var i = 0; i < symbols.length; i++) {
        pattern.add(_Signal(true, symbols[i] ? _dash : _dot));
        if (i != symbols.length - 1) {
          pattern.add(_Signal(false, _gap));
        }
      }
      pattern.add(_Signal(false, _letterGap));
    }

    addLetter([false, false, false]); // S = ...
    addLetter([true, true, true]); // O = ---
    addLetter([false, false, false]); // S = ...

    pattern.add(_Signal(false, _wordGap));
    return pattern;
  }

  Future<void> startSOSFlash() async {
    if (_running) return;

    try {
      final available = await TorchLight.isTorchAvailable();
      if (!available) return;
    } catch (_) {
      return; // device tidak punya flash / tidak didukung
    }

    _running = true;
    final pattern = _buildSosPattern();

    unawaited(_loop(pattern));
  }

  Future<void> _loop(List<_Signal> pattern) async {
    while (_running) {
      for (final signal in pattern) {
        if (!_running) break;
        try {
          if (signal.torchOn) {
            await TorchLight.enableTorch();
          } else {
            await TorchLight.disableTorch();
          }
        } catch (_) {
          // abaikan error sesaat (mis. kamera sedang dipakai proses lain)
        }
        await Future.delayed(Duration(milliseconds: signal.durationMs));
      }
    }
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  Future<void> stop() async {
    _running = false;
    // beri sedikit waktu agar loop sempat keluar sebelum torch dimatikan final
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }
}
