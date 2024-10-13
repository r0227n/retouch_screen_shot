import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:image/image.dart' as img;
import 'shortcut.dart';

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
      color: img.ColorRgba8(0, 0, 0, 128),
    );

    // Draw the timestamp on the image
    img.drawString(
      originalImage,
      text,
      x: 10,
      y: 10,
      font: img.arial24,
      color: img.ColorRgb8(0, 0, 0),
    );

    return Uint8List.fromList(img.encodePng(originalImage));
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
            LogicalKeyboardKey.keyS,
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.shift,
          ): const CaptureScreenIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.keyW,
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.shift,
          ): const CaptureWindowIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.keyR,
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.shift,
          ): const CaptureRegionIntent(),
        },
        child: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

/// A ShortcutManager that logs all keys that it handles.
class LoggingShortcutManager extends ShortcutManager {
  @override
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    final KeyEventResult result = super.handleKeypress(context, event);
    if (result == KeyEventResult.handled) {
      print('Handled shortcut $event in $context');
    }
    return result;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Uint8List?> _futureImage;

  @override
  void initState() {
    super.initState();
    _futureImage = Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        CaptureScreenIntent: CaptureScreenAction(() => capture(CaptureMode.screen)),
        CaptureWindowIntent: CaptureWindowAction(() => capture(CaptureMode.window)),
        CaptureRegionIntent: CaptureRegionAction(() => capture(CaptureMode.region)),
      },
      child: FocusScope(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              MenuAnchor(
                menuChildren: <Widget>[
                  MenuItemButton(
                    child: const Text('Settings'),
                    onPressed: () {
                      _showMenuDialog(context: context, children: const [
                        Text('About'),
                      ]);
                    },
                  ),
                  MenuItemButton(
                    child: const Text('License'),
                    onPressed: () {
                      // TODO: license dialog
                    },
                  ),
                ],
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: FutureBuilder(
              future: _futureImage,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                return switch ((snapshot.connectionState, snapshot.data)) {
                  (ConnectionState.waiting, null) => const CircularProgressIndicator(),
                  (ConnectionState.done, null) => const Text('No image captured'),
                  (ConnectionState.done, Uint8List data) => Image.memory(
                      data,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) {
                          return child;
                        } else {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: frame != null ? child : const CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  _ => const Text('Capturing...'),
                };
              },
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            tooltip: 'More options',
            child: const Icon(Icons.more_vert),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final mode in [CaptureMode.screen, CaptureMode.window, CaptureMode.region])
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    iconSize: 56.0,
                    onPressed: () => capture(mode),
                    tooltip: switch (mode) {
                      CaptureMode.screen => 'Capture Entire Screen',
                      CaptureMode.window => 'Capture Selected Window',
                      CaptureMode.region => 'Capture Selected Region'
                    },
                    icon: switch (mode) {
                      CaptureMode.screen => const Icon(Icons.screenshot_monitor),
                      CaptureMode.window => const Icon(Icons.tab_outlined),
                      CaptureMode.region => const Icon(Icons.crop)
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void capture(CaptureMode mode) {
    print('method');
    setState(() {
      _futureImage = screenCapturer
          .capture(
        mode: mode,
        imagePath: null,
        silent: false,
      )
          .then((value) {
        if (value?.imageBytes != null) {
          return value!.imageBytes!.addTextToImage(DateTime.now().toLocal().toString());
        }
        return null;
      });
    });
  }

  Future<void> _showMenuDialog({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: ListBody(children: children),
            ),
          ),
          contentPadding: const EdgeInsets.all(32.0),
        );
      },
    );
  }
}
