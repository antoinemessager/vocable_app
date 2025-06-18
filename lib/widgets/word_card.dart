import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_pair.dart';
import '../utils/style_utils.dart';
import 'too_easy_dialog.dart';

class WordCard extends StatefulWidget {
  final WordPair word;
  final Function(bool) onAnswer;
  final VoidCallback onTooEasy;
  final VoidCallback? onShowTranslation;

  const WordCard({
    super.key,
    required this.word,
    required this.onAnswer,
    required this.onTooEasy,
    this.onShowTranslation,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _isRevealed = false;

  void _toggleReveal() {
    setState(() {
      _isRevealed = true;
    });
  }

  Future<void> _handleTooEasy() async {
    final prefs = await SharedPreferences.getInstance();
    final hideDialog = prefs.getBool('hide_too_easy_dialog') ?? false;

    if (!hideDialog) {
      final shouldMarkTooEasy = await TooEasyDialog.show(
        context,
        onTooEasy: widget.onTooEasy,
        isVerb: false,
      );
      if (shouldMarkTooEasy != true) {
        return;
      }
    } else {
      widget.onTooEasy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.word.word_fr,
          style: StyleUtils.getAdaptiveTextStyle(
            context,
            baseSize: StyleUtils.headlineMedium,
            baseLineHeight: StyleUtils.lineHeightNormal,
            fontWeight: FontWeight.w600,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 2,
        );
        textPainter.layout(maxWidth: constraints.maxWidth - 80);

        final singleLineTextSpan = TextSpan(
          text: 'Test',
          style: StyleUtils.getAdaptiveTextStyle(
            context,
            baseSize: StyleUtils.headlineMedium,
            baseLineHeight: StyleUtils.lineHeightNormal,
            fontWeight: FontWeight.w600,
          ),
        );
        final singleLinePainter = TextPainter(
          text: singleLineTextSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        singleLinePainter.layout(maxWidth: constraints.maxWidth - 32);
        final singleLineHeight = singleLinePainter.height;

        final needsTwoLines = textPainter.height > singleLineHeight * 1.2;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: needsTwoLines ? 70 : 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        child: Text(
                          widget.word.word_fr,
                          style: StyleUtils.getAdaptiveTextStyle(
                            context,
                            baseSize: StyleUtils.headlineMedium,
                            baseLineHeight: StyleUtils.lineHeightNormal,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                if (!_isRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _toggleReveal();
                        widget.onShowTranslation?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Afficher la traduction',
                        style: StyleUtils.getAdaptiveTextStyle(
                          context,
                          baseSize: StyleUtils.bodyMedium,
                          baseLineHeight: StyleUtils.lineHeightNormal,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  Text(
                    widget.word.word_es,
                    style: StyleUtils.getAdaptiveTextStyle(
                      context,
                      baseSize: StyleUtils.headlineMedium,
                      baseLineHeight: StyleUtils.lineHeightNormal,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (widget.word.es_sentence.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: Colors.blue.shade300,
                            width: 5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '" ',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(text: widget.word.es_sentence),
                                      const TextSpan(
                                        text: '"',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.word.fr_sentence.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                widget.word.fr_sentence,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  IntrinsicHeight(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: FilledButton(
                                  onPressed: () => widget.onAnswer(false),
                                  style: FilledButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: Colors.red[50],
                                    foregroundColor: Colors.red[700],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.close,
                                          size: constraints.maxWidth < 350
                                              ? 16
                                              : 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Je me suis trompé',
                                        style: TextStyle(
                                            fontSize: constraints.maxWidth < 350
                                                ? 11
                                                : 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: FilledButton(
                                  onPressed: () => widget.onAnswer(true),
                                  style: FilledButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: Colors.green[50],
                                    foregroundColor: Colors.green[700],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check,
                                          size: constraints.maxWidth < 350
                                              ? 16
                                              : 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Je savais',
                                        style: TextStyle(
                                            fontSize: constraints.maxWidth < 350
                                                ? 11
                                                : 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.word.nb_time_seen == 1)
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: FilledButton(
                                    onPressed: _handleTooEasy,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      backgroundColor: Colors.grey[100],
                                      foregroundColor: Colors.grey[700],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.double_arrow,
                                            size: constraints.maxWidth < 350
                                                ? 16
                                                : 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Trop facile (ne plus réviser)',
                                          style: TextStyle(
                                              fontSize:
                                                  constraints.maxWidth < 350
                                                      ? 11
                                                      : 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
