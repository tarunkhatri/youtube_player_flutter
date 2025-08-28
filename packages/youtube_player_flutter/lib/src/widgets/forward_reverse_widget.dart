import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/youtube_player_controller.dart';

class ForwardRewindControls extends StatefulWidget {
  const ForwardRewindControls({
    super.key,
    this.controller,
    this.rewindDuration = const Duration(seconds: 10),
    this.forwardDuration = const Duration(seconds: 10),
    this.tapShowDuration = const Duration(milliseconds: 500),
    this.controlsTimeOut = const Duration(seconds: 3),
  });

  final YoutubePlayerController? controller;
  final Duration rewindDuration;
  final Duration forwardDuration;
  final Duration tapShowDuration;
  final Duration controlsTimeOut;

  @override
  State<ForwardRewindControls> createState() => _ForwardRewindControlsState();
}

class _ForwardRewindControlsState extends State<ForwardRewindControls> with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late AnimationController _rewindAnimationController;
  late AnimationController _forwardAnimationController;
  Timer? _timer;

  final ValueNotifier<bool> _showRewindButton = ValueNotifier(false);
  final ValueNotifier<bool> _showForwardButton = ValueNotifier(false);
  final ValueNotifier<bool> _showInitialButtons = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    _rewindAnimationController = AnimationController(
      vsync: this,
      duration: widget.tapShowDuration,
    );

    _forwardAnimationController = AnimationController(
      vsync: this,
      duration: widget.tapShowDuration,
    );

    // Hide initial buttons after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _showInitialButtons.value = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = YoutubePlayerController.of(context);
    assert(
    controller != null || widget.controller != null,
    'No YoutubePlayerController found in context. Pass one explicitly.',
    );
    _controller = controller ?? widget.controller!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewindAnimationController.dispose();
    _forwardAnimationController.dispose();
    _showRewindButton.dispose();
    _showForwardButton.dispose();
    _showInitialButtons.dispose();
    super.dispose();
  }

  void _showRewindButtonAnimation() {
    _showRewindButton.value = true;
    _rewindAnimationController.reset();
    _rewindAnimationController.forward().then((_) {
      _showRewindButton.value = false;
    });
  }

  void _showForwardButtonAnimation() {
    _showForwardButton.value = true;
    _forwardAnimationController.reset();
    _forwardAnimationController.forward().then((_) {
      _showForwardButton.value = false;
    });
  }

  void _toggleControls() {
    _controller.updateValue(
      _controller.value.copyWith(
        isControlsVisible: !_controller.value.isControlsVisible,
      ),
    );

    _timer?.cancel();
    _timer = Timer(widget.controlsTimeOut, () {
      if (!_controller.value.isDragging) {
        _controller.updateValue(
          _controller.value.copyWith(
            isControlsVisible: false,
          ),
        );
      }
    });
  }

  void _rewind() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - widget.rewindDuration;
    final targetPosition = newPosition.isNegative ? Duration.zero : newPosition;

    _controller.seekTo(targetPosition);
    _showRewindButtonAnimation();
  }

  void _forward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + widget.forwardDuration;
    final maxDuration = _controller.metadata.duration;
    final targetPosition = newPosition > maxDuration ? maxDuration : newPosition;

    _controller.seekTo(targetPosition);
    _showForwardButtonAnimation();
  }

  Widget _buildButton({
    required ValueNotifier<bool> notifier,
    required bool isForward,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isVisible, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _showInitialButtons,
          builder: (context, showInitial, _) {
            if (!isVisible && !showInitial) return const SizedBox.shrink();

            return AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(22.5),
                ),
                child: isForward
                    ? const Icon(Icons.double_arrow_rounded, color: Colors.white70, size: 22)
                    : Transform.rotate(
                  angle: math.pi,
                  child: const Icon(Icons.double_arrow_rounded, color: Colors.white70, size: 22),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final halfWidth = MediaQuery.of(context).size.width * 0.5;

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onDoubleTap: _rewind,
                onTap: _toggleControls,
                child: Container(color: Colors.transparent),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTap: _forward,
                onTap: _toggleControls,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
        // Rewind button
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(width: halfWidth, child: Center(child: _buildButton(notifier: _showRewindButton, isForward: false))),
        ),
        // Forward button
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(width: halfWidth, child: Center(child: _buildButton(notifier: _showForwardButton, isForward: true))),
        ),
      ],
    );
  }
}
