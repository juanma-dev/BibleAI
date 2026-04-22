import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/chat_provider.dart';

class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Chat header
          _ChatHeader(settings: settings, isDark: isDark, colorScheme: colorScheme),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(language: settings.language, colorScheme: colorScheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _MessageBubble(
                        message: msg,
                        language: settings.language,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1);
                    },
                  ),
          ),

          // Input bar
          _ChatInput(
            controller: _inputController,
            focusNode: _focusNode,
            language: settings.language,
            colorScheme: colorScheme,
            isDark: isDark,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends ConsumerWidget {
  final AppSettings settings;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ChatHeader({required this.settings, required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_rounded, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              settings.language == 'es' ? 'Asistente Bíblico AI' : 'AI Bible Assistant',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          // AI provider badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              settings.aiProvider.displayName,
              style: GoogleFonts.lato(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Clear chat
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
            tooltip: settings.language == 'es' ? 'Limpiar chat' : 'Clear chat',
          ),
          // Close chat
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => ref.read(chatVisibleProvider.notifier).state = false,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String language;
  final ColorScheme colorScheme;

  const _EmptyChat({required this.language, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final hints = language == 'es'
        ? [
            '¿Qué significa este versículo?',
            '¿Cuál es el contexto histórico de este libro?',
            '¿Qué dice la Biblia sobre el amor?',
            'Compara este versículo con otros similares',
          ]
        : [
            'What does this verse mean?',
            'What is the historical context of this book?',
            'What does the Bible say about love?',
            'Compare this verse with similar ones',
          ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 36, color: colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            language == 'es'
                ? 'Toca un versículo para preguntar\no escribe tu consulta'
                : 'Tap a verse to ask\nor type your question',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: hints.map((h) => _HintChip(text: h, colorScheme: colorScheme)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends ConsumerWidget {
  final String text;
  final ColorScheme colorScheme;

  const _HintChip({required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(chatProvider.notifier).sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 11,
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String language;
  final bool isDark;
  final ColorScheme colorScheme;

  const _MessageBubble({
    required this.message,
    required this.language,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, size: 14, color: colorScheme.primary),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.chatUserBubble
                        : isDark ? AppColors.chatAiBubbleDark : AppColors.chatAiBubbleLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                  ),
                  child: message.isLoading
                      ? _LoadingDots(color: colorScheme.primary)
                      : isUser
                          ? Text(
                              message.content,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            )
                          : MarkdownBody(
                              data: message.content,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.lora(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                ),
                                strong: GoogleFonts.lora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                code: GoogleFonts.robotoMono(
                                  fontSize: 12,
                                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                            ),
                ),
                // Action buttons for AI messages
                if (!isUser && !message.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniAction(
                          icon: Icons.copy_rounded,
                          onTap: () => Clipboard.setData(ClipboardData(text: message.content)),
                          colorScheme: colorScheme,
                        ),
                        _MiniAction(
                          icon: Icons.share_rounded,
                          onTap: () => Share.share(message.content),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _MiniAction({required this.icon, required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: colorScheme.primary),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  final Color color;

  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (offset < 0.5 ? offset * 2 : (1 - offset) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String language;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.language,
    required this.colorScheme,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: language == 'es'
                    ? 'Pregunta sobre la Biblia...'
                    : 'Ask about the Bible...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
