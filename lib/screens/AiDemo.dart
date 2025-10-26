// lib/pages/ai_demo.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../providers/god_provider.dart';
import '../models/god.dart';

class AiDemo extends ConsumerStatefulWidget {
  const AiDemo({super.key});

  @override
  ConsumerState<AiDemo> createState() => _AiDemoState();
}

class _AiDemoState extends ConsumerState<AiDemo> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isCountingPaused = false;
  String _recognizedText = '';
  God? _selectedGod;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Timer to detect 1-minute silence
  Timer? _silenceTimer;

  // Floating chanting words
  final List<_ChantWord> _chantWords = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeSpeech();
    _checkMicPermission();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onError: (e) => debugPrint('[SPEECH ERROR] $e'),
      onStatus: (s) => debugPrint('[SPEECH STATUS] $s'),
    );
  }

  Future<void> _checkMicPermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) await Permission.microphone.request();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _silenceTimer?.cancel();
    super.dispose();
  }

  // ----------- START / STOP Listening ------------
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final initialized = await _speech.initialize(
      onError: (e) => debugPrint('[SPEECH ERROR] $e'),
      onStatus: (s) => debugPrint('[SPEECH STATUS] $s'),
    );
    if (!initialized) return;

    await _speech.listen(
      localeId: 'hi-IN',
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(seconds: 60), // long silence allowed
      listenFor: const Duration(minutes: 30),
      onResult: _onSpeechResult,
    );

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    _restartSilenceTimer();
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    await _speech.stop();
    setState(() {
      _isListening = false;
      _recognizedText = '';
    });
  }

  void _restartSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(minutes: 1), () async {
      debugPrint('[DEBUG] No sound for 1 min → auto stop mic');
      await _stopListening();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Mic stopped due to silence (1 min).')));
      }
    });
  }

  // ----------- SPEECH RESULT ------------
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    setState(() => _recognizedText = result.recognizedWords);
    _restartSilenceTimer(); // reset silence timer on sound

    if (result.finalResult) {
      Future.delayed(const Duration(seconds: 2), () {
        _handleFinalResult(result.recognizedWords);
      });
    }
  }

  // ----------- TRANSLITERATION, MATCHING & COUNTING ------------
  String devToEng(String input) {
    if (input.isEmpty) return '';
    if (RegExp(r'^[\x00-\x7F]+$').hasMatch(input)) {
      return input.toLowerCase().trim();
    }

    const map = {
      'अ': 'a', 'आ': 'aa', 'ा': 'a', 'इ': 'i', 'ई': 'ii', 'ि': 'i', 'ी': 'ii',
      'उ': 'u', 'ऊ': 'uu', 'ु': 'u', 'ू': 'uu',
      'ए': 'e', 'ऐ': 'ai', 'ो': 'o', 'औ': 'au', 'ओ': 'o',
      'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
      'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
      'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
      'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
      'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
      'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v',
      'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
      'ं': 'n', 'ः': 'h', 'ँ': 'n', '़': '',
      '।': ' ', '॥': ' ',
    };

    final buffer = StringBuffer();
    for (var ch in input.characters) {
      buffer.write(map[ch] ?? ch);
    }

    String out = buffer.toString().toLowerCase();
    out = out.replaceAll(RegExp(r'aa+'), 'a').replaceAll(RegExp(r'ii+'), 'i');
    out = out.replaceAll(RegExp(r'uu+'), 'u').replaceAll(RegExp(r'\s+'), ' ');
    out = out.replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    return out;
  }

  String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  int levenshtein(String a, String b) {
    final la = a.length, lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    final d = List.generate(la + 1, (_) => List.filled(lb + 1, 0));
    for (int i = 0; i <= la; i++) d[i][0] = i;
    for (int j = 0; j <= lb; j++) d[0][j] = j;
    for (int i = 1; i <= la; i++) {
      for (int j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].reduce((v, e) => v < e ? v : e);
      }
    }
    return d[la][lb];
  }

  bool fuzzyMatch(String a, String b) {
    final dist = levenshtein(normalize(a), normalize(b));
    final avg = dist / b.length;
    return avg <= 0.45;
  }

  void _handleFinalResult(String finalText) {
    if (_selectedGod == null || _isCountingPaused) return;

    final spoken = devToEng(finalText);
    final target = devToEng(_selectedGod!.name);
    if (spoken.contains(target) || fuzzyMatch(spoken, target)) {
      final notifier = ref.read(godListProvider.notifier);
      notifier.incrementCount(_selectedGod!.id);
      _addChantWord(_selectedGod!.name);
    }
  }

  // ----------- ANIMATED CHANTING WORDS ------------
  void _addChantWord(String word) {
    final chant = _ChantWord(word: word);
    setState(() => _chantWords.add(chant));

    // auto remove after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _chantWords.remove(chant));
      }
    });
  }

  // ----------- UI ------------
  void _toggleCountingPause() {
    setState(() => _isCountingPaused = !_isCountingPaused);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isCountingPaused ? 'Counting paused' : 'Counting resumed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gods = ref.watch(godListProvider);
    final God? selected = (gods.isEmpty)
        ? null
        : gods.firstWhere((g) => g.id == _selectedGod?.id, orElse: () => gods.first);

    if (_selectedGod == null || (selected != null && selected.id != _selectedGod!.id)) {
      _selectedGod = selected;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFC107), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Chanting words floating
              ..._chantWords.map((c) => c.build(context)),

              Column(
                children: [
                  const SizedBox(height: 18),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.temple_hindu, color: Colors.white, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Naam Jaap — Voice Counter',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _toggleCountingPause,
                          icon: Icon(_isCountingPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white),
                          label: Text(_isCountingPaused ? 'RESUME' : 'PAUSE',
                              style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Dropdown + total
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<God>(
                              value: selected,
                              underline: const SizedBox(),
                              dropdownColor: Colors.orange[900],
                              isExpanded: true,
                              items: gods
                                  .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g.name,
                                          style: const TextStyle(color: Colors.white))))
                                  .toList(),
                              onChanged: (g) => setState(() => _selectedGod = g),
                            ),
                          ),
                          if (selected != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Total',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                  Text('${selected.totalCount}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Mic Button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) => Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _isListening
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black38,
                                  blurRadius: 25,
                                  spreadRadius: 5)
                            ],
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [Colors.white, Colors.orangeAccent]
                                  : [Colors.white70, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.black87,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start/Stop Text Label
                  Text(
                    _isListening ? 'Stop Listening' : 'Start Listening',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Helper Class for Floating Chant Animation ----
class _ChantWord {
  final String word;
  final UniqueKey _key = UniqueKey();

  _ChantWord({required this.word});

  Widget build(BuildContext context) {
    final randomX = (50 + (150 * (DateTime.now().microsecond % 10)) / 10).toDouble();
    return Positioned(
      bottom: 60,
      left: randomX,
      child: AnimatedOpacity(
        key: _key,
        opacity: 0,
        duration: const Duration(seconds: 3),
        curve: Curves.easeOut,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: -200),
          duration: const Duration(seconds: 3),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: 1 - (value.abs() / 200),
                child: Text(
                  word,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(1, 1))
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
