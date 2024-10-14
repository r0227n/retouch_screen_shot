import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Color;
import 'package:image/image.dart' as img;
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

extension ColorX on Color {
  /// Converts the current color to an `img.ColorRgba8` object.
  ///
  /// This method returns a new `img.ColorRgba8` instance with the red, green,
  /// blue, and alpha values of the current color.
  ///
  /// Returns:
  ///   An `img.ColorRgba8` object representing the current color.
  img.ColorRgba8 toRgba8() {
    return img.ColorRgba8(red, green, blue, alpha);
  }
}

extension Uint8ListX on Uint8List {
  /// Adds a text overlay to an image.
  ///
  /// This function takes a string of text and overlays it onto an image at the specified
  /// coordinates. The text is drawn with a semi-transparent background to ensure readability.
  ///
  /// Parameters:
  /// - `text` (String): The text to be added to the image.
  /// - `x` (int, optional): The x-coordinate where the text will be placed. Default is 10.
  /// - `y` (int, optional): The y-coordinate where the text will be placed. Default is 10.
  /// - `textHeight` (int, optional): The height of the text background. Default is 30.
  ///
  /// Returns:
  /// - `Uint8List`: The modified image with the text overlay. If the original image cannot be
  ///   decoded, the function returns the original image.
  ///
  /// Example:
  /// ```dart
  /// Uint8List modifiedImage = addTextToImage('Hello, World!', x: 50, y: 50, textHeight: 40);
  /// ```
  Uint8List addTextToImage(
    String text, {
    int x = 10,
    int y = 10,
    int textHeight = 30,
    Color textColor = const Color(0xFF000000), // Black
    Color backgroundColor = const Color(0xFFFFFFFF), // White
  }) {
    img.Image? originalImage = img.decodeImage(this);
    if (originalImage == null) return this;

    int maxWidth = originalImage.width - 20;

    // Draw background
    img.fillRect(
      originalImage,
      x1: x,
      y1: y,
      x2: x + maxWidth,
      y2: y + textHeight,
      color: backgroundColor.toRgba8(),
    );

    // Draw the timestamp on the image
    img.drawString(
      originalImage,
      text,
      x: 10,
      y: 10,
      font: img.arial24,
      color: textColor.toRgba8(),
    );

    return Uint8List.fromList(img.encodePng(originalImage));
  }

  /// Copy the current image to the clipboard as a PNG file.
  ///
  /// This method writes the image bytes to a temporary file named 'screenshot.png'
  /// and then uses the Pasteboard to copy the file path to the clipboard.
  ///
  /// Returns a [Future] that completes with `true` if the operation was successful,
  /// or `false` otherwise.
  Future<bool> copyToClipboard() async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/screenshot.png');
    await file.writeAsBytes(this);

    return Pasteboard.writeFiles([file.path]);
  }
}
