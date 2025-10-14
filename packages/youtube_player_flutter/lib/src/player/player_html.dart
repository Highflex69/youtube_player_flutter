import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlayerHtml {
  final YoutubePlayerController controller;

  const PlayerHtml({required this.controller});

  String get player {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        $_headSection
    </head>
    <body>
        <div id="player"></div>
        <script>            
            $_scriptSection
        </script>
    </body>
    </html>
  ''';
  }

  String get _headSection => '''
    <style>
            html,
            body {
                margin: 0;
                padding: 0;
                background-color: #000000;
                overflow: hidden;
                position: fixed;
                height: 100%;
                width: 100%;
                pointer-events: none;
            }
             $_hideOverlayHeadSection
        </style>
        <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
    ''';

  String get _scriptSection => '''
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
    var player;
    var timerId;
            
    function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    height: '100%',
                    width: '100%',
                    videoId: '${controller.initialVideoId}',
                    playerVars: {
                        'controls': 0,
                        'playsinline': 1,
                        'enablejsapi': 1,
                        'fs': 0,
                        'rel': 0,
                        'showinfo': 0,
                        'iv_load_policy': 3,
                        'modestbranding': 1,
                        'cc_load_policy': ${_booleanConverter(value: controller.flags.enableCaption)},
                        'cc_lang_pref': '${controller.flags.captionLanguage}',
                        'autoplay': ${_booleanConverter(value: controller.flags.autoPlay)},
                        'start': ${controller.flags.startAt},
                        'end': ${controller.flags.endAt}
                    },
                    events: {
                        onReady: function(event) { 
                            window.flutter_inappwebview.callHandler('Ready');
                            $_hideOverlayBodySection
                        },
                        onStateChange: function(event) { sendPlayerStateChange(event.data); },
                        onPlaybackQualityChange: function(event) { window.flutter_inappwebview.callHandler('PlaybackQualityChange', event.data); },
                        onPlaybackRateChange: function(event) { window.flutter_inappwebview.callHandler('PlaybackRateChange', event.data); },
                        onError: function(error) { window.flutter_inappwebview.callHandler('Errors', error.data); }
                    },
                });
            }

            function sendPlayerStateChange(playerState) {
                clearTimeout(timerId);
                window.flutter_inappwebview.callHandler('StateChange', playerState);
                if (playerState == 1) {
                    startSendCurrentTimeInterval();
                    sendVideoData(player);
                }
            }

            function sendVideoData(player) {
                var videoData = {
                    'duration': player.getDuration(),
                    'title': player.getVideoData().title,
                    'author': player.getVideoData().author,
                    'videoId': player.getVideoData().video_id
                };
                window.flutter_inappwebview.callHandler('VideoData', videoData);
            }

            function startSendCurrentTimeInterval() {
                timerId = setInterval(function () {
                    window.flutter_inappwebview.callHandler('VideoTime', player.getCurrentTime(), player.getVideoLoadedFraction());
                }, 100);
            }

            function play() {
                player.playVideo();
                return '';
            }

            function pause() {
                player.pauseVideo();
                return '';
            }

            function loadById(loadSettings) {
                player.loadVideoById(loadSettings);
                return '';
            }

            function cueById(cueSettings) {
                player.cueVideoById(cueSettings);
                return '';
            }

            function loadPlaylist(playlist, index, startAt) {
                player.loadPlaylist(playlist, 'playlist', index, startAt);
                return '';
            }

            function cuePlaylist(playlist, index, startAt) {
                player.cuePlaylist(playlist, 'playlist', index, startAt);
                return '';
            }

            function mute() {
                player.mute();
                return '';
            }

            function unMute() {
                player.unMute();
                return '';
            }
            
            function toggleCaptions() {
                var track = player.getOption('captions', 'track');
                if (track && track.languageCode) {
                    player.unloadModule('captions');
                } else {
                    player.loadModule('captions');
                    player.setOption('captions', 'track', {});
                }
                return '';
            }
            function showCaptions() {
                player.loadModule('captions');
                player.setOption('captions', 'track', {
                    languageCode: 'en' // ensure this is defined
                });
                return '';
            }
            function hideCaptions() {
                player.unloadModule('captions');
                return '';
            }

            function setVolume(volume) {
                player.setVolume(volume);
                return '';
            }

            function seekTo(position, seekAhead) {
                player.seekTo(position, seekAhead);
                return '';
            }

            function setSize(width, height) {
                player.setSize(width, height);
                return '';
            }

            function setPlaybackRate(rate) {
                player.setPlaybackRate(rate);
                return '';
            }

            function setTopMargin(margin) {
                document.getElementById("player").style.marginTop = margin;
                return '';
            }
    ''';

  String get _hideOverlayBodySection => controller.flags.hideYoutubeOverlay
      ? '''
            // Additional JavaScript to hide overlay elements
            function hideOverlayElements() {
                var iframe = document.querySelector('iframe');
                if (iframe && iframe.contentDocument) {
                    var style = iframe.contentDocument.createElement('style');
                   style.textContent = `
                        .ytp-title, .ytp-chrome-top, .ytp-show-cards-title,
                        .ytp-title-text, .ytp-title-link, .ytp-title-expanded-overlay,
                        .ytp-gradient-top, .ytp-videowall-still, .ytp-ce-element,
                        .ytp-cards-teaser, .iv-branding, .ytp-pause-overlay {
                            display: none !important;
                            visibility: hidden !important;
                            opacity: 0 !important;
                        }
                    `;
                    iframe.contentDocument.head.appendChild(style);
                }
            }
            setTimeout(hideOverlayElements, 1000);
            setInterval(hideOverlayElements, 2000);
          '''
      : '';

  String get _hideOverlayHeadSection => controller.flags.hideYoutubeOverlay
      ? '''
            /* Hide YouTube overlay elements */
            .ytp-title,
            .ytp-chrome-top,
            .ytp-show-cards-title,
            .ytp-title-text,
            .ytp-title-link,
            .ytp-title-expanded-overlay,
            .ytp-gradient-top,
            .ytp-videowall-still,
            .ytp-ce-element,
            .ytp-cards-teaser,
            .iv-branding,
            .ytp-pause-overlay {
                display: none !important;
                visibility: hidden !important;
                opacity: 0 !important;
            }
            
            /* Hide the top gradient overlay */
            .ytp-gradient-top {
                background: none !important;
            }
            '''
      : '';

  String _booleanConverter({required bool value}) =>
      value == true ? "'1'" : "'0'";

  String get userAgent => controller.flags.forceHD
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : '';
}
