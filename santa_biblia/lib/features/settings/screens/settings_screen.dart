import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lang = settings.language;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(lang == 'es' ? 'Configuración' : 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme section
          _SectionHeader(title: lang == 'es' ? 'Apariencia' : 'Appearance', isDark: isDark, colorScheme: colorScheme),
          _ThemeSelector(settings: settings, lang: lang, colorScheme: colorScheme, theme: theme, isDark: isDark),
          const SizedBox(height: 24),

          // Font size
          _SectionHeader(title: lang == 'es' ? 'Texto' : 'Text', isDark: isDark, colorScheme: colorScheme),
          _FontSizeRow(settings: settings, lang: lang, colorScheme: colorScheme, theme: theme),
          const SizedBox(height: 24),

          // AI Provider
          _SectionHeader(title: lang == 'es' ? 'Asistente de IA' : 'AI Assistant', isDark: isDark, colorScheme: colorScheme),
          _AiProviderSection(settings: settings, lang: lang, colorScheme: colorScheme, theme: theme, isDark: isDark),
          const SizedBox(height: 24),

          // Backend URL
          _SectionHeader(title: lang == 'es' ? 'Conexión al Servidor' : 'Server Connection', isDark: isDark, colorScheme: colorScheme),
          _BackendUrlRow(settings: settings, lang: lang, colorScheme: colorScheme, theme: theme, isDark: isDark),
          const SizedBox(height: 32),

          // About
          _AboutSection(lang: lang, colorScheme: colorScheme, theme: theme),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final ColorScheme colorScheme;

  const _SectionHeader({required this.title, required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lato(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  final AppSettings settings;
  final String lang;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  const _ThemeSelector({
    required this.settings,
    required this.lang,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (ThemeModePreference.light, Icons.light_mode_outlined, lang == 'es' ? 'Claro' : 'Light'),
      (ThemeModePreference.dark, Icons.dark_mode_outlined, lang == 'es' ? 'Oscuro' : 'Dark'),
      (ThemeModePreference.system, Icons.brightness_auto_rounded, lang == 'es' ? 'Sistema' : 'System'),
    ];

    return Row(
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final (mode, icon, label) = entry.value;
        final selected = settings.themeMode == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => ref.read(settingsProvider.notifier).setThemeMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: selected ? colorScheme.primary.withOpacity(0.12) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? colorScheme.primary : colorScheme.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: selected ? colorScheme.primary : colorScheme.onSurface, size: 22),
                  const SizedBox(height: 6),
                  Text(label, style: GoogleFonts.lato(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? colorScheme.primary : colorScheme.onSurface)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FontSizeRow extends ConsumerWidget {
  final AppSettings settings;
  final String lang;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _FontSizeRow({required this.settings, required this.lang, required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(lang == 'es' ? 'Tamaño del texto' : 'Text size', style: theme.textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${settings.fontSize.round()}px', style: GoogleFonts.lato(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          Row(
            children: [
              Text('A', style: GoogleFonts.lora(fontSize: 14, color: colorScheme.onSurface)),
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
              Text('A', style: GoogleFonts.lora(fontSize: 24, color: colorScheme.onSurface)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              lang == 'es' ? 'Así se verá el texto de la Biblia' : 'This is how Bible text will look',
              style: GoogleFonts.lora(fontSize: settings.fontSize * 0.75, color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiProviderSection extends ConsumerStatefulWidget {
  final AppSettings settings;
  final String lang;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  const _AiProviderSection({
    required this.settings,
    required this.lang,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  @override
  ConsumerState<_AiProviderSection> createState() => _AiProviderSectionState();
}

class _AiProviderSectionState extends ConsumerState<_AiProviderSection> {
  bool _showApiKey = false;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = widget.settings.aiApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        // Provider grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
          ),
          itemCount: AiProvider.values.length,
          itemBuilder: (context, index) {
            final provider = AiProvider.values[index];
            final selected = settings.aiProvider == provider;
            return GestureDetector(
              onTap: () => ref.read(settingsProvider.notifier).setAiProvider(provider),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? widget.colorScheme.primary.withOpacity(0.12)
                      : (widget.isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? widget.colorScheme.primary : widget.colorScheme.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          provider.requiresApiKey ? Icons.vpn_key_rounded : Icons.open_in_browser_rounded,
                          size: 14,
                          color: selected ? widget.colorScheme.primary : widget.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider.displayName,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? widget.colorScheme.primary : widget.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      provider.requiresApiKey
                          ? (widget.lang == 'es' ? 'API Key' : 'API Key')
                          : (widget.lang == 'es' ? 'Gratis' : 'Free'),
                      style: GoogleFonts.lato(fontSize: 10, color: widget.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // API key field (shown only for paid providers)
        if (settings.aiProvider.requiresApiKey)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'es'
                      ? 'API Key de ${settings.aiProvider.displayName}'
                      : '${settings.aiProvider.displayName} API Key',
                  style: widget.theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_showApiKey,
                  decoration: InputDecoration(
                    hintText: 'sk-...',
                    suffixIcon: IconButton(
                      icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    ),
                  ),
                  onChanged: (v) => ref.read(settingsProvider.notifier).setAiApiKey(v),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lang == 'es'
                      ? '⚠️ La API key se envía a tu propio servidor backend, nunca directamente a la IA.'
                      : '⚠️ The API key is sent to your own backend server, never directly to the AI.',
                  style: GoogleFonts.lato(fontSize: 11, color: widget.colorScheme.outline),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.lang == 'es'
                        ? 'Este proveedor es gratuito y no requiere API key'
                        : 'This provider is free and requires no API key',
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BackendUrlRow extends ConsumerStatefulWidget {
  final AppSettings settings;
  final String lang;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  const _BackendUrlRow({
    required this.settings, required this.lang,
    required this.colorScheme, required this.theme, required this.isDark,
  });

  @override
  ConsumerState<_BackendUrlRow> createState() => _BackendUrlRowState();
}

class _BackendUrlRowState extends ConsumerState<_BackendUrlRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settings.backendUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lang == 'es' ? 'URL del servidor backend' : 'Backend server URL',
            style: widget.theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'http://192.168.1.100:5000',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            onChanged: (v) => ref.read(settingsProvider.notifier).setBackendUrl(v),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'es'
                ? 'Dirección de tu servidor C# .NET donde residen las API keys de IA.'
                : 'Address of your C# .NET server where AI API keys live.',
            style: GoogleFonts.lato(fontSize: 11, color: widget.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String lang;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AboutSection({required this.lang, required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, color: colorScheme.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            lang == 'es' ? 'La Santa Biblia Asistida por AI' : 'The Holy Bible Assisted by AI',
            style: GoogleFonts.cinzelDecorative(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            lang == 'es'
                ? 'Versiones de dominio público:\nReina-Valera 1909 · KJV · WEB · ASV'
                : 'Public domain versions:\nReina-Valera 1909 · KJV · WEB · ASV',
            style: GoogleFonts.lato(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
