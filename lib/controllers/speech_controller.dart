import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechController extends GetxController {
  late stt.SpeechToText _speech;
  var isListening = false.obs;
  var recognizedText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _speech = stt.SpeechToText();
  }

  Future<String> startListening() async {
    recognizedText.value = '';
    bool available = await _speech.initialize();

    if (available) {
      isListening.value = true;
      _speech.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          if (result.finalResult) {
            isListening.value = false;
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      // Wait for completion
      await Future.delayed(const Duration(seconds: 5));
      _speech.stop();
      isListening.value = false;
    }

    return recognizedText.value;
  }

  void stopListening() {
    _speech.stop();
    isListening.value = false;
  }
}