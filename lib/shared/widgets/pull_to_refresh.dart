import 'dart:math' show max, pi, pow, sin;
import 'package:flutter/material.dart';

// ── Scroll physics: pull-to-refresh at top + iOS-like bounce at bottom ────

class RefreshScrollPhysics extends ScrollPhysics {
  const RefreshScrollPhysics({super.parent});

  @override
  RefreshScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return RefreshScrollPhysics(parent: const BouncingScrollPhysics());
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset > 0 && position.pixels >= position.maxScrollExtent) {
      final overscrollFraction =
          (position.pixels - position.maxScrollExtent) /
          position.viewportDimension;
      final friction = 0.52 * pow(1.0 - overscrollFraction.clamp(0.0, 1.0), 2);
      return offset * friction.clamp(0.05, 1.0);
    }
    return offset;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.minScrollExtent,
        max(0.0, velocity),
        tolerance: toleranceFor(position),
      );
    }
    return parent?.createBallisticSimulation(position, velocity);
  }
}

// ── Scroll physics: top-clamped + iOS-like bounce at bottom (for dismiss screens) ──

class DismissScrollPhysics extends ScrollPhysics {
  const DismissScrollPhysics({super.parent});

  @override
  DismissScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DismissScrollPhysics(parent: const BouncingScrollPhysics());
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 上端: クランプ（コンテンツが動かないように）
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    // 下端: オーバースクロール許可（BouncingScrollPhysics に委任）
    return 0.0;
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 下端を超えてドラッグ: iOS 風の抵抗
    if (offset > 0 && position.pixels >= position.maxScrollExtent) {
      final overscrollFraction =
          (position.pixels - position.maxScrollExtent) /
          position.viewportDimension;
      final friction = 0.52 * pow(1.0 - overscrollFraction.clamp(0.0, 1.0), 2);
      return offset * friction.clamp(0.05, 1.0);
    }
    return offset;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // 下端のスプリングバックは BouncingScrollPhysics に委任
    return parent?.createBallisticSimulation(position, velocity);
  }
}

// ── Scroll physics: 1.5% top micro-bounce on arrival + top-clamped at rest (for dismiss) ──

class DismissScrollPhysicsWithTopBounce extends ScrollPhysics {
  const DismissScrollPhysicsWithTopBounce({super.parent});

  @override
  DismissScrollPhysicsWithTopBounce applyTo(ScrollPhysics? ancestor) {
    return DismissScrollPhysicsWithTopBounce(
      parent: const BouncingScrollPhysics(),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 上端: 既に最上部にいる → クランプ（dismiss用、コンテンツを動かさない）
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    // 上端: スクロール中に上端に到達 → 1.5%までマイクロバウンス許可、それ以上クランプ
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      final limit = -position.viewportDimension * 0.015;
      if (value >= limit) return 0.0;
      return value - limit;
    }
    // 下端: バウンス許可
    return 0.0;
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 下端バウンス抵抗
    if (offset > 0 && position.pixels >= position.maxScrollExtent) {
      final fraction =
          (position.pixels - position.maxScrollExtent) /
          position.viewportDimension;
      final friction = 0.52 * pow(1.0 - fraction.clamp(0.0, 1.0), 2);
      return offset * friction.clamp(0.05, 1.0);
    }
    return offset;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // 上端を超えていたらスプリングバックで0に戻す
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.minScrollExtent,
        max(0.0, velocity),
        tolerance: toleranceFor(position),
      );
    }
    // 下端のスプリングバックは BouncingScrollPhysics に委任
    return parent?.createBallisticSimulation(position, velocity);
  }
}

// ── Three-dot pull-to-refresh indicator ───────────────────────────────────

class PullRefreshDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final int dotsVisible;
  final bool isRefreshing;

  const PullRefreshDots({
    super.key,
    required this.controller,
    required this.color,
    required this.dotsVisible,
    required this.isRefreshing,
  });

  Widget _dot(int i) => AnimatedBuilder(
    animation: controller,
    builder: (ctx, child) {
      double dy = 0;
      if (isRefreshing) {
        final t = controller.value;
        final start = i / 4.0;
        final end = start + 0.25;
        if (t >= start && t < end) {
          dy = -9.0 * sin((t - start) / 0.25 * pi);
        }
      }
      return Transform.translate(offset: Offset(0, dy), child: child);
    },
    child: Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final show = isRefreshing || i < dotsVisible;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedSlide(
              offset: show ? Offset.zero : const Offset(0, -1.5),
              duration: const Duration(milliseconds: 380),
              curve: Curves.elasticOut,
              child: _dot(i),
            ),
          ),
        );
      }),
    );
  }
}
