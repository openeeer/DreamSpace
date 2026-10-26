import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../data/providers.dart';
import '../../data/processing.dart';
import '../../models/dream.dart';

/// Mock dictation: records nothing, transcribes nothing. The button flow,
/// the night-safe surface, and the hand-off into the processing pipeline are
/// real; the audio → text step belongs to the future server.
class DictationScreen extends ConsumerStatefulWidget {
  const DictationScreen({super.key});
  @override
  ConsumerState<DictationScreen> createState() => _DictationScreenState();
}

enum _DictationPhase { idle, recording, sending }

class _DictationScreenState extends ConsumerState<DictationScreen> {
  _DictationPhase phase = _DictationPhase.idle;
  DateTime started = DateTime.now();
  Duration get elapsed => DateTime.now().difference(started);

  Future<void> toggle() async {
    final en = ref.read(englishProvider);
    if (phase == _DictationPhase.idle) {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        phase = _DictationPhase.recording;
        started = DateTime.now();
      });
      return;
    }
    if (phase == _DictationPhase.recording) {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.lightImpact();
      }
      setState(() => phase = _DictationPhase.sending);
      // Mock transcript: a rich sample text so the whole downstream pipeline
      // (stages, merge, character matching) is exercised end to end.
      final transcript = en
          ? 'I was in a glass staircase going down to the sea. The ocean had no end and a last train was leaving without me. Mom was there, waving from the platform, and the whole dream felt strange but calm, like it was a message.'
          : 'Я шёл по стеклянной лестнице, которая спускалась прямо к морю. Океан был без конца, и последний поезд уходил без меня. Мама стояла на перроне и махала рукой, и весь сон был странным, но спокойным, будто это было послание.';
      final now = DateTime.now();
      final dream = Dream(
        id: const Uuid().v4(),
        title: '',
        description: transcript,
        date: now,
        createdAt: now.toUtc(),
        updatedAt: now.toUtc(),
        source: DreamSource.dictated,
        status: ProcessingStatus.queued,
      );
      try {
        await ref.read(repositoryProvider).save(dream);
        if (!mounted) return;
        final processing = ref.read(processingServiceProvider);
        if (processing.enabled) {
          processing.process(dream);
          context.go('/processing/${dream.id}');
        } else {
          // Privacy off: saved locally, quietly, nothing "leaves" the device.
          context.go('/record?id=${dream.id}');
        }
      } catch (_) {
        if (mounted) {
          setState(() => phase = _DictationPhase.idle);
          await dreamNotice(
            context,
            tr(en, 'Не удалось сохранить', 'Could not save'),
            tr(
              en,
              'Запись не сохранилась. Попробуй ещё раз.',
              'The recording was not saved. Please try again.',
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider);
    final recording = phase == _DictationPhase.recording;
    final sending = phase == _DictationPhase.sending;
    // Night mode: dim the whole surface so a half-asleep dreamer is not
    // blinded. Deliberately below normal contrast; this screen is a torch,
    // not a reading surface.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xff05081a),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  onPressed: () => context.pop(),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: const Color(0xff8b86ad),
                    size: 22,
                    semanticLabel: tr(en, 'Закрыть', 'Close'),
                  ),
                ),
              ),
              const Spacer(),
              // Pulse ring around the record button while recording.
              Semantics(
                button: true,
                label: recording
                    ? tr(en, 'Остановить запись', 'Stop recording')
                    : tr(en, 'Начать запись', 'Start recording'),
                enabled: !sending,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: sending ? null : toggle,
                  child: _RecordOrb(
                    recording: recording,
                    elapsed: elapsed,
                    sending: sending,
                    en: en,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Rhythm.section)
                    .add(const EdgeInsets.only(bottom: Rhythm.xl)),
                child: Column(
                  children: [
                    Text(
                      sending
                          ? tr(en, 'Уходит на сервер…', 'Sending to server…')
                          : recording
                          ? tr(
                              en,
                              'Говори спокойно — я слышу тебя',
                              'Speak softly — I can hear you',
                            )
                          : tr(
                              en,
                              'Нажми и расскажи сон,\nкак только проснёшься',
                              'Tap and tell your dream\nas soon as you wake',
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xffa8a3c9),
                      ),
                    ),
                    if (!sending) ...[
                      const SizedBox(height: Rhythm.m),
                      Text(
                        tr(
                          en,
                          'Расшифровка появится в черновике — сможешь поправить',
                          'The transcript lands in a draft — you can edit it',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff6d688f),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordOrb extends StatelessWidget {
  const _RecordOrb({
    required this.recording,
    required this.elapsed,
    required this.sending,
    required this.en,
  });
  final bool recording, sending;
  final Duration elapsed;
  final bool en;

  String get _timeLabel {
    final m = elapsed.inMinutes, s = elapsed.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    height: 240,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (recording)
          const _PulsingHalo(color: Color(0xffc0acff))
        else
          Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x14120e2e), Color(0x0508081a)],
              ),
            ),
          ),
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording ? const Color(0xffc0acff) : const Color(0xff171c3c),
            border: Border.all(
              color: const Color(0xffc0acff).withValues(alpha: .5),
              width: 1,
            ),
            boxShadow: recording
                ? [
                    BoxShadow(
                      color: const Color(0xffc0acff).withValues(alpha: .35),
                      blurRadius: 40,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: sending
                ? const CupertinoActivityIndicator(color: Color(0xffc0acff))
                : recording
                ? Text(
                    _timeLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      letterSpacing: 1,
                      color: Color(0xff05081a),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Icon(
                    CupertinoIcons.mic_fill,
                    size: 40,
                    color: const Color(0xffc0acff),
                    semanticLabel: tr(en, 'Записать', 'Record'),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _PulsingHalo extends StatefulWidget {
  const _PulsingHalo({required this.color});
  final Color color;
  @override
  State<_PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<_PulsingHalo>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      return Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.color.withValues(alpha: .3)),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in const [.0, .5])
              Container(
                width: 108 + ((t + offset) % 1) * 130,
                height: 108 + ((t + offset) % 1) * 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(
                      alpha: .5 * (1 - ((t + offset) % 1)),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
