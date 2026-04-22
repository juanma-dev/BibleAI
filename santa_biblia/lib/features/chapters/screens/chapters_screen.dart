import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../settings/providers/settings_provider.dart';
import '../../chat/providers/chat_provider.dart';

class ChaptersScreen extends ConsumerWidget {
  final int bookId;

  const ChaptersScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final bookData = BibleConstants.bibleBooks.firstWhere((b) => b['id'] == bookId);
    final book = BibleBook.fromMap(bookData);
    final bookName = book.name(settings.language);
    final totalChapters = book.chapters;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(bookName),
            Text(
              settings.language == 'es'
                  ? '${totalChapters} capítulos'
                  : '${totalChapters} chapters',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // AI chat button for book context
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: settings.language == 'es' ? 'Preguntar sobre este libro' : 'Ask about this book',
            onPressed: () {
              ref.read(chatProvider.notifier).sendChapterQuery(
                bookName,
                0, // 0 means whole book context
                settings.language,
              );
              ref.read(chatVisibleProvider.notifier).state = true;
              context.push('/reader/${book.id}/1');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Book info banner
          _BookInfoBanner(book: book, language: settings.language, colorScheme: colorScheme, theme: theme),
          // Chapters grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 72,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: totalChapters,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                return _ChapterButton(
                  chapter: chapter,
                  onTap: () => context.push('/reader/${book.id}/$chapter'),
                ).animate().scale(
                  delay: Duration(milliseconds: index * 10),
                  duration: 200.ms,
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookInfoBanner extends StatelessWidget {
  final BibleBook book;
  final String language;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _BookInfoBanner({
    required this.book,
    required this.language,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            book.isOldTestament ? Icons.history_edu_rounded : Icons.auto_stories_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              language == 'es'
                  ? book.isOldTestament ? 'Antiguo Testamento' : 'Nuevo Testamento'
                  : book.isOldTestament ? 'Old Testament' : 'New Testament',
              style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Text(
            'Libro ${book.id} • ${book.abbreviation}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ChapterButton extends StatelessWidget {
  final int chapter;
  final VoidCallback onTap;

  const _ChapterButton({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Center(
            child: Text(
              '$chapter',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
