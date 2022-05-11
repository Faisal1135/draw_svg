abstract class AnimationRange {
  AnimationRange(this.start, this.end) {
    assert(start <= end && start >= 0 && end >= 0);
  }
  final int start;
  final int end;

  bool get isLower => start != null;
  bool get isUpper => end != null;

  @override
  bool operator ==(Object o) =>
      o is AnimationRange && start == o.start && end == o.end;
}

class PathIndexRange extends AnimationRange {
  PathIndexRange({required int start, required int end}) : super(start, end);
}
