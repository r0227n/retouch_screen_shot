import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:image/image.dart' as img;

class CaptureButton {
  const CaptureButton({
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    this.iconSize = 56.0,
    required this.tooltip,
    required this.onPressed,
  });

  final bool isSelected;
  final Widget icon;
  final Widget selectedIcon;
  final double iconSize;
  final String tooltip;
  final VoidCallback onPressed;

  Widget build() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        iconSize: iconSize,
        onPressed: onPressed,
        tooltip: tooltip,
        color: isSelected ? Colors.white : null,
        isSelected: isSelected,
        icon: icon,
        selectedIcon: selectedIcon,
      ),
    );
  }

  CaptureButton copyWith({
    bool? isSelected,
    Widget? icon,
    Widget? selectedIcon,
    double? iconSize,
    String? tooltip,
    VoidCallback? onPressed,
  }) {
    return CaptureButton(
      isSelected: isSelected ?? this.isSelected,
      icon: icon ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      iconSize: iconSize ?? this.iconSize,
      tooltip: tooltip ?? this.tooltip,
      onPressed: onPressed ?? this.onPressed,
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
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
  Uint8List? _imageData;
  CaptureMode? _selectedCaptureMode;

  Future<void> capture(CaptureMode mode) async {
    CapturedData? capturedData = await screenCapturer.capture(
      mode: mode,
      imagePath: null,
      silent: false,
    );
    setState(() {
      if (capturedData?.imageBytes != null) {
        _imageData = addTimestampToImage(capturedData!.imageBytes!);
      }
      _selectedCaptureMode = mode;
    });
  }

  late final List<CaptureButton> captureButtons;

  @override
  void initState() {
    super.initState();

    captureButtons = [
      CaptureButton(
        isSelected: _selectedCaptureMode == CaptureMode.screen,
        icon: const Icon(Icons.screenshot_monitor),
        selectedIcon: const Icon(Icons.screenshot_monitor_outlined),
        tooltip: 'Full Screen',
        onPressed: () => capture(CaptureMode.screen),
      ),
      CaptureButton(
        isSelected: _selectedCaptureMode == CaptureMode.region,
        icon: const Icon(Icons.crop),
        selectedIcon: const Icon(Icons.crop_outlined),
        tooltip: 'Region',
        onPressed: () => capture(CaptureMode.region),
      ),
      CaptureButton(
        isSelected: _selectedCaptureMode == CaptureMode.window,
        icon: const Icon(Icons.tab_outlined),
        selectedIcon: const Icon(Icons.tab_outlined),
        tooltip: 'Window',
        onPressed: () => capture(CaptureMode.window),
      ),
    ];
  }

  /// Adds a timestamp to the given image data.
  ///
  /// This function decodes the provided image data, adds a timestamp at the
  /// specified position, and returns the modified image data.
  ///
  /// The timestamp is drawn with a semi-transparent black background to ensure
  /// readability.
  ///
  /// Parameters:
  /// - `imageData` (`Uint8List`): The original image data.
  /// - `x` (`int`, optional): The x-coordinate of the top-left corner of the
  ///   timestamp. Default is 10.
  /// - `y` (`int`, optional): The y-coordinate of the top-left corner of the
  ///   timestamp. Default is 10.
  /// - `textHeight` (`int`, optional): The height of the text background.
  ///   Default is 30.
  ///
  /// Returns:
  /// - `Uint8List`: The modified image data with the timestamp added.
  Uint8List addTimestampToImage(
    Uint8List imageData, {
    int x = 10,
    int y = 10,
    int textHeight = 30,
  }) {
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return imageData;

    String timestamp = DateTime.now().toLocal().toString();

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
      timestamp,
      x: 10,
      y: 10,
      font: img.arial24,
      color: img.ColorRgb8(0, 0, 0),
    );

    return Uint8List.fromList(img.encodePng(originalImage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _imageData != null ? Image.memory(_imageData!) : const Text('No image captured'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'More options',
        child: const Icon(Icons.more_vert),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final button in captureButtons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: button.build(),
            ),
        ]),
      ),
    );
  }
}
