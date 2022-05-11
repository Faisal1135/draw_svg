class DebugOptions {
  DebugOptions({
    this.showBoundingBox = false,
    this.showViewPort = false,
    this.recordFrames = false,
    this.resolutionFactor = 1.0,
    this.fileName = "",
    this.outPutDir = "",
  });

  final bool showBoundingBox;
  final bool showViewPort;
  final bool recordFrames;
  final String outPutDir;
  final String fileName;

  final double resolutionFactor;

  int _frameCount = -1;
}

void resetFrame(DebugOptions options) {
  options._frameCount = -1;
}

void iterateFrame(DebugOptions options) {
  options._frameCount++;
}

int getFrameCount(DebugOptions options) {
  return options._frameCount;
}
