// lib/levels/level_base.dart
// ─────────────────────────────────────────────────────────────────────────────
// Shared model, painter, and helpers used by every level screen.
// Each level file imports this and adds only its own shape + arrow data.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';

// ── Direction enum ────────────────────────────────────────────────────────────
enum ArrowDir { up, down, left, right }

// ── Arrow data model ──────────────────────────────────────────────────────────
class ArrowData {
  final int id;
  int row, col;
  final ArrowDir dir;
  final int length; // 1 = short, 2 = medium, 3 = long
  final Color color;
  bool solved;

  ArrowData({
    required this.id,
    required this.row,
    required this.col,
    required this.dir,
    required this.length,
    required this.color,
    this.solved = false,
  });

  /// All grid cells occupied by this arrow.
  List<(int, int)> get cells => List.generate(length, (i) {
        final r = row +
            (dir == ArrowDir.down
                ? i
                : dir == ArrowDir.up
                    ? -i
                    : 0);
        final c = col +
            (dir == ArrowDir.right
                ? i
                : dir == ArrowDir.left
                    ? -i
                    : 0);
        return (r, c);
      });
}

// ── Reusable level state mixin ────────────────────────────────────────────────
mixin LevelStateMixin<T extends StatefulWidget> on State<T> {
  late List<ArrowData> arrows;
  int nextSolveId = 0;
  int lives = 3;
  int secondsLeft = 60;
  bool gameOver = false;
  bool victory = false;
  Timer? _levelTimer;
  final Map<int, ValueNotifier<int>> animTrigger = {};

  final AudioService _audio = AudioService();

  int get levelNumber;
  int get rows;
  int get cols;
  List<ArrowData> Function() get buildArrowsFn;
  Widget Function() get nextLevelBuilder;

  void initLevelState() {
    arrows = buildArrowsFn();
    for (final a in arrows) {
      animTrigger[a.id] = ValueNotifier(0);
    }
    _audio.playGameMusic();
    _startTimer();
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    for (final v in animTrigger.values) {
      v.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        secondsLeft--;
        if (secondsLeft <= 0) triggerGameOver();
      });
    });
  }

  void triggerGameOver() {
    _levelTimer?.cancel();
    _audio.playLoseSound();
    setState(() => gameOver = true);
  }

  void triggerVictory() {
    _levelTimer?.cancel();
    _audio.playWinSound();
    setState(() => victory = true);
    if (mounted) {
      context.read<GameProvider>().recordLevelComplete(
            level: levelNumber,
            time: 60 - secondsLeft,
            lives: lives,
          );
    }
  }

  bool canSlide(ArrowData arrow) {
    final occupied = <(int, int)>{};
    for (final a in arrows) {
      if (a.id != arrow.id && !a.solved) {
        for (final cell in a.cells) {
          occupied.add(cell);
        }
      }
    }
    final dr = arrow.dir == ArrowDir.down
        ? 1
        : arrow.dir == ArrowDir.up
            ? -1
            : 0;
    final dc = arrow.dir == ArrowDir.right
        ? 1
        : arrow.dir == ArrowDir.left
            ? -1
            : 0;
    var r = arrow.row + dr * arrow.length;
    var c = arrow.col + dc * arrow.length;
    // Walk the escape path; any occupied cell blocks the arrow
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      if (occupied.contains((r, c))) return false;
      r += dr;
      c += dc;
    }
    return true;
  }

  void onTap(ArrowData arrow) {
    if (gameOver || victory || arrow.solved) return;
    if (arrow.id != nextSolveId || !canSlide(arrow)) {
      wrongTap();
      return;
    }
    _audio.playArrowSound();
    animTrigger[arrow.id]!.value++;
    Future.delayed(350.ms, () {
      if (!mounted) return;
      setState(() {
        arrow.solved = true;
        nextSolveId++;
        if (nextSolveId >= arrows.length) triggerVictory();
      });
    });
  }

  void wrongTap() {
    _audio.playLoseSound();
    setState(() {
      lives--;
      if (lives <= 0) triggerGameOver();
    });
  }

  void restart() {
    _levelTimer?.cancel();
    setState(() {
      arrows = buildArrowsFn();
      nextSolveId = 0;
      lives = 3;
      secondsLeft = 60;
      gameOver = false;
      victory = false;
      for (final a in arrows) {
        animTrigger[a.id]?.value = 0;
      }
    });
    _audio.playGameMusic();
    _startTimer();
  }

  void quit() {
    _levelTimer?.cancel();
    _audio.resumeMenuMusic();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void goNextLevel() {
    _levelTimer?.cancel();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => nextLevelBuilder()));
  }

  // ── Build helpers ───────────────────────────────────────────────────────────

  Widget buildHUD() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
              children: List.generate(
                  3,
                  (i) => Icon(
                      i < lives ? Icons.favorite : Icons.favorite_border,
                      color: i < lives ? Colors.redAccent : Colors.grey,
                      size: 26))),
          Row(children: [
            Icon(Icons.timer,
                color: secondsLeft <= 10 ? Colors.redAccent : Colors.cyan,
                size: 20),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                  color: secondsLeft <= 10 ? Colors.redAccent : Colors.white,
                  fontSize: secondsLeft <= 10 ? 26 : 22,
                  fontWeight: FontWeight.bold),
              child: Text('${secondsLeft}s'),
            ),
          ]),
        ]),
      );

  Widget buildGrid(double cellSize, Set<(int, int)> shapeCells) {
    return Center(
        child: SizedBox(
            width: cellSize * cols,
            height: cellSize * rows,
            child: Stack(children: [
              // Shape background cells
              for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                  Positioned(
                      left: c * cellSize,
                      top: r * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: Container(
                          decoration: BoxDecoration(
                        color: shapeCells.contains((r, c))
                            ? AppColors.darkNavy.withValues(alpha: 0.6)
                            : Colors.transparent,
                        border: shapeCells.contains((r, c))
                            ? Border.all(color: Colors.white12, width: 0.5)
                            : null,
                      ))),
              // Arrows
              for (final a in arrows)
                if (!a.solved) buildArrow(a, cellSize),
            ])));
  }

  Widget buildArrow(ArrowData arrow, double cellSize) {
    final isHoriz = arrow.dir == ArrowDir.left || arrow.dir == ArrowDir.right;
    final w = isHoriz ? cellSize * arrow.length : cellSize;
    final h = isHoriz ? cellSize : cellSize * arrow.length;
    double left = arrow.col * cellSize;
    double top = arrow.row * cellSize;
    if (arrow.dir == ArrowDir.up) top -= (arrow.length - 1) * cellSize;
    if (arrow.dir == ArrowDir.left) left -= (arrow.length - 1) * cellSize;
    final so = switch (arrow.dir) {
      ArrowDir.right => const Offset(1.5, 0),
      ArrowDir.left => const Offset(-1.5, 0),
      ArrowDir.up => const Offset(0, -1.5),
      ArrowDir.down => const Offset(0, 1.5),
    };
    return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: ValueListenableBuilder<int>(
          valueListenable: animTrigger[arrow.id]!,
          builder: (_, trigger, child) => GestureDetector(
              onTap: () => onTap(arrow),
              child: trigger == 0
                  ? child!
                  : child!
                      .animate(key: ValueKey(trigger))
                      .slideX(
                          begin: 0,
                          end: isHoriz ? so.dx : 0,
                          duration: 300.ms,
                          curve: Curves.easeIn)
                      .slideY(
                          begin: 0,
                          end: !isHoriz ? so.dy : 0,
                          duration: 300.ms,
                          curve: Curves.easeIn)
                      .fadeOut(
                          begin: 1, duration: 300.ms, curve: Curves.easeIn)),
          child: ArrowWidget(
              dir: arrow.dir,
              length: arrow.length,
              color: arrow.color,
              cellSize: cellSize),
        ));
  }
}

// ── Arrow Widget + Painter ────────────────────────────────────────────────────

class ArrowWidget extends StatelessWidget {
  final ArrowDir dir;
  final int length;
  final Color color;
  final double cellSize;
  const ArrowWidget(
      {super.key,
      required this.dir,
      required this.length,
      required this.color,
      required this.cellSize});

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: ArrowPainter(
          dir: dir, length: length, color: color, cellSize: cellSize));
}

class ArrowPainter extends CustomPainter {
  final ArrowDir dir;
  final int length;
  final Color color;
  final double cellSize;

  const ArrowPainter(
      {required this.dir,
      required this.length,
      required this.color,
      required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final pad = cellSize * 0.15;
    final shaft = cellSize * 0.22;
    final head = cellSize * 0.36;
    final path = _buildPath(size, pad, shaft, head);
    canvas.drawPath(
        path.shift(const Offset(2, 2)), Paint()..color = Colors.black38);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  Path _buildPath(Size s, double pad, double shaft, double head) {
    final path = Path();
    final isHoriz = dir == ArrowDir.left || dir == ArrowDir.right;
    if (isHoriz) {
      final midY = s.height / 2;
      final flip = dir == ArrowDir.left;
      final start = flip ? s.width - pad : pad;
      final end = flip ? pad : s.width - pad;
      final headEnd = flip ? head + pad : s.width - head - pad;
      path.moveTo(start, midY - shaft);
      path.lineTo(headEnd, midY - shaft);
      path.lineTo(headEnd, midY - head);
      path.lineTo(end, midY);
      path.lineTo(headEnd, midY + head);
      path.lineTo(headEnd, midY + shaft);
      path.lineTo(start, midY + shaft);
    } else {
      final midX = s.width / 2;
      final flip = dir == ArrowDir.up;
      final start = flip ? s.height - pad : pad;
      final end = flip ? pad : s.height - pad;
      final headEnd = flip ? head + pad : s.height - head - pad;
      path.moveTo(midX - shaft, start);
      path.lineTo(midX - shaft, headEnd);
      path.lineTo(midX - head, headEnd);
      path.lineTo(midX, end);
      path.lineTo(midX + head, headEnd);
      path.lineTo(midX + shaft, headEnd);
      path.lineTo(midX + shaft, start);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
