import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math' show min;  // Add this import

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
      if (prompt.isEmpty) {
        print('Empty prompt received');
        return 'Error: Empty prompt';
      }

      print('Sending prompt to model: ${prompt.substring(0, min(100, prompt.length))}...');

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        print('Model output: ${response.text!.substring(0, min(100, response.text!.length))}...');
        return response.text!;
      } else {
        print('No content generated');
        return 'No content generated';
      }
    } catch (e) {
      print('Error generating content: $e');
      return 'Error generating content: $e';
    }
  }

  Future<String> generateSummary(String fullContent, List<String> urls) async {
    try {
      final urlsString = urls.isNotEmpty ? urls.join('\n') : 'No URLs provided';
      final prompt = '''
Please summarize the following content into a concise podcast episode summary. Use bullet points for key points.

Content:
$fullContent

URLs:
$urlsString

Summary format:
- Brief overview of the episode (1-2 sentences)
- Key points (3-5 bullet points)
- Relevant URLs (if any)

Important:
- Only include information that is present in the provided content.
- Do not use placeholders or templated responses like "[Insert specific key point]" or "[Insert URL]".
- If there are no relevant URLs, omit that section from the summary.
- Keep the summary concise yet informative, capturing the main ideas and highlights of the content.

Please provide the summary without any additional explanations or meta-commentary.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        print('Generated summary: ${response.text}');
        return response.text!;
      } else {
        print('No summary generated');
        return 'No summary generated';
      }
    } catch (e) {
      print('Error generating summary: $e');
      return 'Error generating summary';
    }
  }

  Future<String> generatePodcastTitle(String content) async {
    try {
      final prompt = '''
Based on the following content, generate a catchy and unique podcast title. The title should:
1. Always start with today's date in the format "MM/DD: "
2. Be engaging and reflect the main theme or highlight of the content
3. Be concise, ideally not exceeding 50 characters including the date

Content:
$content

Please provide only the title, without any additional explanation.
''';

      final promptContent = [Content.text(prompt)];
      final response = await _model.generateContent(promptContent);
      
      if (response.text != null) {
        print('Generated podcast title: ${response.text}');
        return response.text!.trim();
      } else {
        print('No podcast title generated');
        return 'No podcast title generated';
      }
    } catch (e) {
      print('Error generating podcast title: $e');
      return 'Error generating podcast title';
    }
  }
}