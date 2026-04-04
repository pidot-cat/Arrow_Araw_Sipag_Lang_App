// lib/levels/game_screen_lvl_5.dart
// Level 5 — 9×9 Grid — Pentagon Shape
// ─────────────────────────────────────────────────────────────────────────────
// Pentagon (flat top, 5 sides) approximated in 9×9:
//
//   . . . X X X . . .   row 0
//   . . X X X X X . .   row 1
//   . X X X X X X X .   row 2
//   X X X X X X X X X   row 3
//   X X X X X X X X X   row 4
//   X X X X X X X X X   row 5
//   . X X X X X X X .   row 6
//   . . X X X X X . .   row 7
//   . . . X X X . . .   row 8   ← bottom tip
//
// ─────────────────────────────────────────────────────────────────────────────
import 'game_screen_lvl_6.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/victory_overlay.dart';

enum ArrowDir { up, down, left, right }

class ArrowData {
  final int id;
  int row, col;
  final ArrowDir dir;
  final int length;
  final Color color;
  bool solved;
  ArrowData(
      {required this.id,
      required this.row,
      required this.col,
      required this.dir,
      required this.length,
      required this.color,
      this.solved = false});
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

const int _rows = 9, _cols = 9;

const Set<(int, int)> _shapeCells = {
  (0, 3),
  (0, 4),
  (0, 5),
  (1, 2),
  (1, 3),
  (1, 4),
  (1, 5),
  (1, 6),
  (2, 1),
  (2, 2),
  (2, 3),
  (2, 4),
  (2, 5),
  (2, 6),
  (2, 7),
  (3, 0),
  (3, 1),
  (3, 2),
  (3, 3),
  (3, 4),
  (3, 5),
  (3, 6),
  (3, 7),
  (3, 8),
  (4, 0),
  (4, 1),
  (4, 2),
  (4, 3),
  (4, 4),
  (4, 5),
  (4, 6),
  (4, 7),
  (4, 8),
  (5, 0),
  (5, 1),
  (5, 2),
  (5, 3),
  (5, 4),
  (5, 5),
  (5, 6),
  (5, 7),
  (5, 8),
  (6, 1),
  (6, 2),
  (6, 3),
  (6, 4),
  (6, 5),
  (6, 6),
  (6, 7),
  (7, 2),
  (7, 3),
  (7, 4),
  (7, 5),
  (7, 6),
  (8, 3),
  (8, 4),
  (8, 5),
};

List<ArrowData> _buildArrows() => [
      // Top cluster
      ArrowData(
          id: 0,
          row: 0,
          col: 3,
          dir: ArrowDir.up,
          length: 1,
          color: AppColors.arrowRed),
      ArrowData(
          id: 1,
          row: 0,
          col: 4,
          dir: ArrowDir.up,
          length: 1,
          color: AppColors.arrowOrange),
      ArrowData(
          id: 2,
          row: 0,
          col: 5,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowYellow),
      // Row 1
      ArrowData(
          id: 3,
          row: 1,
          col: 2,
          dir: ArrowDir.left,
          length: 2,
          color: AppColors.arrowGreen),
      ArrowData(
          id: 4,
          row: 1,
          col: 4,
          dir: ArrowDir.up,
          length: 2,
          color: AppColors.arrowCyan),
      ArrowData(
          id: 5,
          row: 1,
          col: 6,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowBlue),
      // Row 2
      ArrowData(
          id: 6,
          row: 2,
          col: 1,
          dir: ArrowDir.left,
          length: 1,
          color: AppColors.arrowPurple),
      ArrowData(
          id: 7,
          row: 2,
          col: 2,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowPink),
      ArrowData(
          id: 8,
          row: 2,
          col: 5,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowWhite),
      ArrowData(
          id: 9,
          row: 2,
          col: 7,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowRed),
      // Row 3
      ArrowData(
          id: 10,
          row: 3,
          col: 0,
          dir: ArrowDir.left,
          length: 1,
          color: AppColors.arrowOrange),
      ArrowData(
          id: 11,
          row: 3,
          col: 1,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowYellow),
      ArrowData(
          id: 12,
          row: 3,
          col: 4,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowGreen),
      ArrowData(
          id: 13,
          row: 3,
          col: 6,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowCyan),
      // Row 4
      ArrowData(
          id: 14,
          row: 4,
          col: 0,
          dir: ArrowDir.left,
          length: 1,
          color: AppColors.arrowBlue),
      ArrowData(
          id: 15,
          row: 4,
          col: 1,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowPurple),
      ArrowData(
          id: 16,
          row: 4,
          col: 3,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowPink),
      ArrowData(
          id: 17,
          row: 4,
          col: 6,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowWhite),
      ArrowData(
          id: 18,
          row: 4,
          col: 8,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowRed),
      // Row 5
      ArrowData(
          id: 19,
          row: 5,
          col: 0,
          dir: ArrowDir.left,
          length: 1,
          color: AppColors.arrowOrange),
      ArrowData(
          id: 20,
          row: 5,
          col: 1,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowYellow),
      ArrowData(
          id: 21,
          row: 5,
          col: 4,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowGreen),
      ArrowData(
          id: 22,
          row: 5,
          col: 7,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowCyan),
      // Row 6
      ArrowData(
          id: 23,
          row: 6,
          col: 1,
          dir: ArrowDir.left,
          length: 1,
          color: AppColors.arrowBlue),
      ArrowData(
          id: 24,
          row: 6,
          col: 2,
          dir: ArrowDir.right,
          length: 3,
          color: AppColors.arrowPurple),
      ArrowData(
          id: 25,
          row: 6,
          col: 5,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowPink),
      ArrowData(
          id: 26,
          row: 6,
          col: 7,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowWhite),
      // Row 7
      ArrowData(
          id: 27,
          row: 7,
          col: 2,
          dir: ArrowDir.down,
          length: 2,
          color: AppColors.arrowRed),
      ArrowData(
          id: 28,
          row: 7,
          col: 4,
          dir: ArrowDir.down,
          length: 1,
          color: AppColors.arrowOrange),
      ArrowData(
          id: 29,
          row: 7,
          col: 5,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowYellow),
      // Row 8
      ArrowData(
          id: 30,
          row: 8,
          col: 3,
          dir: ArrowDir.down,
          length: 1,
          color: AppColors.arrowGreen),
      ArrowData(
          id: 31,
          row: 8,
          col: 4,
          dir: ArrowDir.down,
          length: 1,
          color: AppColors.arrowCyan),
      ArrowData(
          id: 32,
          row: 8,
          col: 5,
          dir: ArrowDir.down,
          length: 1,
          color: AppColors.arrowBlue),
    ];

class GameScreenLvl5 extends StatefulWidget {
  const GameScreenLvl5({super.key});
  @override
  State<GameScreenLvl5> createState() => _GameScreenLvl5State();
}

class _GameScreenLvl5State extends State<GameScreenLvl5> {
  late List<ArrowData> _arrows;
  int _nextSolveId = 0, _lives = 3, _secondsLeft = 60;
  bool _gameOver = false, _victory = false;
  Timer? _timer;
  final Map<int, ValueNotifier<int>> _animTrigger = {};

  @override
  void initState() {
    super.initState();
    _arrows = _buildArrows();
    for (final a in _arrows) { _animTrigger[a.id] = ValueNotifier(0); }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) _triggerGameOver();
      });
    });
  }

  void _triggerGameOver() {
    _timer?.cancel();
    setState(() => _gameOver = true);
  }

  void _triggerVictory() {
    _timer?.cancel();
    setState(() => _victory = true);
    context
        .read<GameProvider>()
        .recordLevelComplete(level: 5, time: 60 - _secondsLeft, lives: _lives);
  }

  bool _canSlide(ArrowData arrow) {
    final occupied = <(int, int)>{};
    for (final a in _arrows) {
      if (a.id != arrow.id && !a.solved) {
        for (final cell in a.cells) { occupied.add(cell); }
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
    var r = arrow.row + dr * arrow.length, c = arrow.col + dc * arrow.length;
    while (r >= 0 && r < _rows && c >= 0 && c < _cols) {
      if (occupied.contains((r, c))) return false;
      r += dr;
      c += dc;
    }
    return true;
  }

  void _onTap(ArrowData arrow) {
    if (_gameOver || _victory || arrow.solved) return;
    if (arrow.id != _nextSolveId || !_canSlide(arrow)) {
      _wrongTap();
      return;
    }
    _animTrigger[arrow.id]!.value++;
    Future.delayed(350.ms, () {
      if (!mounted) return;
      setState(() {
        arrow.solved = true;
        _nextSolveId++;
        if (_nextSolveId >= _arrows.length) _triggerVictory();
      });
    });
  }

  void _wrongTap() {
    context.read<GameProvider>().playErrorSound();
    setState(() {
      _lives--;
      if (_lives <= 0) _triggerGameOver();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = (MediaQuery.of(context).size.width * 0.9) / _cols;
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Stack(children: [
        SafeArea(
            child: Column(children: [
          _buildHUD(),
          const SizedBox(height: 16),
          _buildGrid(cellSize)
        ])),
        if (_gameOver) GameOverOverlay(onRetry: _restart, onBack: _quit),
        if (_victory) VictoryOverlay(onNext: _nextLevel, onBack: _quit),
      ]),
    );
  }

  Widget _buildHUD() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
              children: List.generate(
                  3,
                  (i) => Icon(
                      i < _lives ? Icons.favorite : Icons.favorite_border,
                      color: i < _lives ? Colors.redAccent : Colors.grey,
                      size: 26))),
          Text('${_secondsLeft}s',
              style: TextStyle(
                  color: _secondsLeft <= 10 ? Colors.redAccent : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _buildGrid(double cellSize) => Center(
      child: SizedBox(
          width: cellSize * _cols,
          height: cellSize * _rows,
          child: Stack(children: [
            for (int r = 0; r < _rows; r++)
              for (int c = 0; c < _cols; c++)
                Positioned(
                    left: c * cellSize,
                    top: r * cellSize,
                    width: cellSize,
                    height: cellSize,
                    child: Container(
                        decoration: BoxDecoration(
                      color: _shapeCells.contains((r, c))
                          ? AppColors.darkNavy.withValues(alpha: 0.6)
                          : Colors.transparent,
                      border: _shapeCells.contains((r, c))
                          ? Border.all(color: Colors.white12, width: 0.5)
                          : null,
                    ))),
            for (final a in _arrows)
              if (!a.solved) _buildArrow(a, cellSize),
          ])));

  Widget _buildArrow(ArrowData arrow, double cellSize) {
    final isHoriz = arrow.dir == ArrowDir.left || arrow.dir == ArrowDir.right;
    final w = isHoriz ? cellSize * arrow.length : cellSize;
    final h = isHoriz ? cellSize : cellSize * arrow.length;
    double left = arrow.col * cellSize, top = arrow.row * cellSize;
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
          valueListenable: _animTrigger[arrow.id]!,
          builder: (_, trigger, child) => GestureDetector(
              onTap: () => _onTap(arrow),
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
                      .fadeOut(begin: 1, duration: 300.ms)),
          child: _ArrowWidget(
              dir: arrow.dir,
              length: arrow.length,
              color: arrow.color,
              cellSize: cellSize),
        ));
  }

  void _restart() => setState(() {
        _arrows = _buildArrows();
        _nextSolveId = 0;
        _lives = 3;
        _secondsLeft = 60;
        _gameOver = false;
        _victory = false;
        for (final a in _arrows) { _animTrigger[a.id]?.value = 0; }
        _timer?.cancel();
        _startTimer();
      });

  void _quit() => Navigator.of(context).popUntil((r) => r.isFirst);
  void _nextLevel() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GameScreenLvl6()));
}

class _ArrowWidget extends StatelessWidget {
  final ArrowDir dir;
  final int length;
  final Color color;
  final double cellSize;
  const _ArrowWidget(
      {required this.dir,
      required this.length,
      required this.color,
      required this.cellSize});
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _ArrowPainter(
          dir: dir, length: length, color: color, cellSize: cellSize));
}

class _ArrowPainter extends CustomPainter {
  final ArrowDir dir;
  final int length;
  final Color color;
  final double cellSize;
  const _ArrowPainter(
      {required this.dir,
      required this.length,
      required this.color,
      required this.cellSize});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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
    canvas.drawPath(path, paint);
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
      final he = flip ? head + pad : s.width - head - pad;
      path.moveTo(start, midY - shaft);
      path.lineTo(he, midY - shaft);
      path.lineTo(he, midY - head);
      path.lineTo(end, midY);
      path.lineTo(he, midY + head);
      path.lineTo(he, midY + shaft);
      path.lineTo(start, midY + shaft);
    } else {
      final midX = s.width / 2;
      final flip = dir == ArrowDir.up;
      final start = flip ? s.height - pad : pad;
      final end = flip ? pad : s.height - pad;
      final he = flip ? head + pad : s.height - head - pad;
      path.moveTo(midX - shaft, start);
      path.lineTo(midX - shaft, he);
      path.lineTo(midX - head, he);
      path.lineTo(midX, end);
      path.lineTo(midX + head, he);
      path.lineTo(midX + shaft, he);
      path.lineTo(midX + shaft, start);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
