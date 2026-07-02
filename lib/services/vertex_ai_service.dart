import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class VertexAiService {
  final String _projectId = "smartmeal-fyp-501109";
  final String _apiKey = AppConfig.gcpApiKey;
  final String _location = "us-central1";
  final String _model = "gemini-2.5-flash";

  /// Sends a captured image to the Google Cloud Vertex AI Gemini model
  /// and returns a list of identified ingredients.
  Future<List<String>> scanIngredients(File imageFile) async {
    final endpoint = "https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/$_model:generateContent?key=$_apiKey";
    
    try {
      // 1. Read image bytes and encode to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Get MIME type based on file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = (extension == 'png') ? 'image/png' : 'image/jpeg';

      // 2. Prepare request payload
      final requestBody = jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": "Identify all distinct food ingredients visible in this image. "
                    "Return ONLY a valid JSON array of strings containing the ingredient names, for example: [\"Chicken\", \"Onions\", \"Cheese\"]. "
                    "Do not include any other text, conversational elements, or markdown code block backticks (like ```json). "
                    "If no clear food ingredients are recognized, return an empty array []."
              },
              {
                "inlineData": {
                  "mimeType": mimeType,
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "maxOutputTokens": 300,
          "responseMimeType": "application/json"
        }
      });

      // 3. Send HTTP POST request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
        },
        body: requestBody,
      );

      // 4. Parse the response
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          final parts = content?['parts'] as List?;
          
          if (parts != null && parts.isNotEmpty) {
            String textResult = parts[0]['text'] as String? ?? "[]";
            
            // Clean up model response just in case it included markdown wrappers
            textResult = textResult.trim();
            if (textResult.startsWith("```json")) {
              textResult = textResult.substring(7);
            }
            if (textResult.startsWith("```")) {
              textResult = textResult.substring(3);
            }
            if (textResult.endsWith("```")) {
              textResult = textResult.substring(0, textResult.length - 3);
            }
            textResult = textResult.trim();

            final decoded = jsonDecode(textResult);
            if (decoded is List) {
              return decoded.map((e) => e.toString().trim()).toList();
            }
          }
        }
        return [];
      } else {
        throw Exception("Vertex AI request failed with status: ${response.statusCode}\nBody: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error scanning ingredients with Vertex AI: $e");
    }
  }
}
