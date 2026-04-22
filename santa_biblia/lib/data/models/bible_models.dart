class BibleVersion {
  final String id;
  final String language;
  final String name;
  final String abbreviation;
  final String description;
  final bool isPublicDomain;

  const BibleVersion({
    required this.id,
    required this.language,
    required this.name,
    required this.abbreviation,
    required this.description,
    required this.isPublicDomain,
  });

  factory BibleVersion.fromMap(Map<String, dynamic> map) => BibleVersion(
    id: map['id'] as String,
    language: map['language'] as String,
    name: map['name'] as String,
    abbreviation: map['abbreviation'] as String,
    description: map['description'] as String,
    isPublicDomain: (map['isPublicDomain'] as bool?) ?? true,
  );
}

class BibleBook {
  final int id;
  final String nameEs;
  final String nameEn;
  final int chapters;
  final String testament;
  final String abbreviation;

  const BibleBook({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.chapters,
    required this.testament,
    required this.abbreviation,
  });

  factory BibleBook.fromMap(Map<String, dynamic> map) => BibleBook(
    id: map['id'] as int,
    nameEs: map['name_es'] as String,
    nameEn: map['name_en'] as String,
    chapters: map['chapters'] as int,
    testament: map['testament'] as String,
    abbreviation: map['abbreviation'] as String,
  );

  String name(String language) => language == 'es' ? nameEs : nameEn;

  bool get isOldTestament => testament == 'OT';
}

class BibleVerse {
  final int id;
  final String versionId;
  final int bookId;
  final int chapter;
  final int verse;
  final String text;

  const BibleVerse({
    required this.id,
    required this.versionId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromMap(Map<String, dynamic> map) => BibleVerse(
    id: map['id'] as int,
    versionId: map['version_id'] as String,
    bookId: map['book_id'] as int,
    chapter: map['chapter'] as int,
    verse: map['verse'] as int,
    text: map['text'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'version_id': versionId,
    'book_id': bookId,
    'chapter': chapter,
    'verse': verse,
    'text': text,
  };

  String get reference => '$bookId $chapter:$verse';
}

class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final List<BibleVerse>? referencedVerses;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.referencedVerses,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    List<BibleVerse>? referencedVerses,
  }) => ChatMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    timestamp: timestamp,
    referencedVerses: referencedVerses ?? this.referencedVerses,
    isLoading: isLoading ?? this.isLoading,
  );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

enum AiProvider {
  gemini('Gemini', 'Google Gemini', true),
  openai('OpenAI', 'GPT-4o', true),
  anthropic('Anthropic', 'Claude', true),
  mistral('Mistral', 'Mistral AI', true),
  groq('Groq', 'Groq (Llama/Gemma)', true),
  ollama('Ollama', 'Local (Ollama)', false);

  final String id;
  final String displayName;
  final bool requiresApiKey;

  const AiProvider(this.id, this.displayName, this.requiresApiKey);
}

class AppSettings {
  final ThemeModePreference themeMode;
  final String language;
  final String bibleVersion;
  final double fontSize;
  final AiProvider aiProvider;
  final String aiApiKey;
  final String backendUrl;

  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.bibleVersion,
    required this.fontSize,
    required this.aiProvider,
    required this.aiApiKey,
    required this.backendUrl,
  });

  AppSettings copyWith({
    ThemeModePreference? themeMode,
    String? language,
    String? bibleVersion,
    double? fontSize,
    AiProvider? aiProvider,
    String? aiApiKey,
    String? backendUrl,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    bibleVersion: bibleVersion ?? this.bibleVersion,
    fontSize: fontSize ?? this.fontSize,
    aiProvider: aiProvider ?? this.aiProvider,
    aiApiKey: aiApiKey ?? this.aiApiKey,
    backendUrl: backendUrl ?? this.backendUrl,
  );
}

enum ThemeModePreference { light, dark, system }
