import 'package:mcp_llm/mcp_llm.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiProvider extends LlmProvider {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiProvider({required this.apiKey}) {
    _model = GenerativeModel(apiKey: apiKey);
  }

  @override
  Future<ChatResponse> chat(String prompt) async {
    final response = await _model.chat(prompt);
    return ChatResponse(text: response.text);
  }
}

// Factory สำหรับ McpLlm
class GeminiProviderFactory extends LlmProviderFactory {
  @override
  LlmProvider create(Map<String, dynamic> config) {
    final apiKey = config['apiKey'] as String? ?? '';
    return GeminiProvider(apiKey: apiKey);
  }
}
