// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void writeWav(String path, List<double> samples, {int sampleRate = 44100}) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  final numSamples = samples.length;
  final bytesPerSample = 2; // 16-bit PCM
  final dataSize = numSamples * bytesPerSample;

  final bytes = BytesBuilder();
  // RIFF header
  bytes.add('RIFF'.codeUnits);
  bytes.add(_int32(36 + dataSize));
  bytes.add('WAVE'.codeUnits);
  // fmt subchunk
  bytes.add('fmt '.codeUnits);
  bytes.add(_int32(16)); // Subchunk1Size
  bytes.add(_int16(1));  // PCM format
  bytes.add(_int16(1));  // Mono channel
  bytes.add(_int32(sampleRate));
  bytes.add(_int32(sampleRate * bytesPerSample)); // ByteRate
  bytes.add(_int16(bytesPerSample)); // BlockAlign
  bytes.add(_int16(16)); // BitsPerSample
  // data subchunk
  bytes.add('data'.codeUnits);
  bytes.add(_int32(dataSize));

  // Write PCM samples
  for (var i = 0; i < numSamples; i++) {
    var val = (samples[i].clamp(-1.0, 1.0) * 32767.0).round();
    if (val < 0) val += 65536;
    bytes.addByte(val & 0xFF);
    bytes.addByte((val >> 8) & 0xFF);
  }

  file.writeAsBytesSync(bytes.toBytes());
  print('Generated $path (${(numSamples / sampleRate).toStringAsFixed(2)}s)');
}

Uint8List _int32(int v) {
  final b = ByteData(4)..setUint32(0, v, Endian.little);
  return b.buffer.asUint8List();
}

Uint8List _int16(int v) {
  final b = ByteData(2)..setUint16(0, v, Endian.little);
  return b.buffer.asUint8List();
}

List<double> generateTone(double freq, double duration, {String envelope = 'decay', double volume = 0.5}) {
  final sampleRate = 44100;
  final n = (sampleRate * duration).round();
  final list = List<double>.filled(n, 0.0);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    var env = 1.0;
    if (envelope == 'decay') {
      env = exp(-t * 8.0);
    } else if (envelope == 'pluck') {
      env = exp(-t * 20.0);
    } else if (envelope == 'smooth') {
      env = sin(pi * t / duration);
    } else if (envelope == 'fade_out') {
      env = (1.0 - t / duration);
    }
    final wave = sin(2 * pi * freq * t) + 0.25 * sin(4 * pi * freq * t);
    list[i] = wave * env * volume;
  }
  return list;
}

List<double> generateChimeSequence(List<double> freqs, double noteDuration) {
  final out = <double>[];
  for (final f in freqs) {
    out.addAll(generateTone(f, noteDuration, envelope: 'pluck', volume: 0.6));
  }
  return out;
}

List<double> generateAmbientLoop(double duration) {
  final sampleRate = 44100;
  final n = (sampleRate * duration).round();
  final list = List<double>.filled(n, 0.0);
  final chords = [
    [261.63, 329.63, 392.00, 523.25], // C major 7
    [220.00, 261.63, 329.63, 440.00], // A minor 7
    [174.61, 220.00, 261.63, 349.23], // F major 7
    [196.00, 246.94, 293.66, 392.00], // G major 7
  ];

  final chordLen = duration / chords.length;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final chordIdx = (t / chordLen).floor().clamp(0, chords.length - 1);
    final chordT = t - chordIdx * chordLen;
    final env = sin(pi * chordT / chordLen);

    var sample = 0.0;
    for (final f in chords[chordIdx]) {
      sample += sin(2 * pi * f * t) * 0.12;
    }
    list[i] = sample * env * 0.4;
  }
  return list;
}

void main() {
  final baseDir = 'assets/audio';
  Directory(baseDir).createSync(recursive: true);

  writeWav('$baseDir/pickup.wav', generateTone(440, 0.1, envelope: 'pluck', volume: 0.4));
  writeWav('$baseDir/place.wav', generateTone(220, 0.12, envelope: 'pluck', volume: 0.6));
  
  final invalidSamples = <double>[
    ...generateTone(130, 0.08, envelope: 'decay', volume: 0.4),
    ...generateTone(110, 0.08, envelope: 'decay', volume: 0.4),
  ];
  writeWav('$baseDir/invalid.wav', invalidSamples);
  writeWav('$baseDir/clear.wav', generateChimeSequence([523.25, 659.25, 783.99, 1046.50], 0.08));
  writeWav('$baseDir/combo.wav', generateChimeSequence([440.0, 554.37, 659.25, 880.0, 1108.73], 0.07));
  writeWav('$baseDir/game_over.wav', generateChimeSequence([440.0, 415.30, 349.23, 293.66], 0.15));
  writeWav('$baseDir/click.wav', generateTone(800, 0.04, envelope: 'pluck', volume: 0.3));
  writeWav('$baseDir/bgm.wav', generateAmbientLoop(12.0));

  print('All sound effects & ambient music generated successfully!');
}
