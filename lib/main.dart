import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

const rtcAppId =
    '59535f1fe3e64f3b864ae7a55bbd3196'; //------------ Need DIY -------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SenseTime Extension Example'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final RtcEngine _rtcEngine;
  late final RtcEngineEventHandler _rtcEngineEventHandler;

  bool _isReadyPreview = false;
  bool _enableExtension = true;
  bool _enableSticker = false;
  int rtcEnginebuild = 0;

  String rtcEngineVersion = 'None';

  Future<String> _copyAsset(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    Directory appDocDir = await getApplicationDocumentsDirectory();

    final dirname = path.dirname(assetPath);

    Directory dstDir = Directory(path.join(appDocDir.path, dirname));
    if (!(await dstDir.exists())) {
      await dstDir.create(recursive: true);
    }

    String p = path.join(appDocDir.path, path.basename(assetPath));
    final file = File(p);
    if (!(await file.exists())) {
      await file.create();
      await file.writeAsBytes(bytes);
    }

    return file.absolute.path;
  }

  Future<void> _requestPermissionIfNeed() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
  }

  Future<void> _init() async {
    await _requestPermissionIfNeed();
    _rtcEngine = createAgoraRtcEngine();
    await _rtcEngine.initialize(const RtcEngineContext(
      appId: rtcAppId,
      logConfig: LogConfig(level: LogLevel.logLevelInfo),
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _rtcEngineEventHandler = RtcEngineEventHandler(
      onExtensionEvent: (provider, extension, key, value) {
        debugPrint(
            '[onExtensionEvent] provider: $provider, extension: $extension, key: $key, value: $value');
      },
      onExtensionStarted: (provider, extension) {
        debugPrint(
            '[onExtensionStarted] provider: $provider, extension: $extension');
        if (provider == 'SenseTime' && extension == 'Effect') {
          _initSTExtension();
        }
      },
      onExtensionError: (provider, extension, error, message) {
        debugPrint(
            '[onExtensionError] provider: $provider, extension: $extension, error: $error, message: $message');
      },
    );
    _rtcEngine.registerEventHandler(_rtcEngineEventHandler);
    await _loadVersion();

    await _rtcEngine.enableExtension(
        provider: "SenseTime", extension: "Effect", enable: _enableExtension);

    await _rtcEngine.enableVideo();
    await _rtcEngine.startPreview();

    setState(() {
      _isReadyPreview = true;
    });
  }

  Future<void> _loadVersion() async {
    var sdkversion = await _rtcEngine.getVersion();
    rtcEngineVersion = sdkversion.version ?? 'None';
    rtcEnginebuild = sdkversion.build ?? 0;
  }

  Future<void> _loadAIModels() async {
    final bundleRealPath = await _copyAsset(
        'Resource/models/M_SenseME_Face_Video_Template_p_3.9.0.3.model');
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_human_action_create',
        value: jsonEncode({'model_path': bundleRealPath, 'config': 255}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_create_handle',
        value: jsonEncode({}));
  }

  Future<void> _enableStickerEffect(String stickerPath) async {
    final stickerRealPath = await _copyAsset(stickerPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_add_package',
        value: jsonEncode({'path': stickerRealPath}));
  }

  Future<void> _disableStickerEffect(String stickerPath) async {
    final stickerRealPath = await _copyAsset(stickerPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_remove_package',
        value: jsonEncode({'path': stickerRealPath}));
  }

  Future<void> _initSTExtension() async {
    final bundleRealPath =
        await _copyAsset('Resource/license/SenseMARS_Effects.lic');
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_check_activecode',
        value: jsonEncode({'license_path': bundleRealPath}));

    _loadAIModels();
  }

  Future<void> _dispose() async {
    _rtcEngine.unregisterEventHandler(_rtcEngineEventHandler);
    await _rtcEngine.release();
  }

  @override
  void initState() {
    super.initState();

    _init();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReadyPreview) {
      return Container();
    }

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        AgoraVideoView(
            controller: VideoViewController(
          rtcEngine: _rtcEngine,
          canvas: const VideoCanvas(uid: 0),
        )),
        Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(flex: 1, child: Container()),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Agora RTC SDK: $rtcEngineVersion($rtcEnginebuild)',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  onPressed: () async {
                    setState(() {
                      _enableExtension = !_enableExtension;
                    });

                    await _rtcEngine.enableExtension(
                        provider: "SenseTime",
                        extension: "Effect",
                        enable: _enableExtension);
                  },
                  child: Text(_enableExtension
                      ? 'disableExtension'
                      : 'enableExtension'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.cyan),
                  onPressed: () async {
                    setState(() {
                      _enableSticker = !_enableSticker;
                    });

                    if (_enableSticker) {
                      _enableStickerEffect('Resource/stickers/AiXin.zip');
                    } else {
                      _disableStickerEffect('Resource/stickers/AiXin.zip');
                    }
                  },
                  child:
                      Text(_enableSticker ? 'disableSticker' : 'enableSticker'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
