import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class AiDemo extends StatefulWidget {
  const AiDemo({super.key});

  @override
  State<AiDemo> createState() => _AiDemoState();
}

class _AiDemoState extends State<AiDemo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  String _selectedGod = 'Krishna';
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _checkMicPermission();
  }

  Future<void> _checkMicPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      await Permission.microphone.request();
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          // Restart listening if stopped automatically
          if (status == "done") {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint("Speech error: $error");
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
          _count = 0;
        });

        _speech.listen(
          onResult: (result) {
            final text = result.recognizedWords.trim();

            setState(() {
              _recognizedText = text;
            });

            if (text.isNotEmpty) {
              final lowerText = text.toLowerCase();
              final lowerGod = _selectedGod.toLowerCase();

              // Check if the word appears
              if (lowerText.contains(lowerGod)) {
                setState(() {
                  _count++;
                });
              }
            }
          },
          listenMode: stt.ListenMode.dictation,
          localeId: "en-IN", // can change to 'hi-IN' for Hindi
          partialResults: true,
        );
      } else {
        debugPrint("Speech recognition not available");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Title
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(
                "Naam Jup Counter - Shradha",
                style: GoogleFonts.poppins(
                  color: Colors.tealAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Center pulsing microphone
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [Colors.greenAccent, Colors.teal]
                              : [Colors.tealAccent, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom UI: Dropdown + captions + count
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedGod,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.tealAccent),
                    items: ['Krishna', 'Shiva', 'Ram', 'Durga', 'Hanuman']
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedGod = value!);
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _isListening
                        ? "🎙️ Listening for '$_selectedGod'..."
                        : "Tap the circle to start listening",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.tealAccent, width: 1),
                    ),
                    child: Text(
                      _recognizedText.isEmpty
                          ? "Say something..."
                          : _recognizedText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.tealAccent,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "🕉️ Count: $_count",
                    style: GoogleFonts.poppins(
                      color: Colors.tealAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
