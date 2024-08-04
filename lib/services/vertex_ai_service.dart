import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math' show min;
import 'package:home/prompt.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VertexAIService {
  late final GenerativeModel _model;
  final String language;

  VertexAIService({required this.language}) {
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

  String _replaceLanguagePlaceholder(String prompt) {
    return prompt.replaceAll('{language}', language);
  }

  Future<String> generateContent(String prompt) async {
    try {
      if (prompt.isEmpty) {
        print('Empty prompt received');
        return 'Error: Empty prompt';
      }

      prompt = _replaceLanguagePlaceholder(prompt);
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
      final prompt = _replaceLanguagePlaceholder('''
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

Answer in the {language} only.
''');

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

  Future<String> generatePodcastTitle(String description, String dateRange) async {
    final prompt = _replaceLanguagePlaceholder('''
${podcastTitlePrompt.replaceAll('{Placeholder for description}', description).replaceAll('{Placeholder for date range}', dateRange)}

IMPORTANT: Return ONLY the generated title, without any explanations or additional text. The title should be a single line, concise, and no longer than 10 words.
''');

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    if (response.text != null) {
      final title = response.text!.trim();
      print('Generated podcast title: $title');
      return title;
    } else {
      print('No podcast title generated');
      throw Exception('Failed to generate podcast title');
    }
  }

  Future<String> generateImagePrompt(String fullDescription) async {
    final prompt = _replaceLanguagePlaceholder(imagePrompt.replaceAll('{Placeholder for transcript}', fullDescription));
    
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    if (response.text != null) {
      print('Generated image prompt: ${response.text}');
      return response.text!;
    } else {
      print('No image prompt generated');
      throw Exception('Failed to generate image prompt');
    }
  }
}