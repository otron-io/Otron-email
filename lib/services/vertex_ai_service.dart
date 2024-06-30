import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';

class VertexAIService {
  final FirebaseVertexAI _vertexAI;

  VertexAIService() : _vertexAI = FirebaseVertexAI.instance;

  Future<String> generateContent(String promptText) async {
    return await _generateContent(promptText, isStream: false);
  }

  Stream<String> generateContentStream(String promptText) async* {
    yield* _generateContentStream(promptText);
  }

  Future<String> _generateContent(String promptText, {required bool isStream}) async {
    final model = _vertexAI.generativeModel(model: 'gemini-1.5-flash');
    final prompt = [Content.text(promptText)];

    try {
      final response = await model.generateContent(prompt);
      return response.text ?? 'No content generated';
    } catch (e) {
      print('Error generating content: $e');
      return 'Error generating content';
    }
  }

  Stream<String> _generateContentStream(String promptText) async* {
    final model = _vertexAI.generativeModel(model: 'gemini-1.5-flash');
    final prompt = [Content.text(promptText)];

    try {
      final response = model.generateContentStream(prompt);
      await for (final chunk in response) {
        yield chunk.text ?? 'No content generated';
      }
    } catch (e) {
      print('Error generating content: $e');
      yield 'Error generating content';
    }
  }
}