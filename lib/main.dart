import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:dash_bubble/dash_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:trotter/trotter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'snackbars.dart';

void main() {
  LocalNotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 23, 24, 30);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '天下布魔招募助手',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          background: primaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 150,
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Color.fromARGB(255, 20, 87, 232),
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
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen({
    super.key,
  });

  var characterNames;
  var characterTags;
  var tagSet;
  var charIndexWithTags;
  var chineseFixDict;
  var chineseDistanceCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 120, 11, 103),
              Color.fromARGB(255, 71, 5, 16),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '天下布魔招募助手',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 30,
                    letterSpacing: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'TKFM Recruiter',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 15,
                    wordSpacing: 5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.23),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: const Color.fromARGB(
                        255, 255, 255, 255), // <-- Button color
                    foregroundColor:
                        const Color.fromARGB(255, 0, 0, 0), // <-- Splash color
                    fixedSize: const Size(200, 200),
                  ),
                  onPressed: () {
                    DashBubble.instance.requestOverlayPermission();
                    DashBubble.instance.requestPostNotificationsPermission();

                    const MethodChannel('channel_screenshot')
                        .invokeMethod<String>('getScreenshot'); // PNG base64

                    // download data if not exists
                    if (characterNames == null || characterTags == null || chineseFixDict == null) {
                      _initData();
                      chineseDistance('布', '魔');
                    }
                    
                    _startBubble(
                      context,
                      bubbleOptions: BubbleOptions(
                        // notificationIcon: 'github_bubble',
                        bubbleIcon: 'shiro',
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
                        title: '天下布魔招募助手',
                        body: '天下布魔招募助手 正在執行',
                        channelId: 'dash_bubble_notification',
                        channelName: 'Dash Bubble Notification',
                        icon: 'shiro',
                      ),
                      onTap: () async {
                        Fluttertoast.showToast(
                          msg: "截圖分析中...",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                        );

                        String? screenshotBase64;
                        try {
                          screenshotBase64 =
                              await const MethodChannel('channel_screenshot')
                                  .invokeMethod<String>(
                                      'getScreenshot'); // PNG base64
                        } on PlatformException {
                          Fluttertoast.showToast(
                            msg: "請允許截圖權限並再試一次！",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                          );
                          await Future.delayed(const Duration(seconds: 1));
                          screenshotBase64 =
                              await const MethodChannel('channel_screenshot')
                                  .invokeMethod<String>(
                                      'getScreenshot'); // PNG base64
                        }
                        var foundTagStrings = await getTagsFromScreenshot(
                            screenshotBase64!.replaceAll(RegExp(r'\s+'), ''));

                        if (foundTagStrings
                            .contains(characterNames['tags'][20])) {
                          LocalNotificationService().showNotificationAndroid(
                              "恭喜找到領袖！",
                              "請至 purindaisuki.github.io/tkfmtools/ 查看細節！");
                          return;
                        } else {
                          var (recommendedName, recommendedComb) =
                              getRecommendedCharacters(foundTagStrings);
                          if (recommendedName == '') {
                            if (foundTagStrings.length == 5) {
                              LocalNotificationService()
                                  .showNotificationAndroid("沒有找到推薦組合 :( ",
                                      foundTagStrings.join(', '));
                              return;
                            } else {
                              LocalNotificationService().showNotificationAndroid(
                                  "分析失敗！",
                                  "只找到 ${foundTagStrings.length} 個標籤. 請再試一次或截圖回報錯誤.");
                              return;
                            }
                          } else {
                            LocalNotificationService()
                                .showNotificationAndroid(
                                    "推薦 ★ $recommendedName",
                                    "標籤組合：${recommendedComb.join(', ')}");
                            return;
                          }
                        }
                      },
                    );
                  },
                  child: const Text('開啟助手泡泡',
                      style: TextStyle(
                          fontSize: 23,
                          letterSpacing: 2, 
                          fontWeight: FontWeight.bold)
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
              ],
            ),
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

  Future<void> _initData() async {
    final characterNamesString = await http.get(Uri.parse(
        "https://raw.githubusercontent.com/purindaisuki/tkfmtools/master/src/data/string/character_zh-TW.json"));
    final characterTagsString = await http.get(Uri.parse(
        "https://raw.githubusercontent.com/purindaisuki/tkfmtools/master/src/data/character.json"));
    final chineseFixString = await http.get(Uri.parse("https://raw.githubusercontent.com/toosyou/tkfm_recruiter/main/data/chinese_fix.json"));

    characterNames = jsonDecode(characterNamesString.body);
    characterTags = jsonDecode(characterTagsString.body);
    chineseFixDict = jsonDecode(chineseFixString.body);

    // create overall tags
    for (var i = 0; i < characterTags.length; i++) {
      characterTags[i]['overall_tags'] = [];
      for (var tag in [
        'attribute',
        'position',
        'race',
        'body',
        'oppai',
        'rank'
      ]) {
        characterTags[i]['overall_tags'].add(characterTags[i]['tags'][tag]);
      }
      characterTags[i]['overall_tags'] += characterTags[i]['tags']['else'];
    }

    charIndexWithTags = {};
    for (var tag in characterNames['tags']) {
      final tagIndex = characterNames['tags'].indexOf(tag);
      charIndexWithTags[tag] = [];
      for (var charIndex = 0; charIndex < characterTags.length; charIndex++) {
        var char = characterTags[charIndex];
        if (char['available'] == false) continue;
        if (char['overall_tags'].contains(tagIndex)) {
          charIndexWithTags[tag].add(charIndex);
        }
      }
      charIndexWithTags[tag] = charIndexWithTags[tag].toSet();
    }

    tagSet = characterNames['tags'].toSet();
  }

  Future<List> getTagsFromScreenshot(String screenshotBase64) async {
    // Decode the screenshot
    final screenshotBytes = const Base64Decoder().convert(screenshotBase64);
    final screenshot = img.decodeImage(screenshotBytes);

    // Crop the image
    final cropped = img.copyCrop(screenshot!, 
                          x: 0, y: (screenshot.height*0.3).round(), 
                          width: (screenshot.width / 2).floor() * 2, height: (screenshot.height*0.2 / 2).floor() * 2);

    // Convert screenshot to NV21
    final screenshotNV21 = convertRGBtoNV21(
        cropped.getBytes(order: img.ChannelOrder.bgr),
        cropped.width,
        cropped.height);

    // Create input image
    final imageSize =
        Size(cropped.width.toDouble(), cropped.height.toDouble());
    final imageRotation = InputImageRotationValue.fromRawValue(0);
    const inputImageFormat = InputImageFormat.nv21;

    final inputImage = InputImage.fromBytes(
        bytes: screenshotNV21,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation!,
          format: inputImageFormat,
          bytesPerRow: 0,
        ));

    // OCR
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.chinese);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    var texts = recognizedText.blocks
        .expand((block) => block.lines)
        .expand((line) => line.elements)
        .map((element) => element.text)
        .toList();
    textRecognizer.close();

    print('Original texts: $texts');

    // Fix chinese characters
    for (var i = 0; i < texts.length; i++) {
      for (var key in chineseFixDict.keys) {
        texts[i] = texts[i].replaceAll(key, chineseFixDict[key]!);
      }
      // remove continuous duplicated characters
      texts[i] = texts[i].replaceAllMapped(RegExp(r'(\S)\1{2,}'), (match) => match.group(1)!);
    }
    print(texts);

    // Filter out tags
    var (foundTags, candiateTags, remainingTags) = filterTags(texts);
    print('Found tags: $foundTags');
    print('Remaining tags: $remainingTags');

    // Find the remaining tags
    while (foundTags.length < 5){
      var bestMatchTag = await findTagBestMatch(candiateTags, remainingTags);
      if (bestMatchTag == '') break;
      foundTags.add(bestMatchTag);
    }

    return foundTags;
  }

  (List<String>, List<String>, List<String>) filterTags(List<String> texts){
    var foundTags = texts.where((text) => tagSet.contains(text)).toList();
    var candiateTags = texts.where((text) => !tagSet.contains(text)).toList();
    var remainingTags = tagSet.difference(foundTags.toSet()).toList();

    return (foundTags, candiateTags, remainingTags.cast<String>());
  }

  Future<double> chineseDistance(String a, String b) async {
    final similarity = await const MethodChannel('channel_screenshot').invokeMethod<double>('chineseSimilarity', <String, String>{'a': a[0], 'b': b[0]});
    return 1 - similarity!;
  }

  Future<double> editDistance(String a, String b) async {
    // edit cost `chineseDistance`

    // dp array as 2D list of double
    var dp = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0.0));
    for (var i = 0; i <= a.length; i++) {
      for (var j = 0; j <= b.length; j++) {
        if (i == 0) {
          dp[i][j] = j.toDouble();
        } else if (j == 0) {
          dp[i][j] = i.toDouble();
        } else if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = math.min(
            math.min(
              dp[i - 1][j] + 1,
              dp[i][j - 1] + 1,
            ),
            dp[i - 1][j - 1] + await chineseDistance(a[i - 1], b[j - 1]),
          ) ;
        }
      }
    }
    return dp[a.length][b.length];
  }

  Future<String> findTagBestMatch(List texts, List tags) async {
    var minIndexTag = 0;
    var minIndexText = 0;
    var minDistance = 99999.0;
    for (var i = 0; i < tags.length; i++) {
      double md = 99999.0;
      var minIndex = 0;
      for (var j = 0; j < texts.length; j++) {
        var distance = 99999.0;
        if (chineseDistanceCache.containsKey(tags[i] + texts[j])) {
          distance = chineseDistanceCache[tags[i] + texts[j]]!;
        } else {
          distance = chineseDistanceCache[tags[i] + texts[j]] = await editDistance(tags[i], texts[j]);
        }
        if (distance < md) {
          md = distance;
          minIndex = j;
        }
      }
      if (md < minDistance) {
        minDistance = md;
        minIndexTag = i;
        minIndexText = minIndex;
      }
    }

    if (minDistance > 2) return ''; // no good match

    // remove the found tag from the candidate tags
    texts.removeAt(minIndexText);
    return tags[minIndexTag];
  }

  (String, List) getRecommendedCharacters(List foundTagStrings) {
    bool allElite(charIndices) {
      for (var charIndex in charIndices) {
        if (characterTags[charIndex]['tags']['rank'] != 19) {
          return false;
        }
      }
      return true;
    }
    if (foundTagStrings.isEmpty) {
      return ('', []);
    }

    // get recommended characters
    for (var nComb = 1; nComb <= math.min(3, foundTagStrings.length); nComb++) {
      for (final comb in Combinations(nComb, foundTagStrings)()) {
        var intersect = charIndexWithTags[comb[0]];
        for (var i = 1; i < comb.length; i++) {
          intersect = intersect.intersection(charIndexWithTags[comb[i]]);
        }
        if (intersect.length > 0 && allElite(intersect)) {
          return (
            characterNames['name'][characterTags[intersect.first]['id']],
            comb
          );
        }
      }
    }
    return ('', []);
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
          message: hasStarted ? '助手泡泡已開啟！' : '請再試一次！',
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class LocalNotificationService {
  Future<void> init() async {
    // Initialize native android notification
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize native Ios Notifications
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    WidgetsFlutterBinding.ensureInitialized();
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) async {
        await launchUrl(Uri.parse(
            'https://purindaisuki.github.io/tkfmtools/enlist/filter/'));
      },
    );
  }

  void showNotificationAndroid(String title, String value) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('channel_id', 'Channel Name',
            channelDescription: 'Channel Description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    int notificationId = 1;
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
        notificationId, title, value, notificationDetails,
        payload: 'Not present');
  }
}
