import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSController extends GetxController {
  final FlutterTts flutterTts = FlutterTts();
  var isSpeaking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    isSpeaking.value = true;
    await flutterTts.speak(text);
  }

  Future<void> stop() async {
    isSpeaking.value = false;
    await flutterTts.stop();
  }
}