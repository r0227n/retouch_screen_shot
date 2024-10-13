import 'package:flutter/material.dart';

/// An intent that represents the action of capturing the screen.
class CaptureScreenIntent extends Intent {
  const CaptureScreenIntent();
}

/// An intent that represents the action of capturing a window.
class CaptureWindowIntent extends Intent {
  const CaptureWindowIntent();
}

/// An intent that represents the action of capturing a region.
class CaptureRegionIntent extends Intent {
  const CaptureRegionIntent();
}

/// An action that captures the screen.
class CaptureScreenAction extends Action<CaptureScreenIntent> {
  CaptureScreenAction(this.callback);
  final VoidCallback callback;

  @override
  Object? invoke(CaptureScreenIntent intent) {
    callback();
    return null;
  }
}

/// An action that captures a window.
class CaptureWindowAction extends Action<CaptureWindowIntent> {
  CaptureWindowAction(this.callback);
  final VoidCallback callback;

  @override
  Object? invoke(CaptureWindowIntent intent) {
    callback();
    return null;
  }
}

/// An action that captures a region.
class CaptureRegionAction extends Action<CaptureRegionIntent> {
  CaptureRegionAction(this.callback);
  final VoidCallback callback;

  @override
  Object? invoke(CaptureRegionIntent intent) {
    callback();
    return null;
  }
}
