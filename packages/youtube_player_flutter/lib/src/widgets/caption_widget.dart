import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

/// A widget which displays caption toggle controls in the video player.
class CaptionControls extends StatefulWidget {
  const CaptionControls({
    super.key,
    this.controller,
    this.iconColor = Colors.white,
    this.iconSize = 22.0,
    this.onCaptionToggle,
  });

  final YoutubePlayerController? controller;
  final Color iconColor;
  final double iconSize;
  final VoidCallback? onCaptionToggle;

  @override
  State<CaptionControls> createState() => _CaptionControlsState();
}

class _CaptionControlsState extends State<CaptionControls> {
  late YoutubePlayerController _controller;

  final ValueNotifier<bool> _isCaptionsEnabled = ValueNotifier(false);
  final ValueNotifier<bool> _isVisible = ValueNotifier(true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    assert(
    controller != null || widget.controller != null,
    'No YoutubePlayerController found. Pass one explicitly.',
    );
    _controller = controller ?? widget.controller!;

    _isCaptionsEnabled.value = _controller.flags.enableCaption;
    _isVisible.value = _controller.value.isControlsVisible;

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      _isVisible.value = _controller.value.isControlsVisible;
    }
  }

  void _toggleCaptions() {
    final newState = !_isCaptionsEnabled.value;
    _isCaptionsEnabled.value = newState;

    if (newState) {
      _controller.showCaptions();
    } else {
      _controller.hideCaptions();
    }

    widget.onCaptionToggle?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _isCaptionsEnabled.dispose();
    _isVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isVisible,
        builder: (context, visible, _) {
          return AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: _toggleCaptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isCaptionsEnabled,
                  builder: (context, isEnabled, _) {
                    return Icon(
                      isEnabled ? Icons.closed_caption : Icons.closed_caption_off,
                      color: widget.iconColor,
                      size: widget.iconSize,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
