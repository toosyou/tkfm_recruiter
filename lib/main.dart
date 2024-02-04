import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:dash_bubble/dash_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'snackbars.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF04599c);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dash Bubble Playground',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          background: primaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dash Bubble Playground'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _requestOverlayPermission(context),
                child: const Text('Request Overlay Permission'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _hasOverlayPermission(context),
                child: const Text('Has Overlay Permission?'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _requestPostNotificationsPermission(context),
                child: const Text('Request Post Notifications Permission'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _hasPostNotificationsPermission(context),
                child: const Text('Has Post Notifications Permission?'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _isRunning(context),
                child: const Text('Is Running?'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _startBubble(
                    context,
                    bubbleOptions: BubbleOptions(
                      // notificationIcon: 'github_bubble',
                      bubbleIcon: 'github_bubble',
                      // closeIcon: 'github_bubble',
                      startLocationX: 0,
                      startLocationY: 100,
                      bubbleSize: 60,
                      opacity: 1,
                      enableClose: true,
                      closeBehavior: CloseBehavior.following,
                      distanceToClose: 100,
                      enableAnimateToEdge: true,
                      enableBottomShadow: true,
                      keepAliveWhenAppExit: false,
                    ),
                    notificationOptions: NotificationOptions(
                      id: 1,
                      title: 'Dash Bubble Playground',
                      body: 'Dash Bubble service is running',
                      channelId: 'dash_bubble_notification',
                      channelName: 'Dash Bubble Notification',
                    ),
                    onTap: () async {
                      _logMessage(
                        context: context,
                        message: 'Bubble Tapped',
                      );
                      var screenshotBase64 = await const MethodChannel('channel_screenshot').invokeMethod<String>('getScreenshot'); // PNG base64
                      screenshotBase64 = screenshotBase64!.replaceAll(RegExp(r'\s+'), '');

                      final screenshotBytes = const Base64Decoder().convert(screenshotBase64);
                      final screenshot = img.decodeImage(screenshotBytes);
                      final screenshotNV21 = convertRGBtoNV21(screenshot!.getBytes(order: img.ChannelOrder.rgb), screenshot.width, screenshot.height);

                      final imageSize = Size(screenshot.width.toDouble(), screenshot.height.toDouble());

                      final imageRotation = InputImageRotationValue.fromRawValue(0);
                      const inputImageFormat = InputImageFormat.nv21;

                      final inputImage = InputImage.fromBytes(bytes: screenshotNV21, metadata: InputImageMetadata(
                        size: imageSize,
                        rotation: imageRotation!,
                        format: inputImageFormat,
                        bytesPerRow: 0,
                      ));

                      // await DashBubble.instance.setBubbleIcon(image);
                      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
                      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
                      print("recongnized text");

                      String text = recognizedText.text;
                      print(text);
                      for (TextBlock block in recognizedText.blocks) {
                        final Rect rect = block.boundingBox;
                        final List<math.Point<int>> cornerPoints = block.cornerPoints;
                        final String text = block.text;
                        final List<String> languages = block.recognizedLanguages;
                        
                        for (TextLine line in block.lines) {
                          // Same getters as TextBlock
                          for (TextElement element in line.elements) {
                            // Same getters as TextBlock
                            print(element.text);
                          }
                        }
                      }
                      textRecognizer.close();
                    },
                    onTapDown: (x, y) => _logMessage(
                      context: context,
                      message:
                          'Bubble Tapped Down on: ${_getRoundedCoordinatesAsString(x, y)}',
                    ),
                    onTapUp: (x, y) => _logMessage(
                      context: context,
                      message:
                          'Bubble Tapped Up on: ${_getRoundedCoordinatesAsString(x, y)}',
                    ),
                    onMove: (x, y) => _logMessage(
                      context: context,
                      message:
                          'Bubble Moved to: ${_getRoundedCoordinatesAsString(x, y)}',
                    ),
                  );
                },
                child: const Text('Start Bubble'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _stopBubble(context),
                child: const Text('Stop Bubble'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List convertRGBtoNV21(Uint8List rgbBytes, int cols, int rows) {
    int yIndex = 0;
    int uyIndex = rows * cols;
    Uint8List yuvbuff = Uint8List((1.5 * rows * cols).toInt());

    List<int> nv21 = List<int>.filled((rows + rows ~/ 2) * cols, 0);

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        int Y = 0;
        int U = 0;
        int V = 0;

        int B = rgbBytes[(i * cols + j) * 3];
        int G = rgbBytes[(i * cols + j) * 3 + 1];
        int R = rgbBytes[(i * cols + j) * 3 + 2];

        // Calculate Y value
        Y = (77 * R + 150 * G + 29 * B) >> 8;
        nv21[i * cols + j] = Y;
        yuvbuff[yIndex++] = (Y < 0) ? 0 : ((Y > 255) ? 255 : Y);

        // Calculate U, V values with 2x2 sampling
        if (i % 2 == 0 && (j) % 2 == 0) {
          U = ((-44 * R - 87 * G + 131 * B) >> 8) + 128;
          V = ((131 * R - 110 * G - 21 * B) >> 8) + 128;
          nv21[(rows + i ~/ 2) * cols + j] = V;
          nv21[(rows + i ~/ 2) * cols + j + 1] = U;
          yuvbuff[uyIndex++] = (V < 0) ? 0 : ((V > 255) ? 255 : V);
          yuvbuff[uyIndex++] = (U < 0) ? 0 : ((U > 255) ? 255 : U);
        }
      }
    }

    return Uint8List.fromList(yuvbuff);
  }

  Future<void> _runMethod(
    BuildContext context,
    Future<void> Function() method,
  ) async {
    try {
      await method();
    } catch (error) {
      log(
        name: 'Dash Bubble Playground',
        error.toString(),
      );

      SnackBars.show(
        context: context,
        status: SnackBarStatus.error,
        message: 'Error: ${error.runtimeType}',
      );
    }
  }

  Future<void> _requestOverlayPermission(BuildContext context) async {
    await _runMethod(
      context,
      () async {
        final isGranted = await DashBubble.instance.requestOverlayPermission();

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: isGranted
              ? 'Overlay Permission Granted'
              : 'Overlay Permission is not Granted',
        );
      },
    );
  }

  Future<void> _hasOverlayPermission(BuildContext context) async {
    await _runMethod(
      context,
      () async {
        final hasPermission = await DashBubble.instance.hasOverlayPermission();

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: hasPermission
              ? 'Overlay Permission Granted'
              : 'Overlay Permission is not Granted',
        );
      },
    );
  }

  Future<void> _requestPostNotificationsPermission(
    BuildContext context,
  ) async {
    await _runMethod(
      context,
      () async {
        final isGranted =
            await DashBubble.instance.requestPostNotificationsPermission();

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: isGranted
              ? 'Post Notifications Permission Granted'
              : 'Post Notifications Permission is not Granted',
        );
      },
    );
  }

  Future<void> _hasPostNotificationsPermission(BuildContext context) async {
    await _runMethod(
      context,
      () async {
        final hasPermission =
            await DashBubble.instance.hasPostNotificationsPermission();

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: hasPermission
              ? 'Post Notifications Permission Granted'
              : 'Post Notifications Permission is not Granted',
        );
      },
    );
  }

  Future<void> _isRunning(BuildContext context) async {
    await _runMethod(
      context,
      () async {
        final isRunning = await DashBubble.instance.isRunning();

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: isRunning ? 'Bubble is Running' : 'Bubble is not Running',
        );
      },
    );
  }

  Future<void> _startBubble(
    BuildContext context, {
    BubbleOptions? bubbleOptions,
    NotificationOptions? notificationOptions,
    VoidCallback? onTap,
    Function(double x, double y)? onTapDown,
    Function(double x, double y)? onTapUp,
    Function(double x, double y)? onMove,
  }) async {
    await _runMethod(
      context,
      () async {
        final hasStarted = await DashBubble.instance.startBubble(
          bubbleOptions: bubbleOptions,
          notificationOptions: notificationOptions,
          onTap: onTap,
          onTapDown: onTapDown,
          onTapUp: onTapUp,
          onMove: onMove,
        );

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: hasStarted ? 'Bubble Started' : 'Bubble has not Started',
        );
      },
    );
  }

  Future<void> _stopBubble(BuildContext context) async {
    await _runMethod(
      context,
      () async {
        final hasStopped = await DashBubble.instance.stopBubble();

        SnackBars.show(
          context: context,
          status: SnackBarStatus.success,
          message: hasStopped ? 'Bubble Stopped' : 'Bubble has not Stopped',
        );
      },
    );
  }

  void _logMessage({required BuildContext context, required String message}) {
    log(name: 'DashBubblePlayground', message);

    SnackBars.show(
      context: context,
      status: SnackBarStatus.success,
      message: message,
    );
  }

  String _getRoundedCoordinatesAsString(double x, double y) {
    return '${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}';
  }
}
