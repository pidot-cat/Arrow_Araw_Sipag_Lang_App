// lib/levels/game_screen_lvl_1.dart
// Level 1 — 5×5 Grid — Heart Shape
// ─────────────────────────────────────────────────────────────────────────────
// Heart mask (row, col) — 0-indexed, 5 columns wide, 5 rows tall
//
//   . X X . .
//   X X X X .
//   X X X X X
//   . X X X .
//   . . X . .
//
// Arrows: short (1 cell), medium (2 cells), long (3 cells).
// Correct solve order: arrows must be slid out in sequence 0→N so that each
// arrow's path is clear when it's its turn.
// ─────────────────────────────────────────────────────────────────────────────

import 'game_screen_lvl_2.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/victory_overlay.dart';

// ── Model ────────────────────────────────────────────────────────────────────

enum ArrowDir { up, down, left, right }

class ArrowData {
  final int id;
  int row; // top-left cell row
  int col; // top-left cell col
  final ArrowDir dir;
  final int length; // 1, 2 or 3 cells
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

  /// All cells occupied by this arrow.
  List<(int, int)> get cells {
    return List.generate(length, (i) {
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
}

// ── Level definition ─────────────────────────────────────────────────────────

const int _rows = 5;
const int _cols = 5;

/// Heart-shaped active cells (row, col).
const Set<(int, int)> _heartCells = {
  (0, 1),
  (0, 2),
  (1, 0),
  (1, 1),
  (1, 2),
  (1, 3),
  (2, 0),
  (2, 1),
  (2, 2),
  (2, 3),
  (2, 4),
  (3, 1),
  (3, 2),
  (3, 3),
  (4, 2),
};

/// Initial arrow layout — solve order: id 0 first, id N last.
List<ArrowData> _buildArrows() => [
      // id 0 — slide right out (short)
      ArrowData(
          id: 0,
          row: 0,
          col: 1,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowRed),
      // id 1 — slide up out (short)
      ArrowData(
          id: 1,
          row: 0,
          col: 2,
          dir: ArrowDir.up,
          length: 1,
          color: AppColors.arrowOrange),
      // id 2 — slide left out (medium)
      ArrowData(
          id: 2,
          row: 1,
          col: 0,
          dir: ArrowDir.left,
          length: 2,
          color: AppColors.arrowYellow),
      // id 3 — slide right out (medium)
      ArrowData(
          id: 3,
          row: 1,
          col: 2,
          dir: ArrowDir.right,
          length: 2,
          color: AppColors.arrowGreen),
      // id 4 — slide down out (long)
      ArrowData(
          id: 4,
          row: 2,
          col: 0,
          dir: ArrowDir.down,
          length: 3,
          color: AppColors.arrowCyan),
      // id 5 — slide right out (short)
      ArrowData(
          id: 5,
          row: 2,
          col: 4,
          dir: ArrowDir.right,
          length: 1,
          color: AppColors.arrowBlue),
      // id 6 — slide left out (medium)
      ArrowData(
          id: 6,
          row: 3,
          col: 1,
          dir: ArrowDir.left,
          length: 2,
          color: AppColors.arrowPurple),
      // id 7 — slide down out (short)
      ArrowData(
          id: 7,
          row: 3,
          col: 3,
          dir: ArrowDir.down,
          length: 1,
          color: AppColors.arrowPink),
      // id 8 — slide down out (short) — tip of heart
      ArrowData(
          id: 8,
          row: 4,
          col: 2,
          dir: ArrowDir.down,
          length: 1,
          color: AppColors.arrowWhite),
    ];

// ── Screen ───────────────────────────────────────────────────────────────────

class GameScreenLvl1 extends StatefulWidget {
  const GameScreenLvl1({super.key});

  @override
  State<GameScreenLvl1> createState() => _GameScreenLvl1State();
}

class _GameScreenLvl1State extends State<GameScreenLvl1> {
  late List<ArrowData> _arrows;
  int _nextSolveId = 0;
  int _lives = 3;
  int _secondsLeft = 60;
  bool _gameOver = false;
  bool _victory = false;
  Timer? _timer;

  // Per-arrow animation trigger keys
  final Map<int, ValueNotifier<int>> _animTrigger = {};

  @override
  void initState() {
    super.initState();
    _arrows = _buildArrows();
    for (final a in _arrows) {
      _animTrigger[a.id] = ValueNotifier(0);
    }
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
        .recordLevelComplete(level: 1, time: 60 - _secondsLeft, lives: _lives);
  }

  // ── Tap logic ──────────────────────────────────────────────────────────────

  bool _isCellInHeart(int r, int c) => _heartCells.contains((r, c));

  /// Returns true if the arrow can slide out (entire exit path is clear).
  bool _canSlide(ArrowData arrow) {
    final occupied = <(int, int)>{};
    for (final a in _arrows) {
      if (a.id != arrow.id && !a.solved) {
        for (final cell in a.cells) {
          occupied.add(cell);
        }
      }
    }

    // Determine direction vector
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

    // Check cells ahead until out of grid
    var r = arrow.row + dr * arrow.length;
    var c = arrow.col + dc * arrow.length;
    // We need at least one step out of the grid OR all steps must be free
    while (r >= 0 && r < _rows && c >= 0 && c < _cols) {
      if (occupied.contains((r, c))) return false;
      r += dr;
      c += dc;
    }
    return true;
  }

  void _onTap(ArrowData arrow) {
    if (_gameOver || _victory) return;
    if (arrow.solved) return;

    // Must tap in correct sequence
    if (arrow.id != _nextSolveId) {
      _wrongTap();
      return;
    }

    if (!_canSlide(arrow)) {
      _wrongTap();
      return;
    }

    // Correct tap — animate and mark solved
    _animTrigger[arrow.id]!.value++;
    Future.delayed(const Duration(milliseconds: 350), () {
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cellSize = (size.width * 0.9) / _cols;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHUD(),
                const SizedBox(height: 16),
                _buildGrid(cellSize),
              ],
            ),
          ),
          if (_gameOver) GameOverOverlay(onRetry: _restart, onBack: _quit),
          if (_victory) VictoryOverlay(onNext: _nextLevel, onBack: _quit),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lives
          Row(
            children: List.generate(
              3,
              (i) => Icon(
                i < _lives ? Icons.favorite : Icons.favorite_border,
                color: i < _lives ? Colors.redAccent : Colors.grey,
                size: 26,
              ),
            ),
          ),
          // Timer
          Text(
            '${_secondsLeft}s',
            style: TextStyle(
              color: _secondsLeft <= 10 ? Colors.redAccent : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(double cellSize) {
    return Center(
      child: SizedBox(
        width: cellSize * _cols,
        height: cellSize * _rows,
        child: Stack(
          children: [
            // Grid background cells
            for (int r = 0; r < _rows; r++)
              for (int c = 0; c < _cols; c++)
                Positioned(
                  left: c * cellSize,
                  top: r * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isCellInHeart(r, c)
                          ? AppColors.darkNavy.withValues(alpha: 0.6)
                          : Colors.transparent,
                      border: _isCellInHeart(r, c)
                          ? Border.all(color: Colors.white12, width: 0.5)
                          : null,
                    ),
                  ),
                ),
            // Arrows
            for (final arrow in _arrows)
              if (!arrow.solved) _buildArrow(arrow, cellSize),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow(ArrowData arrow, double cellSize) {
    final isHoriz = arrow.dir == ArrowDir.left || arrow.dir == ArrowDir.right;
    final w = isHoriz ? cellSize * arrow.length : cellSize;
    final h = isHoriz ? cellSize : cellSize * arrow.length;

    // Top-left position of the arrow bounding box
    double left = arrow.col * cellSize;
    double top = arrow.row * cellSize;
    if (arrow.dir == ArrowDir.up) top -= (arrow.length - 1) * cellSize;
    if (arrow.dir == ArrowDir.left) left -= (arrow.length - 1) * cellSize;

    // Slide offset direction for animation
    final slideOffset = switch (arrow.dir) {
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
        builder: (_, trigger, child) {
          return GestureDetector(
            onTap: () => _onTap(arrow),
            child: trigger == 0
                ? child!
                : child!
                    .animate(key: ValueKey(trigger))
                    .slideX(
                      begin: 0,
                      end: isHoriz ? slideOffset.dx : 0,
                      duration: 300.ms,
                      curve: Curves.easeIn,
                    )
                    .slideY(
                      begin: 0,
                      end: !isHoriz ? slideOffset.dy : 0,
                      duration: 300.ms,
                      curve: Curves.easeIn,
                    )
                    .fadeOut(begin: 1, duration: 300.ms, curve: Curves.easeIn),
          );
        },
        child: _ArrowPainter(
          dir: arrow.dir,
          length: arrow.length,
          color: arrow.color,
          cellSize: cellSize,
        ),
      ),
    );
  }

  void _restart() => setState(() {
        _arrows = _buildArrows();
        _nextSolveId = 0;
        _lives = 3;
        _secondsLeft = 60;
        _gameOver = false;
        _victory = false;
        for (final a in _arrows) {
          _animTrigger[a.id]?.value = 0;
        }
        _timer?.cancel();
        _startTimer();
      });

  void _quit() => Navigator.of(context).popUntil((r) => r.isFirst);

  void _nextLevel() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GameScreenLvl2()));
  }
}

// ── Arrow Painter widget ──────────────────────────────────────────────────────

class _ArrowPainter extends StatelessWidget {
  final ArrowDir dir;
  final int length;
  final Color color;
  final double cellSize;

  const _ArrowPainter({
    required this.dir,
    required this.length,
    required this.color,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArrowCustomPainter(
          dir: dir, length: length, color: color, cellSize: cellSize),
    );
  }
}

class _ArrowCustomPainter extends CustomPainter {
  final ArrowDir dir;
  final int length;
  final Color color;
  final double cellSize;

  const _ArrowCustomPainter({
    required this.dir,
    required this.length,
    required this.color,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pad = cellSize * 0.15;
    final shaft = cellSize * 0.22;
    final head = cellSize * 0.36;

    Path path;

    switch (dir) {
      case ArrowDir.right:
        path = _buildHorizontalArrow(size, pad, shaft, head, flipped: false);
      case ArrowDir.left:
        path = _buildHorizontalArrow(size, pad, shaft, head, flipped: true);
      case ArrowDir.down:
        path = _buildVerticalArrow(size, pad, shaft, head, flipped: false);
      case ArrowDir.up:
        path = _buildVerticalArrow(size, pad, shaft, head, flipped: true);
    }

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(2, 2)),
      Paint()..color = Colors.black38,
    );
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  Path _buildHorizontalArrow(Size size, double pad, double shaft, double head,
      {required bool flipped}) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    final path = Path();
    if (!flipped) {
      // →
      path.moveTo(pad, midY - shaft);
      path.lineTo(w - head - pad, midY - shaft);
      path.lineTo(w - head - pad, midY - head);
      path.lineTo(w - pad, midY);
      path.lineTo(w - head - pad, midY + head);
      path.lineTo(w - head - pad, midY + shaft);
      path.lineTo(pad, midY + shaft);
    } else {
      // ←
      path.moveTo(w - pad, midY - shaft);
      path.lineTo(head + pad, midY - shaft);
      path.lineTo(head + pad, midY - head);
      path.lineTo(pad, midY);
      path.lineTo(head + pad, midY + head);
      path.lineTo(head + pad, midY + shaft);
      path.lineTo(w - pad, midY + shaft);
    }
    path.close();
    return path;
  }

  Path _buildVerticalArrow(Size size, double pad, double shaft, double head,
      {required bool flipped}) {
    final w = size.width;
    final h = size.height;
    final midX = w / 2;

    final path = Path();
    if (!flipped) {
      // ↓
      path.moveTo(midX - shaft, pad);
      path.lineTo(midX - shaft, h - head - pad);
      path.lineTo(midX - head, h - head - pad);
      path.lineTo(midX, h - pad);
      path.lineTo(midX + head, h - head - pad);
      path.lineTo(midX + shaft, h - head - pad);
      path.lineTo(midX + shaft, pad);
    } else {
      // ↑
      path.moveTo(midX - shaft, h - pad);
      path.lineTo(midX - shaft, head + pad);
      path.lineTo(midX - head, head + pad);
      path.lineTo(midX, pad);
      path.lineTo(midX + head, head + pad);
      path.lineTo(midX + shaft, head + pad);
      path.lineTo(midX + shaft, h - pad);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
