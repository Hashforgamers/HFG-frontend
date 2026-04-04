import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/html_games/services/html_game_score_bridge_service.dart';

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
  _WebViewStatusTone _statusTone = _WebViewStatusTone.info;

  @override
  void dispose() {
    _controller?.removeJavaScriptHandler(handlerName: 'gameScore');
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

        if (!mounted) {
          return {'accepted': result.didSubmit, 'message': result.message};
        }

        setState(() {
          _isSubmitting = false;
          _statusMessage = result.message;
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
              child: Center(child: CircularProgressIndicator()),
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
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
