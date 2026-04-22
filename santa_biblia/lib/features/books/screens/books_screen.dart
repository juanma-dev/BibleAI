import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../settings/providers/settings_provider.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final books = BibleConstants.bibleBooks.map(BibleBook.fromMap).toList();
    final otBooks = books.where((b) => b.isOldTestament).toList();
    final ntBooks = books.where((b) => !b.isOldTestament).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(settings.language == 'es' ? 'Libros de la Biblia' : 'Books of the Bible'),
            Text(
              BibleConstants.bibleVersions
                  .firstWhere((v) => v['id'] == settings.bibleVersion)['abbreviation'] as String,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildTestamentSection(
            context,
            label: settings.language == 'es' ? 'Antiguo Testamento' : 'Old Testament',
            subtitle: settings.language == 'es' ? '39 Libros' : '39 Books',
            books: otBooks,
            settings: settings,
            colorScheme: colorScheme,
            theme: theme,
            isDark: isDark,
            startIndex: 0,
          ),
          _buildTestamentSection(
            context,
            label: settings.language == 'es' ? 'Nuevo Testamento' : 'New Testament',
            subtitle: settings.language == 'es' ? '27 Libros' : '27 Books',
            books: ntBooks,
            settings: settings,
            colorScheme: colorScheme,
            theme: theme,
            isDark: isDark,
            startIndex: otBooks.length,
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildTestamentSection(
    BuildContext context, {
    required String label,
    required String subtitle,
    required List<BibleBook> books,
    required AppSettings settings,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required bool isDark,
    required int startIndex,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Testament header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: colorScheme.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          // Books list
          ...books.asMap().entries.map((entry) {
            final i = entry.key;
            final book = entry.value;
            return _BookTile(
              book: book,
              language: settings.language,
              onTap: () => context.push('/chapters/${book.id}'),
            ).animate().fadeIn(delay: (i * 25).ms).slideX(begin: 0.05, duration: 250.ms);
          }),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BibleBook book;
  final String language;
  final VoidCallback onTap;

  const _BookTile({required this.book, required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Book number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${book.id}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Book name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name(language),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    language == 'es'
                        ? '${book.chapters} capítulos'
                        : '${book.chapters} chapters',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
