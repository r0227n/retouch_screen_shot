import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/l10n.dart';
import 'settings.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final (prefs, _) = await (SharedPreferences.getInstance(), hotKeyManager.unregisterAll()).wait;
  settings = signal<Settings>(Settings(prefs), autoDispose: true);

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings().locale.watch(context),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Uint8List?> _futureImage;

  @override
  void initState() {
    super.initState();
    final List<HotKey> hotKeys = [
      HotKey(
        identifier: 'capture_screen_hotkey',
        key: PhysicalKeyboardKey.keyS,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      ),
      HotKey(
        identifier: 'capture_window_hotkey',
        key: PhysicalKeyboardKey.keyW,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      ),
      HotKey(
        identifier: 'capture_region_hotkey',
        key: PhysicalKeyboardKey.keyR,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      ),
    ];

    _futureImage = Future.wait(
      hotKeys.map(
        (key) => hotKeyManager.register(
          key,
          keyDownHandler: (hotKey) {
            capture(switch (hotKey.key) {
              PhysicalKeyboardKey.keyS => CaptureMode.screen,
              PhysicalKeyboardKey.keyW => CaptureMode.window,
              PhysicalKeyboardKey.keyR => CaptureMode.region,
              _ => throw Exception('Invalid hotkey'),
            });
          },
        ),
      ),
    ).then((_) => null);
  }

  @override
  void dispose() {
    hotKeyManager.unregisterAll();
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          MenuAnchor(
            menuChildren: <Widget>[
              MenuItemButton(
                child: Text(context.l10n.settings),
                onPressed: () {
                  _showMenuDialog(
                    context: context,
                    children: [
                      for (final locale in AppLocalizations.supportedLocales)
                        Watch((context) => RadioListTile<Locale>(
                              value: locale,
                              groupValue: settings().locale.value,
                              onChanged: (value) {
                                settings().locale.value = value ?? const Locale('en');
                              },
                              title: Text(locale.toLabel(context)),
                            ))
                    ],
                  );
                },
              ),
              MenuItemButton(
                child: Text(context.l10n.licenses),
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
    );
  }

  void capture(CaptureMode mode) {
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
