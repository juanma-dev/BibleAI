import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../settings/providers/settings_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/widgets/chat_panel.dart';
import '../providers/reader_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final int initialChapter;
  final int? highlightVerse;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.initialChapter,
    this.highlightVerse,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  int _currentChapter = 0;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _pageController = PageController(initialPage: _currentChapter - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readerProvider.notifier).loadChapter(
        bookId: widget.bookId,
        chapter: _currentChapter,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    final chapter = page + 1;
    if (chapter == _currentChapter) return;
    setState(() => _currentChapter = chapter);
    ref.read(readerProvider.notifier).loadChapter(
      bookId: widget.bookId,
      chapter: chapter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final readerState = ref.watch(readerProvider);
    final chatVisible = ref.watch(chatVisibleProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bookData = BibleConstants.bibleBooks.firstWhere((b) => b['id'] == widget.bookId);
    final book = BibleBook.fromMap(bookData);
    final totalChapters = book.chapters;
    final bookName = book.name(settings.language);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(
        context, bookName, readerState, settings, colorScheme, theme,
      ),
      body: Column(
        children: [
          // Bible reader (PageView for swipe navigation)
          Expanded(
            flex: chatVisible ? 55 : 100,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: totalChapters,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                return _ChapterPage(
                  bookId: widget.bookId,
                  chapter: chapter,
                  bookName: bookName,
                  isActive: chapter == _currentChapter,
                  highlightVerse: chapter == widget.initialChapter ? widget.highlightVerse : null,
                  fontSize: settings.fontSize,
                  language: settings.language,
                );
              },
            ),
          ),

          // Chat panel
          if (chatVisible)
            const Expanded(
              flex: 45,
              child: ChatPanel(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String bookName,
    ReaderState? state,
    AppSettings settings,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final chatVisible = ref.watch(chatVisibleProvider);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => context.pop(),
      ),
      title: GestureDetector(
        onTap: () => context.push('/chapters/${widget.bookId}'),
        child: Column(
          children: [
            Text(bookName),
            if (state != null)
              Text(
                settings.language == 'es'
                    ? 'Capítulo ${state.chapter}'
                    : 'Chapter ${state.chapter}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Font size toggle
        IconButton(
          icon: const Icon(Icons.format_size_rounded),
          onPressed: () => _showFontSizeDialog(context, settings),
        ),
        // Theme toggle
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            final current = ref.read(settingsProvider).themeMode;
            final next = current == ThemeModePreference.dark
                ? ThemeModePreference.light
                : ThemeModePreference.dark;
            ref.read(settingsProvider.notifier).setThemeMode(next);
          },
        ),
        // Chat toggle
        IconButton(
          icon: Icon(
            chatVisible ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
            color: chatVisible ? colorScheme.primary : null,
          ),
          onPressed: () {
            ref.read(chatVisibleProvider.notifier).state = !chatVisible;
          },
        ),
        // Settings
        IconButton(
          tooltip: 'Configuración',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  void _showFontSizeDialog(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FontSizeSheet(currentSize: settings.fontSize),
    );
  }
}

class _ChapterPage extends ConsumerStatefulWidget {
  final int bookId;
  final int chapter;
  final String bookName;
  final bool isActive;
  final int? highlightVerse;
  final double fontSize;
  final String language;

  const _ChapterPage({
    required this.bookId,
    required this.chapter,
    required this.bookName,
    required this.isActive,
    required this.highlightVerse,
    required this.fontSize,
    required this.language,
  });

  @override
  ConsumerState<_ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends ConsumerState<_ChapterPage> {
  List<BibleVerse> _verses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // On web always load directly (no provider/SQLite involved)
    if (kIsWeb || !widget.isActive) {
      _loadVerses();
    } else {
      _listenToProvider();
    }
  }

  void _listenToProvider() {
    final state = ref.read(readerProvider);
    if (state != null && state.bookId == widget.bookId && state.chapter == widget.chapter && !state.isLoading) {
      setState(() {
        _verses = state.verses;
        _loading = false;
      });
    } else {
      _loadVerses();
    }
  }

  Future<void> _loadVerses() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    final repo = ref.read(bibleRepositoryProvider);
    final settings = ref.read(settingsProvider);
    try {
      final verses = await repo.getChapter(
        versionId: settings.bibleVersion,
        bookId: widget.bookId,
        chapter: widget.chapter,
      );
      if (mounted) setState(() { _verses = verses; _loading = false; });
    } catch (e) {
      debugPrint('ERROR AL CARGAR VERSICULOS: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  void didUpdateWidget(_ChapterPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      final state = ref.read(readerProvider);
      if (state != null && !state.isLoading) {
        setState(() { _verses = state.verses; _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActive) {
      ref.listen(readerProvider, (_, next) {
        if (next != null && next.bookId == widget.bookId && next.chapter == widget.chapter) {
          if (mounted) setState(() { _verses = next.verses; _loading = next.isLoading; });
        }
      });
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    if (_verses.isEmpty) {
      // Error state
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  settings.language == 'es' ? 'Error al cargar' : 'Error loading',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  settings.language == 'es'
                      ? 'Verifica tu conexión a internet e intenta de nuevo.\nError real: $_error'
                      : 'Check your internet connection and try again.\nError: $_error',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadVerses,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(settings.language == 'es' ? 'Reintentar' : 'Retry'),
                ),
              ],
            ),
          ),
        );
      }
      // Loading / first-time download state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48, height: 48,
              child: CircularProgressIndicator(
                color: colorScheme.primary, strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'es' ? 'Cargando versículos...' : 'Loading verses...',
              style: theme.textTheme.bodyMedium,
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 8),
              Text(
                settings.language == 'es'
                    ? 'Obteniendo de bible-api.com'
                    : 'Fetching from bible-api.com',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _verses.length + 2, // +2 for header and footer nav
      itemBuilder: (context, index) {
        if (index == 0) return _ChapterHeader(
          bookName: widget.bookName,
          chapter: widget.chapter,
          language: widget.language,
          colorScheme: colorScheme,
          theme: theme,
        );

        if (index == _verses.length + 1) return _ChapterNavFooter(
          bookId: widget.bookId,
          chapter: widget.chapter,
          bookName: widget.bookName,
          language: widget.language,
        );

        final verse = _verses[index - 1];
        final isHighlighted = verse.verse == widget.highlightVerse;

        return _VerseWidget(
          verse: verse,
          bookName: widget.bookName,
          isHighlighted: isHighlighted,
          fontSize: widget.fontSize,
          language: widget.language,
          isDark: isDark,
          colorScheme: colorScheme,
          theme: theme,
        );
      },
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final String bookName;
  final int chapter;
  final String language;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _ChapterHeader({
    required this.bookName,
    required this.chapter,
    required this.language,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            bookName,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: colorScheme.primary.withOpacity(0.4)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  language == 'es' ? 'Capítulo $chapter' : 'Chapter $chapter',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(width: 40, height: 1, color: colorScheme.primary.withOpacity(0.4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerseWidget extends ConsumerWidget {
  final BibleVerse verse;
  final String bookName;
  final bool isHighlighted;
  final double fontSize;
  final String language;
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _VerseWidget({
    required this.verse,
    required this.bookName,
    required this.isHighlighted,
    required this.fontSize,
    required this.language,
    required this.isDark,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ref_ = '$bookName ${verse.chapter}:${verse.verse}';

    return GestureDetector(
      onTap: () => _showVerseActions(context, ref, ref_),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted
              ? colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              // Verse number
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  margin: const EdgeInsets.only(right: 6, top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${verse.verse}',
                    style: GoogleFonts.lato(
                      fontSize: fontSize * 0.65,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              // Verse text
              TextSpan(
                text: verse.text,
                style: GoogleFonts.lora(
                  fontSize: fontSize,
                  height: 1.85,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(target: isHighlighted ? 1 : 0).tint(
      color: colorScheme.primary.withOpacity(0.08),
    );
  }

  void _showVerseActions(BuildContext context, WidgetRef ref, String ref_) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VerseActionSheet(
        verse: verse,
        bookName: bookName,
        language: language,
        onAskAI: () {
          Navigator.pop(ctx);
          ref.read(chatProvider.notifier).sendVerseQuery(verse, bookName, language);
          ref.read(chatVisibleProvider.notifier).state = true;
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: '$ref_\n${verse.text}'));
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(language == 'es' ? 'Versículo copiado' : 'Verse copied'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onShare: () {
          Navigator.pop(ctx);
          Share.share('$ref_\n\n${verse.text}\n\n— La Santa Biblia App');
        },
      ),
    );
  }
}

class _VerseActionSheet extends StatelessWidget {
  final BibleVerse verse;
  final String bookName;
  final String language;
  final VoidCallback onAskAI;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _VerseActionSheet({
    required this.verse,
    required this.bookName,
    required this.language,
    required this.onAskAI,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$bookName ${verse.chapter}:${verse.verse}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  verse.text,
                  style: GoogleFonts.lora(fontSize: 15, height: 1.6),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Actions
          Row(
            children: [
              _ActionButton(
                icon: Icons.smart_toy_rounded,
                label: language == 'es' ? 'Preguntar AI' : 'Ask AI',
                color: colorScheme.primary,
                onTap: onAskAI,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                icon: Icons.copy_rounded,
                label: language == 'es' ? 'Copiar' : 'Copy',
                color: colorScheme.secondary,
                onTap: onCopy,
              ),
              const SizedBox(width: 10),
              _ActionButton(
                icon: Icons.share_rounded,
                label: language == 'es' ? 'Compartir' : 'Share',
                color: colorScheme.tertiary,
                onTap: onShare,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterNavFooter extends ConsumerWidget {
  final int bookId;
  final int chapter;
  final String bookName;
  final String language;

  const _ChapterNavFooter({
    required this.bookId,
    required this.chapter,
    required this.bookName,
    required this.language,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state?.hasPrevChapter ?? false)
            _NavButton(
              label: language == 'es' ? 'Anterior' : 'Previous',
              icon: Icons.arrow_back_ios_rounded,
              iconAtStart: true,
              onTap: () => ref.read(readerProvider.notifier).prevChapter(),
              colorScheme: colorScheme,
            )
          else
            const SizedBox(width: 100),
          // Chapter indicator
          Text(
            language == 'es' ? 'Cap. ${state?.chapter ?? chapter}' : 'Ch. ${state?.chapter ?? chapter}',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state?.hasNextChapter ?? false)
            _NavButton(
              label: language == 'es' ? 'Siguiente' : 'Next',
              icon: Icons.arrow_forward_ios_rounded,
              iconAtStart: false,
              onTap: () => ref.read(readerProvider.notifier).nextChapter(),
              colorScheme: colorScheme,
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconAtStart;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.iconAtStart,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (iconAtStart) ...[
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            if (!iconAtStart) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 14, color: colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _FontSizeSheet extends ConsumerWidget {
  final double currentSize;

  const _FontSizeSheet({required this.currentSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            settings.language == 'es' ? 'Tamaño del texto' : 'Text size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: 14,
                  max: 28,
                  divisions: 7,
                  activeColor: colorScheme.primary,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setFontSize(v),
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          Text(
            '${settings.fontSize.round()} px',
            style: GoogleFonts.lato(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
