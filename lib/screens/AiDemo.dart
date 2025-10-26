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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeSpeech();
    _checkMicPermission();
    debugPrint('[DEBUG] AiDemo init');
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onError: (e) => debugPrint('[SPEECH ERROR] $e'),
      onStatus: (s) => debugPrint('[SPEECH STATUS] $s'),
    );
    debugPrint('[DEBUG] _speech.initialize -> $available');
  }

  Future<void> _checkMicPermission() async {
    final status = await Permission.microphone.status;
    debugPrint('[DEBUG] mic permission status: $status');
    if (!status.isGranted) {
      final res = await Permission.microphone.request();
      debugPrint('[DEBUG] mic permission request -> $res');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  // -------------- Start / Stop Listening --------------
  Future<void> _startListening() async {
    // Ensure initialized
    final initialized = await _speech.initialize(
      onError: (e) => debugPrint('[SPEECH ERROR] $e'),
      onStatus: (s) => debugPrint('[SPEECH STATUS] $s'),
    );
    debugPrint('[DEBUG] startListening initialize returned $initialized');

    if (!initialized) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech not available')));
      return;
    }

    // Start listening with partial results. pauseFor controls silence threshold.
    await _speech.listen(
      localeId: 'hi-IN',
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(seconds: 5), // wait 5s of silence to finalize
      listenFor: const Duration(minutes: 30),
      onResult: _onSpeechResult,
    );

    setState(() {
      _isListening = true;
      _recognizedText = ''; // clear interim text at start
    });

    debugPrint('[DEBUG] Listening started');
  }

  Future<void> _stopListening() async {
    // wait a little to naturally finish finalization
    await Future.delayed(const Duration(seconds: 2));
    await _speech.stop();
    setState(() {
      _isListening = false;
      _recognizedText = '';
    });
    debugPrint('[DEBUG] Listening stopped');
  }

  void _onMicPressed() {
    debugPrint('[DEBUG] Mic pressed. _isListening=$_isListening');
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // -------------- Speech Result Handler --------------
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    debugPrint('---[SPEECH RESULT]---');
    debugPrint('recognizedWords: "${result.recognizedWords}"');
    debugPrint('finalResult: ${result.finalResult}');
    debugPrint('confidence: ${result.confidence}');
    debugPrint('----------------------');

    setState(() {
      _recognizedText = result.recognizedWords;
    });

    if (result.finalResult) {
      // wait 2-3s post-final to allow natural trailing words, then handle
      Future.delayed(const Duration(seconds: 3), () {
        _handleFinalResult(result.recognizedWords);
      });

      // continuous mode: restart listen if still intended
      if (_isListening) {
        try {
          debugPrint('[DEBUG] restarting listen for continuous mode');
          _speech.listen(
            localeId: 'hi-IN',
            partialResults: true,
            listenMode: stt.ListenMode.dictation,
            pauseFor: const Duration(seconds: 5),
            listenFor: const Duration(minutes: 30),
            onResult: _onSpeechResult,
          );
        } catch (e, st) {
          debugPrint('[ERROR] could not restart listen: $e\n$st');
        }
      }
    }
  }

  // -------------- Transliteration & Normalization --------------
  /// Convert Devanagari characters to a rough latin phonetic form.
  /// This is character-level transliteration (not perfect but robust).
  String devToEng(String input) {
    if (input.isEmpty) return '';

    // If input is already plain ASCII letters/numbers, return lowercase directly
    if (RegExp(r'^[\x00-\x7F]+$').hasMatch(input)) {
      return input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    const map = {
      // vowels + matras
      'अ': 'a', 'आ': 'aa', 'ा': 'a', 'इ': 'i', 'ई': 'ii', 'ि': 'i', 'ी': 'ii',
      'उ': 'u', 'ऊ': 'uu', 'ु': 'u', 'ू': 'uu',
      'ए': 'e', 'ऐ': 'ai', 'ो': 'o', 'औ': 'au', 'ओ': 'o',
      // consonants (simple)
      'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'ng',
      'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
      'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
      'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
      'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
      'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v',
      'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
      // others
      'ं': 'n', 'ः': 'h', 'ँ': 'n', '़': '',
      '।': ' ', '॥': ' ',
    };

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      buffer.write(map[ch] ?? ch);
    }

    String out = buffer.toString().toLowerCase();

    // Normalize:
    // - collapse runs of 'aa'/'ii'/'uu' into single vowel markers (approx.)
    // - replace multiple spaces with one
    // - remove non-alphanumeric except spaces
    out = out.replaceAll(RegExp(r'aa+'), 'a');
    out = out.replaceAll(RegExp(r'ii+'), 'i');
    out = out.replaceAll(RegExp(r'uu+'), 'u');
    out = out.replaceAll(RegExp(r'oo+'), 'u'); // map oo->u approx
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    out = out.replaceAll(RegExp(r'[^a-z0-9 ]'), ''); // keep a-z0-9 & spaces

    // compress repeated letters (e.g., "gooogl" -> "gogol" becomes "gogol" but we compress strict repeats)
    out = out.replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m.group(1) ?? '');

    return out;
  }

  // Normalize english/hybrid tokens for comparison
  String normalizeToken(String s) {
    var t = s.toLowerCase().trim();
    t = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
    // reduce repeated letters (aaaa -> aa)
    t = t.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m.group(1)!);
    return t;
  }

  // Simple Levenshtein distance (small inputs)
  int levenshtein(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    List<List<int>> d = List.generate(la + 1, (_) => List.filled(lb + 1, 0));
    for (int i = 0; i <= la; i++) d[i][0] = i;
    for (int j = 0; j <= lb; j++) d[0][j] = j;
    for (int i = 1; i <= la; i++) {
      for (int j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost
        ].reduce((v, e) => v < e ? v : e);
      }
    }
    return d[la][lb];
  }

  // Checks if targetTokens matches a window in textTokens with fuzzy tolerance
  bool fuzzyTokensMatch(List<String> textTokens, int start, List<String> targetTokens) {
    final n = targetTokens.length;
    if (start + n > textTokens.length) return false;

    int totalDistance = 0;
    int totalLen = 0;
    for (int i = 0; i < n; i++) {
      final a = normalizeToken(textTokens[start + i]);
      final b = normalizeToken(targetTokens[i]);
      final dist = levenshtein(a, b);
      totalDistance += dist;
      totalLen += (b.length == 0 ? 1 : b.length);
    }

    // average edit distance per char
    final avg = totalLen == 0 ? 1.0 : totalDistance / totalLen;
    // allow some tolerance: avg <= 0.45 is fairly permissive
    return avg <= 0.45;
  }

  // -------------- Final Matching & Counting --------------
  void _handleFinalResult(String finalText) {
    debugPrint('[DEBUG] _handleFinalResult raw: "$finalText"');

    if (_selectedGod == null) {
      debugPrint('[DEBUG] no selected god -> abort');
      return;
    }
    if (_isCountingPaused) {
      debugPrint('[DEBUG] counting paused -> abort');
      return;
    }

    // Convert both sides to phonetic Latin-ish and normalize
    final converted = devToEng(finalText);
    final target = devToEng(_selectedGod!.name);

    debugPrint('[DEBUG] converted spoken: "$converted"');
    debugPrint('[DEBUG] converted target:  "$target"');

    if (converted.isEmpty || target.isEmpty) {
      debugPrint('[DEBUG] empty converted text/target -> abort');
      return;
    }

    final textTokens = converted.split(' ').where((s) => s.isNotEmpty).toList();
    final targetTokens = target.split(' ').where((s) => s.isNotEmpty).toList();

    debugPrint('[DEBUG] textTokens=$textTokens');
    debugPrint('[DEBUG] targetTokens=$targetTokens');

    // Sliding window over textTokens to find matches of targetTokens sequence
    int matches = 0;
    for (int i = 0; i <= textTokens.length - targetTokens.length; i++) {
      if (fuzzyTokensMatch(textTokens, i, targetTokens)) {
        matches++;
        debugPrint('[DEBUG] fuzzy match at index $i -> window=${textTokens.sublist(i, i + targetTokens.length)}');
        // advance i to skip overlapping matches
        i += targetTokens.length - 1;
      }
    }

    // As a last resort: check substring (exact) on converted strings
    if (matches == 0 && converted.contains(target)) {
      debugPrint('[DEBUG] fallback exact contains found');
      // count occurrences naive non-overlapping
      int idx = 0;
      while ((idx = converted.indexOf(target, idx)) != -1) {
        matches++;
        idx += target.length;
      }
    }

    debugPrint('[DEBUG] total matches found = $matches');

    if (matches <= 0) {
      debugPrint('[DEBUG] no matches -> not incrementing');
      return;
    }

    final notifier = ref.read(godListProvider.notifier);
    for (int i = 0; i < matches; i++) {
      notifier.incrementCount(_selectedGod!.id);
      debugPrint('[DEBUG] incremented for ${_selectedGod!.name} (${i + 1}/$matches)');
    }
  }

  // -------------- UI / Helper --------------
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

    // Only update selected if null or changed externally
    if (_selectedGod == null || (selected != null && selected.id != _selectedGod!.id)) {
      _selectedGod = selected;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFA726),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.temple_hindu, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Naam Jaap — Voice Counter', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _toggleCountingPause,
                    icon: Icon(_isCountingPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                    label: Text(_isCountingPaused ? 'RESUME' : 'STOP', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: _isCountingPaused ? Colors.grey[800] : Colors.black),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Dropdown + total
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
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
                        items: gods.map((g) => DropdownMenuItem(value: g, child: Text(g.name, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (g) => setState(() => _selectedGod = g),
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Total', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                        Text('${selected.totalCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Mic
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: _onMicPressed,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _isListening ? [Colors.white, Colors.orange.shade300] : [Colors.white70, Colors.orange.shade800]),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, spreadRadius: 4)],
                        ),
                        child: Center(child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 56, color: Colors.black87)),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Recognized text or listening hint
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              child: Text(
                _isListening ? (_recognizedText.isEmpty ? '🎤 Listening...' : _recognizedText) : '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
