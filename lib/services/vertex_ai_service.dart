import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';

class VertexAIService {
  late final GenerativeModel _model;

  VertexAIService() {
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    await Firebase.initializeApp();
    
    final safetySettings = [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    ];

    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
      safetySettings: safetySettings,
    );
  }

  Future<String> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        print('Model output: ${response.text}');
        return response.text!;
      } else {
        print('No content generated');
        return 'No content generated';
      }
    } catch (e) {
      print('Error generating content: $e');
      return 'Error generating content';
    }
  }
}