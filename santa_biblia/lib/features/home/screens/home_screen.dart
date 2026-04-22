import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../settings/providers/settings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedLanguage = 'es';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _selectedLanguage = settings.language;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final versions = BibleConstants.bibleVersions
        .where((v) => v['language'] == _selectedLanguage)
        .map(BibleVersion.fromMap)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildHeader(theme, colorScheme),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 32),
                      _buildLanguageSelector(theme, colorScheme),
                      const SizedBox(height: 32),
                      _buildVersionsSection(
                          versions, settings, theme, colorScheme),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Configuración',
                onPressed: () => context.push('/settings'),
                icon: Icon(
                  Icons.settings_outlined,
                  color: colorScheme.primary,
                  size: 26,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.lightBackground, AppColors.lightSurface],
          ),
        ),
        child: Column(
          children: [
            // Cross icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 38,
                color: colorScheme.primary,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.3),
            const SizedBox(height: 6),
            Text(
              AppConstants.appSubtitle,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: colorScheme.primary,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Idioma / Language',
          style: theme.textTheme.titleSmall?.copyWith(
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _LanguageButton(
              flag: '🇪🇸',
              label: 'Español',
              selected: _selectedLanguage == 'es',
              onTap: () {
                setState(() => _selectedLanguage = 'es');
                ref.read(settingsProvider.notifier).setLanguage('es');
              },
            ),
            const SizedBox(width: 12),
            _LanguageButton(
              flag: '🇺🇸',
              label: 'English',
              selected: _selectedLanguage == 'en',
              onTap: () {
                setState(() => _selectedLanguage = 'en');
                ref.read(settingsProvider.notifier).setLanguage('en');
              },
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildVersionsSection(
    List<BibleVersion> versions,
    AppSettings settings,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedLanguage == 'es' ? 'Selecciona una Versión' : 'Select a Version',
          style: theme.textTheme.titleSmall?.copyWith(
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        ...versions.asMap().entries.map((entry) {
          final index = entry.key;
          final version = entry.value;
          return _VersionCard(
            version: version,
            isSelected: settings.bibleVersion == version.id,
            onTap: () async {
              await ref.read(settingsProvider.notifier).setBibleVersion(version.id);
              if (mounted) context.push('/books');
            },
          ).animate().fadeIn(delay: (400 + index * 80).ms).slideY(begin: 0.15);
        }),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withOpacity(0.12)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final BibleVersion version;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionCard({
    required this.version,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.08)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    version.abbreviation,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      version.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 22)
              else
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
