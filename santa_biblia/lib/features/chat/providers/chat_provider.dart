import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/bible_models.dart';
import '../../../core/constants/app_constants.dart';
import '../../settings/providers/settings_provider.dart';
import '../../reader/providers/reader_provider.dart';

// Chat visibility
final chatVisibleProvider = StateProvider<bool>((ref) => false);

// Chat panel height ratio (0.0 - 1.0)
final chatHeightRatioProvider = StateProvider<double>((ref) => 0.45);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this.ref) : super([]);

  final Ref ref;

  Future<void> sendMessage(String userText) async {
    final settings = ref.read(settingsProvider);
    final readerState = ref.read(readerProvider);

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: userText,
      timestamp: DateTime.now(),
    );
    final loadingMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_ai',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = [...state, userMsg, loadingMsg];

    try {
      // RAG: search relevant verses
      final bibleRepo = ref.read(bibleRepositoryProvider);
      final ragVerses = await bibleRepo.searchVerses(
        versionId: settings.bibleVersion,
        query: userText,
        limit: AppConstants.ragMaxVerses,
      );

      // Build context for AI
      final verseContext = ragVerses.isEmpty
          ? ''
          : '\n\nVersículos relevantes encontrados en ${settings.bibleVersion.toUpperCase()}:\n' +
              ragVerses.map((v) => '[${v.bookId} ${v.chapter}:${v.verse}] ${v.text}').join('\n');

      final currentContext = readerState != null
          ? '\nContexto actual: ${readerState.bookName} ${readerState.chapter}'
          : '';

      final aiResponse = await _callBackend(
        userMessage: userText,
        verseContext: verseContext,
        currentContext: currentContext,
        settings: settings,
      );

      // Replace loading with real response
      state = [
        ...state.where((m) => m.id != loadingMsg.id),
        ChatMessage(
          id: loadingMsg.id,
          role: 'assistant',
          content: aiResponse,
          timestamp: DateTime.now(),
          referencedVerses: ragVerses,
        ),
      ];
    } catch (e) {
      state = [
        ...state.where((m) => m.id != loadingMsg.id),
        ChatMessage(
          id: loadingMsg.id,
          role: 'assistant',
          content: 'Error al conectar con el asistente. Verifica tu conexión y configuración.',
          timestamp: DateTime.now(),
        ),
      ];
    }
  }

  Future<String> _callBackend({
    required String userMessage,
    required String verseContext,
    required String currentContext,
    required AppSettings settings,
  }) async {
    final uri = Uri.parse('${settings.backendUrl}/api/chat');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': userMessage,
        'verse_context': verseContext,
        'current_context': currentContext,
        'provider': settings.aiProvider.id,
        'api_key': settings.aiApiKey,
        'language': settings.language,
        'history': state
            .where((m) => !m.isLoading)
            .take(10)
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      }),
    ).timeout(AppConstants.httpTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['response'] as String? ?? 'Sin respuesta';
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  void sendVerseQuery(BibleVerse verse, String bookName, String language) {
    final ref_ = language == 'es'
        ? '$bookName ${verse.chapter}:${verse.verse}'
        : '$bookName ${verse.chapter}:${verse.verse}';
    final question = language == 'es'
        ? 'Explícame el versículo $ref_: "${verse.text}"'
        : 'Explain this verse $ref_: "${verse.text}"';
    sendMessage(question);
  }

  void sendChapterQuery(String bookName, int chapter, String language) {
    final question = language == 'es'
        ? 'Dame el contexto histórico y el mensaje principal de $bookName capítulo $chapter.'
        : 'Give me the historical context and main message of $bookName chapter $chapter.';
    sendMessage(question);
  }

  void clearChat() => state = [];
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(ref),
);
