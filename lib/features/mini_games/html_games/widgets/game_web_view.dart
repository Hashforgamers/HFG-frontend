import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/html_games/services/html_game_asset_server.dart';
import 'package:hash/features/mini_games/html_games/services/html_game_score_bridge_service.dart';
import 'package:hash/features/mini_games/html_games/super_over_analytics.dart';

enum _WebViewStatusTone { info, success, error }

class GameWebView extends StatefulWidget {
  const GameWebView({
    super.key,
    required this.game,
    required this.scoreBridgeService,
  });

  final HtmlMiniGame game;
  final HtmlGameScoreBridgeService scoreBridgeService;

  @override
  State<GameWebView> createState() => _GameWebViewState();
}

class _GameWebViewState extends State<GameWebView> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  String? _statusMessage;
  Timer? _statusTimer;
  _WebViewStatusTone _statusTone = _WebViewStatusTone.info;

  @override
  void dispose() {
    _statusTimer?.cancel();
    _controller?.removeJavaScriptHandler(handlerName: 'gameScore');
    _controller?.removeJavaScriptHandler(handlerName: 'haptic');
    _controller?.removeJavaScriptHandler(handlerName: 'share');
    _controller?.removeJavaScriptHandler(handlerName: 'shareVideo');
    _controller?.removeJavaScriptHandler(handlerName: 'analytics');
    super.dispose();
  }

  Future<void> _reloadGame() async {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _loadError = null;
      _isLoading = true;
    });

    await _loadGameContent(controller);
  }

  Future<void> _loadGameContent(InAppWebViewController controller) async {
    try {
      if (widget.game.isRemoteUrl) {
        await controller.loadUrl(
          urlRequest: URLRequest(url: WebUri(widget.game.gameUrl)),
        );
        return;
      }

      // Prefer the bundled-asset server: relative scripts/models resolve and the
      // game works offline. Fall back to inlining the HTML if it can't start.
      try {
        final url = await HtmlGameAssetServer.instance.urlFor(
          widget.game.gameUrl,
        );
        await controller.loadUrl(
          urlRequest: URLRequest(url: WebUri(url.toString())),
        );
        return;
      } catch (_) {}

      final html = await rootBundle.loadString(widget.game.gameUrl);
      await controller.loadData(
        data: html,
        mimeType: 'text/html',
        encoding: 'utf8',
        baseUrl: WebUri('https://hashforgamers.local/${widget.game.gameId}/'),
        historyUrl: WebUri(
          'https://hashforgamers.local/${widget.game.gameId}/',
        ),
      );
    } catch (_) {
      _handleMainFrameError(
        'Local game asset could not be loaded. Check the bundled asset path.',
      );
    }
  }

  void _registerScoreHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'gameScore',
      callback: (arguments) async {
        if (!mounted) {
          return {'accepted': false, 'message': 'Player not mounted.'};
        }

        final payload = arguments.isNotEmpty ? arguments.first : null;
        setState(() {
          _isSubmitting = true;
          _statusMessage = 'Submitting score...';
          _statusTone = _WebViewStatusTone.info;
        });

        final result = await widget.scoreBridgeService.submitScoreFromPayload(
          game: widget.game,
          payload: payload,
        );
        _trackScoreSubmitted(payload, result);

        if (!mounted) {
          return {'accepted': result.didSubmit, 'message': result.message};
        }

        setState(() {
          _isSubmitting = false;
          _statusMessage = result.message;
          // the banner sits over the game's own HUD — let it fade after a moment
          _statusTimer?.cancel();
          _statusTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _statusMessage = null);
          });
          _statusTone = switch (result.status) {
            HtmlGameScoreSubmissionStatus.success => _WebViewStatusTone.success,
            HtmlGameScoreSubmissionStatus.duplicate => _WebViewStatusTone.info,
            HtmlGameScoreSubmissionStatus.invalidScore ||
            HtmlGameScoreSubmissionStatus.missingUser ||
            HtmlGameScoreSubmissionStatus.failed => _WebViewStatusTone.error,
          };
        });

        return {
          'accepted': result.didSubmit,
          'score': result.score,
          'message': result.message,
        };
      },
    );
  }

  void _trackScoreSubmitted(
    Object? payload,
    HtmlGameScoreSubmissionResult result,
  ) {
    if (widget.game.gameId != SuperOverAnalytics.gameId) return;
    final map = payload is Map ? payload : const {};
    final balls = map['balls'];
    final runId = map['runId'];
    SuperOverAnalytics.scoreSubmitted(
      status: result.status.name,
      score: result.score,
      ballsPlayed: balls is num ? balls.toInt() : null,
      rank: result.rank,
      previousBest: result.previousBest,
      isNewBest: result.isNewBest,
      runId: runId == null ? null : '$runId',
    );
  }

  /// Games report gameplay moments for analytics with
  /// `callHandler('analytics', { event, params })`; only Super Over's are
  /// logged, and only the events and params it whitelists.
  void _registerAnalyticsHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'analytics',
      callback: (arguments) {
        if (widget.game.gameId == SuperOverAnalytics.gameId) {
          SuperOverAnalytics.fromWeb(
            arguments.isNotEmpty ? arguments.first : null,
          );
        }
        return null;
      },
    );
  }

  /// Games ask for a tap of feedback on big moments (a wicket, a six) with
  /// `callHandler('haptic', 'light' | 'medium' | 'heavy')`.
  void _registerHapticHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'haptic',
      callback: (arguments) {
        final kind = arguments.isNotEmpty ? arguments.first : null;
        switch (kind) {
          case 'heavy':
            HapticFeedback.heavyImpact();
          case 'medium':
            HapticFeedback.mediumImpact();
          default:
            HapticFeedback.lightImpact();
        }
        return null;
      },
    );
  }

  /// Games share a result with `callHandler('share', { text, image })`, where
  /// `image` is an optional base64 PNG (a score card). Replies `{ ok: true }`
  /// once the share sheet is opening.
  void _registerShareHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'share',
      callback: (arguments) async {
        final payload = arguments.isNotEmpty ? arguments.first : null;
        if (payload is! Map) return {'ok': false};
        final text = payload['text']?.toString() ?? '';
        final image = payload['image'];
        final files = <XFile>[];
        // a 1080×1350 card is well under this; anything bigger isn't a score card
        if (image is String &&
            image.isNotEmpty &&
            image.length < 12 * 1024 * 1024) {
          try {
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/${widget.game.gameId}_share.png');
            await file.writeAsBytes(base64Decode(image), flush: true);
            files.add(XFile(file.path, mimeType: 'image/png'));
          } catch (_) {}
        }
        if (text.isEmpty && files.isEmpty) return {'ok': false};
        unawaited(
          SharePlus.instance.share(
            ShareParams(text: text, files: files.isEmpty ? null : files),
          ),
        );
        return {'ok': true};
      },
    );
  }

  /// Games share a highlight clip with
  /// `callHandler('shareVideo', { text, video, mime, name })`, where `video` is
  /// a base64 MP4/WebM. Replies `{ ok: true }` once the share sheet is opening.
  void _registerShareVideoHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'shareVideo',
      callback: (arguments) async {
        final payload = arguments.isNotEmpty ? arguments.first : null;
        if (payload is! Map) return {'ok': false};
        final video = payload['video'];
        // a 10-second 720p clip is a few MB; anything far bigger isn't a highlight
        if (video is! String ||
            video.isEmpty ||
            video.length > 64 * 1024 * 1024) {
          return {'ok': false};
        }
        final mime = payload['mime']?.toString() ?? 'video/mp4';
        final ext = mime.contains('webm') ? 'webm' : 'mp4';
        try {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${widget.game.gameId}_highlight.$ext');
          await file.writeAsBytes(base64Decode(video), flush: true);
          unawaited(
            SharePlus.instance.share(
              ShareParams(
                text: payload['text']?.toString(),
                files: [XFile(file.path, mimeType: mime)],
              ),
            ),
          );
          return {'ok': true};
        } catch (_) {
          return {'ok': false};
        }
      },
    );
  }

  void _handleMainFrameError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadError = message;
      _statusMessage = null;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InAppWebView(
            key: ValueKey('game-webview-${widget.game.gameId}'),
            initialData: InAppWebViewInitialData(
              data:
                  '<!DOCTYPE html><html><body style="margin:0;background:#000;"></body></html>',
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              supportZoom: false,
              transparentBackground: true,
              allowFileAccess: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              useHybridComposition: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              _registerScoreHandler(controller);
              _registerHapticHandler(controller);
              _registerShareHandler(controller);
              _registerShareVideoHandler(controller);
              _registerAnalyticsHandler(controller);
              unawaited(_loadGameContent(controller));
            },
            onLoadStart: (controller, url) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _loadError = null;
              });
            },
            onLoadStop: (controller, url) {
              if (!mounted) return;
              setState(() => _isLoading = false);
            },
            onProgressChanged: (controller, progress) {
              if (!mounted) return;
              if (progress >= 100) {
                setState(() => _isLoading = false);
              }
            },
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame ?? true) {
                _handleMainFrameError(
                  error.description.isEmpty
                      ? 'Could not load the game.'
                      : error.description,
                );
              }
            },
            onReceivedHttpError: (controller, request, response) {
              if (request.isForMainFrame ?? true) {
                _handleMainFrameError(
                  'Game failed to load (${response.statusCode}).',
                );
              }
            },
          ),
        ),
        if (_loadError != null)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF050505),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFF7A7A),
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _reloadGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB554),
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_statusMessage != null)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _StatusBanner(message: _statusMessage!, tone: _statusTone),
          ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xA6000000),
              child: Center(child: AppLinearLoader.screen()),
            ),
          ),
        if (_isSubmitting)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const AppLinearLoader(width: 30, height: 3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Submitting score...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.tone});

  final String message;
  final _WebViewStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      _WebViewStatusTone.success => (
        const Color(0xFF0F2A1A).withValues(alpha: 0.96),
        const Color(0xFF79E2A0),
        Icons.check_circle_outline_rounded,
      ),
      _WebViewStatusTone.error => (
        const Color(0xFF311414).withValues(alpha: 0.96),
        const Color(0xFFFF9B9B),
        Icons.error_outline_rounded,
      ),
      _ => (
        const Color(0xFF161616).withValues(alpha: 0.96),
        const Color(0xFFFFD27E),
        Icons.info_outline_rounded,
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
