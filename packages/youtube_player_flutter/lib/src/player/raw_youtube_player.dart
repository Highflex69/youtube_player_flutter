// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:youtube_player_flutter/src/player/player_html.dart';

import '../enums/player_state.dart';
import '../utils/youtube_meta_data.dart';
import '../utils/youtube_player_controller.dart';

/// A raw youtube player widget which interacts with the underlying webview inorder to play YouTube videos.
///
/// Use [YoutubePlayer] instead.
class RawYoutubePlayer extends StatefulWidget {
  /// Creates a [RawYoutubePlayer] widget.
  const RawYoutubePlayer({
    super.key,
    this.onEnded,
  });

  /// {@macro youtube_player_flutter.onEnded}
  final void Function(YoutubeMetaData metaData)? onEnded;

  @override
  State<RawYoutubePlayer> createState() => _RawYoutubePlayerState();
}

class _RawYoutubePlayerState extends State<RawYoutubePlayer>
    with WidgetsBindingObserver {
  YoutubePlayerController? controller;
  PlayerState? _cachedPlayerState;
  bool _isPlayerReady = false;
  bool _onLoadStopCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cachedPlayerState != null &&
            _cachedPlayerState == PlayerState.playing) {
          controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _cachedPlayerState =
            controller?.value.playerState ?? PlayerState.paused;
        controller?.pause();
        break;
      default:
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = YoutubePlayerController.of(context);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final htmlPlayer = PlayerHtml(controller: controller!);

    return IgnorePointer(
      ignoring: true,
      child: InAppWebView(
        key: widget.key,
        initialData: InAppWebViewInitialData(
          data: htmlPlayer.player,
          encoding: 'utf-8',
          baseUrl: WebUri.uri(Uri.https('youtube-nocookie.com')),
          mimeType: 'text/html',
        ),
        initialSettings: InAppWebViewSettings(
          userAgent: htmlPlayer.userAgent,
          mediaPlaybackRequiresUserGesture: false,
          transparentBackground: true,
          disableContextMenu: true,
          supportZoom: false,
          disableHorizontalScroll: false,
          disableVerticalScroll: false,
          allowsInlineMediaPlayback: true,
          allowsAirPlayForMediaPlayback: true,
          allowsPictureInPictureMediaPlayback: true,
          useWideViewPort: false,
          useHybridComposition: controller?.flags.useHybridComposition,
        ),
        onWebViewCreated: (webController) {
          controller?.updateValue(webViewController: webController);
          webController
            ..addJavaScriptHandler(
              handlerName: 'Ready',
              callback: (_) {
                _isPlayerReady = true;
                if (_onLoadStopCalled) {
                  controller?.updateValue(isReady: true);
                }
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'StateChange',
              callback: (args) {
                PlayerState? playerState = controller?.value.playerState;
                bool? isPlaying = controller?.value.isPlaying;
                int? errorCode = controller?.value.errorCode;

                switch (args.first as int) {
                  case -1:
                    playerState = PlayerState.unStarted;
                    break;
                  case 0:
                    if (controller?.metadata != null) {
                      widget.onEnded?.call(controller!.metadata);
                    }
                    playerState = PlayerState.ended;
                    break;
                  case 1:
                    playerState = PlayerState.playing;
                    isPlaying = true;
                    errorCode = 0;
                    break;
                  case 2:
                    playerState = PlayerState.paused;
                    isPlaying = false;
                    break;
                  case 3:
                    playerState = PlayerState.buffering;
                    break;
                  case 5:
                    playerState = PlayerState.cued;
                    break;
                  default:
                    final e = Exception(
                        "Invalid player state obtained: ${args.first}");
                    debugPrint(e.toString());
                    throw e;
                }

                controller?.updateValue(
                  playerState: playerState,
                  isLoaded: playerState != PlayerState.unStarted,
                  isPlaying: isPlaying,
                  hasPlayed: playerState == PlayerState.playing,
                  errorCode: errorCode,
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'PlaybackQualityChange',
              callback: (args) {
                controller?.updateValue(playbackQuality: args.first as String);
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'PlaybackRateChange',
              callback: (args) {
                final num rate = args.first;
                controller?.updateValue(
                  playbackRate: rate.toDouble(),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'Errors',
              callback: (args) {
                final errorCode = args.first.toString();
                controller?.updateValue(
                  errorCode: int.tryParse(errorCode) ?? -1,
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoData',
              callback: (args) {
                controller?.updateValue(
                  metaData: YoutubeMetaData.fromRawData(args.first),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoTime',
              callback: (args) {
                final position = args.first * 1000;
                final num buffered = args.last;
                controller?.updateValue(
                  position: Duration(milliseconds: position.floor()),
                  buffered: buffered.toDouble(),
                );
              },
            );
        },
        onLoadStop: (_, __) {
          _onLoadStopCalled = true;
          if (_isPlayerReady && controller != null) {
            controller?.updateValue(isReady: true);
          }
        },
      ),
    );
  }
}
