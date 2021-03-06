import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'abstract_drawing_state.dart';
import 'drawing_widget.dart';

class AnimatedDrawingWithTickerState extends AbstractAnimatedDrawingState
    with SingleTickerProviderStateMixin {
  AnimatedDrawingWithTickerState() : super() {
    onFinishAnimation = () {
      if (!onFinishEvoked) {
        onFinishEvoked = true;

        SchedulerBinding.instance?.addPostFrameCallback((_) {
          onFinishAnimationDefault();
        });

        if (controller != null &&
                controller!.status == AnimationStatus.dismissed ||
            controller!.status == AnimationStatus.completed) {
          finished = true;
        }
      }
    };
  }

  bool paused = false;
  bool finished = true;

  @override
  void didUpdateWidget(DrawAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller != null) {
      controller!.duration = widget.duration;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    addListenersToAnimationController();
  }

  @override
  void dispose() {
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    buildAnimation();
    return createCustomPaint(context);
  }

  Future<void> buildAnimation() async {
    try {
      if ((paused ||
              (finished &&
                  controller != null &&
                  !(controller!.status == AnimationStatus.forward))) &&
          widget.run == true) {
        paused = false;
        finished = false;
        controller!.reset();
        onFinishEvoked = false;
        controller!.forward();
      } else if (controller != null &&
          (controller!.status == AnimationStatus.forward) &&
          widget.run == false) {
        controller!.stop();
        paused = true;
      }
    } on TickerCanceled {}
  }
}
