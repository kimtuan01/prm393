import 'package:flutter/material.dart';

/// Centralized notification system to display consistent top overlay banners
/// that slide down from the very top, covering the AppBar area, auto-dismiss,
/// and allow swipe-up dismissal. All existing calls automatically adopt this.
class AppNotification {
  static OverlayEntry? _currentOverlay;

  /// Success (green) — default 2s
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showTopOverlay(
      context,
      message,
      backgroundColor: Colors.green,
      duration: duration,
      icon: Icons.check_circle,
    );
  }

  /// Error (red) — default 2s
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showTopOverlay(
      context,
      message,
      backgroundColor: Colors.red,
      duration: duration,
      icon: Icons.error_outline,
    );
  }

  /// Warning (orange) — default 2s
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showTopOverlay(
      context,
      message,
      backgroundColor: Colors.orange,
      duration: duration,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Info (blue) — default 2s
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showTopOverlay(
      context,
      message,
      backgroundColor: Colors.blue,
      duration: duration,
      icon: Icons.info_outline,
    );
  }

  static void _showTopOverlay(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Duration duration,
    IconData? icon,
  }) {
    // Remove any existing overlay
    _removeCurrentOverlay();

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) => _TopNotificationBanner(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
        icon: icon,
        onClose: _removeCurrentOverlay,
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }

  static void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _TopNotificationBanner extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final IconData? icon;
  final VoidCallback onClose;

  const _TopNotificationBanner({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.onClose,
    this.icon,
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide down
    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (!_dismissed && mounted) _close();
    });
  }

  void _close() async {
    _dismissed = true;
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top; // avoid status bar
    const appBarHeight = kToolbarHeight; // 56.0 — standard AppBar height

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: const ValueKey('top_notification_banner'),
          direction: DismissDirection.up,
          onDismissed: (_) => _close(),
          child: Material(
            color: Colors.transparent,
            elevation: 10,
            child: Container(
              height: topPadding + appBarHeight, // cover status bar + AppBar
              decoration: BoxDecoration(color: widget.backgroundColor),
              padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null)
                    Icon(widget.icon, color: Colors.white),
                  if (widget.icon != null) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _close,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
