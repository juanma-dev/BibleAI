import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/bible_database.dart';
import '../../../data/models/bible_models.dart';
import '../../../data/repositories/bible_repository.dart';
import '../../../core/constants/bible_constants.dart';
import '../../settings/providers/settings_provider.dart';

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository(BibleDatabase.instance);
});

class ReaderState {
  final int bookId;
  final String bookName;
  final int chapter;
  final int totalChapters;
  final List<BibleVerse> verses;
  final bool isLoading;
  final String? error;
  final int? highlightedVerse;

  const ReaderState({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.totalChapters,
    required this.verses,
    required this.isLoading,
    this.error,
    this.highlightedVerse,
  });

  bool get hasPrevChapter => chapter > 1;
  bool get hasNextChapter => chapter < totalChapters;

  ReaderState copyWith({
    int? bookId,
    String? bookName,
    int? chapter,
    int? totalChapters,
    List<BibleVerse>? verses,
    bool? isLoading,
    String? error,
    int? highlightedVerse,
  }) => ReaderState(
    bookId: bookId ?? this.bookId,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    totalChapters: totalChapters ?? this.totalChapters,
    verses: verses ?? this.verses,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    highlightedVerse: highlightedVerse ?? this.highlightedVerse,
  );
}

class ReaderNotifier extends StateNotifier<ReaderState?> {
  ReaderNotifier(this.ref) : super(null);

  final Ref ref;

  Future<void> loadChapter({
    required int bookId,
    required int chapter,
  }) async {
    final settings = ref.read(settingsProvider);
    final bookData = BibleConstants.bibleBooks.firstWhere((b) => b['id'] == bookId);
    final bookName = settings.language == 'es'
        ? bookData['name_es'] as String
        : bookData['name_en'] as String;

    state = ReaderState(
      bookId: bookId,
      bookName: bookName,
      chapter: chapter,
      totalChapters: bookData['chapters'] as int,
      verses: [],
      isLoading: true,
    );

    try {
      final repo = ref.read(bibleRepositoryProvider);
      final verses = await repo.getChapter(
        versionId: settings.bibleVersion,
        bookId: bookId,
        chapter: chapter,
      );

      state = state!.copyWith(verses: verses, isLoading: false);
    } catch (e) {
      state = state!.copyWith(
        isLoading: false,
        error: 'Error cargando capítulo: $e',
      );
    }
  }

  Future<void> nextChapter() async {
    final s = state;
    if (s == null || !s.hasNextChapter) return;
    await loadChapter(bookId: s.bookId, chapter: s.chapter + 1);
  }

  Future<void> prevChapter() async {
    final s = state;
    if (s == null || !s.hasPrevChapter) return;
    await loadChapter(bookId: s.bookId, chapter: s.chapter - 1);
  }

  void highlightVerse(int? verseNumber) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(highlightedVerse: verseNumber);
  }

  void clearHighlight() => highlightVerse(null);
}

final readerProvider = StateNotifierProvider<ReaderNotifier, ReaderState?>(
  (ref) => ReaderNotifier(ref),
);
