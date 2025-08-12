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
    '59535f1fe3e64f3b864ae7a55bbd3196'; //------------ Change if you need -------------
const aiModelPath =
    'Resource/models/M_SenseME_Face_Video_Template_p_4.0.0.model';
const stickerPath = 'Resource/stickers/AiXin.zip';
const lipsPath = 'Resource/makeup_lip/6自然.zip';
const eyelashPath = 'Resource/makeup_eyelash/eyelashk.zip';
const eyeshadowPath = 'Resource/makeup_eyeshadow/eyeshadowa.zip';
const licensePath = 'Resource/license/SenseMARS_Effects.lic';

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
  bool _enableBeauty = false;

  int rtcEnginebuild = 0;

  String rtcEngineVersion = 'Loading...';

  double lipsLevel = 0.99;
  double filterLevel = 0.99;

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

  Future<void> _dispose() async {
    _rtcEngine.unregisterEventHandler(_rtcEngineEventHandler);
    await _rtcEngine.release();
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
      onExtensionEventWithContext:
          (ExtensionContext context, String key, String value) {
        debugPrint(
            '[onExtensionEventWithContext] ExtensionContext: $context, key: $key, value: $value');
      },
      onExtensionStartedWithContext: (ExtensionContext context) {
        debugPrint(
            '[onExtensionStartedWithContext] ExtensionContext: $context');
        if (context.providerName == 'SenseTime' &&
            context.extensionName == 'Effect') {
          _initSTExtension();
        }
      },
      onExtensionErrorWithContext:
          (ExtensionContext context, int error, String message) {
        debugPrint(
            '[onExtensionErrorWithContext] ExtensionContext: $context, error: $error, message: $message');
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

  Future<void> _loadAIModels() async {
    final aiModelRealPath = await _copyAsset(aiModelPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_human_action_create',
        value: jsonEncode({'model_path': aiModelRealPath, 'config': 255}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_create_handle',
        value: jsonEncode({}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_human_action_detect_enable',
        value: jsonEncode({'enable': true}));
  }

  Future<void> _enableStickerEffect() async {
    final stickerRealPath = await _copyAsset(stickerPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_add_package',
        value: jsonEncode({'path': stickerRealPath}));
  }

  Future<void> _disableStickerEffect() async {
    final stickerRealPath = await _copyAsset(stickerPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_remove_package',
        value: jsonEncode({'path': stickerRealPath}));
  }

  Future<void> _enableComposer() async {
    // Find map of st_mobile_effect_set_beauty's param in STEffectBeautyType.class, in Native Demo

    final lipsRealpath = await _copyAsset(lipsPath);
    final eyelashRealPath = await _copyAsset(eyelashPath);
    final eyeshadowRealPath = await _copyAsset(eyeshadowPath);

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 402, 'path': lipsRealpath}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 408, 'path': eyelashRealPath}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 406, 'path': eyeshadowRealPath}));
  }

  Future<void> _disableComposer() async {
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 501, 'path': ''}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 402, 'path': ''}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 408, 'path': ''}));

    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty',
        value: jsonEncode({'param': 406, 'path': ''}));
  }

  Future<void> _setLipsStrength(double strenth) async {
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty_strength',
        value: jsonEncode({'param': 402, 'val': strenth}));
  }

  Future<void> _setfilterStrength(double strenth) async {
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_effect_set_beauty_strength',
        value: jsonEncode({'param': 501, 'val': strenth}));
  }

  Future<void> _initSTExtension() async {
    final licenseRealPath = await _copyAsset(licensePath);
    await _rtcEngine.setExtensionProperty(
        provider: 'SenseTime',
        extension: 'Effect',
        key: 'st_mobile_check_activecode',
        value: jsonEncode({'license_path': licenseRealPath}));

    await _loadAIModels();
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
                      _enableBeauty = !_enableBeauty;
                    });

                    if (_enableBeauty) {
                      await _enableComposer();
                    } else {
                      await _disableComposer();
                    }
                  },
                  child: Text(_enableBeauty ? 'disableBeauty' : 'enableBeauty'),
                ),
                const Text('Lips Level'),
                Slider(
                    value: lipsLevel,
                    min: 0.0,
                    max: 1.0,
                    onChanged: _enableBeauty
                        ? (double value) async {
                            setState(() {
                              lipsLevel = value;
                            });

                            _setLipsStrength(lipsLevel);
                          }
                        : null),
                const Text('Filter Level'),
                Slider(
                    value: filterLevel,
                    min: 0.0,
                    max: 1.0,
                    onChanged: _enableBeauty
                        ? (double value) async {
                            setState(() {
                              filterLevel = value;
                            });

                            _setfilterStrength(filterLevel);
                          }
                        : null),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.yellow),
                  onPressed: () async {
                    setState(() {
                      _enableSticker = !_enableSticker;
                    });

                    if (_enableSticker) {
                      await _enableStickerEffect();
                    } else {
                      await _disableStickerEffect();
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
