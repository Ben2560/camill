import 'package:flutter/material.dart';
import '../../core/theme/camill_colors.dart';
import 'pull_to_refresh.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final String? subtitle;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.subtitle,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isLoading) _dotsController.repeat();
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_dotsController.isAnimating) {
      _dotsController.repeat();
    } else if (!widget.isLoading) {
      _dotsController.stop();
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        // コンテンツ：ロード完了時にフェードイン
        AnimatedOpacity(
          opacity: widget.isLoading ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: widget.child,
        ),
        // ローディング表示：ロード中のみポインターを受け取る
        IgnorePointer(
          ignoring: !widget.isLoading,
          child: AnimatedOpacity(
            opacity: widget.isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
                // 上部の極細プログレスバー
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      colors.primary.withAlpha(100),
                    ),
                    minHeight: 2,
                  ),
                ),
                // 中央の3ドット（＋メッセージ）
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PullRefreshDots(
                        controller: _dotsController,
                        color: colors.textMuted,
                        dotsVisible: 3,
                        isRefreshing: true,
                      ),
                      if (widget.message != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          widget.message!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
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
      ],
    );
  }
}
