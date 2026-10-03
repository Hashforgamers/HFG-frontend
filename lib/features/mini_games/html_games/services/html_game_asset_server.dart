import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Serves bundled HTML games (and everything next to them: scripts, models,
/// textures) from the Flutter asset bundle over a loopback-only HTTP server.
///
/// `loadData` can't resolve relative URLs, so games with ES modules or asset
/// files load from here instead: they then work offline and load instantly.
/// Only paths under [_root] are served; it binds an ephemeral port on
/// 127.0.0.1 so nothing outside the device can reach it.
class HtmlGameAssetServer {
  HtmlGameAssetServer._();

  static final HtmlGameAssetServer instance = HtmlGameAssetServer._();

  static const _root = 'assets/html_games/';
  static const _types = <String, String>{
    'html': 'text/html; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'mjs': 'text/javascript; charset=utf-8',
    'json': 'application/json',
    'css': 'text/css; charset=utf-8',
    'glb': 'model/gltf-binary',
    'gltf': 'model/gltf+json',
    'hdr': 'application/octet-stream',
    'bin': 'application/octet-stream',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'webp': 'image/webp',
    'ktx2': 'image/ktx2',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'txt': 'text/plain; charset=utf-8',
    'md': 'text/plain; charset=utf-8',
  };

  HttpServer? _server;
  Future<Uri>? _starting;

  /// Base URL of the running server (starts it on first use).
  Future<Uri> start() => _starting ??= _bind().catchError((Object e) {
        _starting = null;
        throw e;
      });

  /// Absolute URL for a bundled asset path such as
  /// `assets/html_games/super_over/index.html`.
  Future<Uri> urlFor(String assetPath) async => (await start()).resolve(assetPath);

  Future<Uri> _bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_handle, onError: (_) {});
    return Uri.parse('http://127.0.0.1:${server.port}/');
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      var path = Uri.decodeFull(request.uri.path);
      if (path.startsWith('/')) path = path.substring(1);
      if (request.method != 'GET' ||
          !path.startsWith(_root) ||
          path.contains('..')) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final data = await rootBundle.load(path);
      final ext = path.split('.').last.toLowerCase();
      response.headers
        ..set(HttpHeaders.contentTypeHeader, _types[ext] ?? 'application/octet-stream')
        ..set(HttpHeaders.cacheControlHeader, 'max-age=3600')
        ..set('Access-Control-Allow-Origin', '*');
      response.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      response.statusCode = HttpStatus.notFound;
    } finally {
      await response.close();
    }
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _starting = null;
  }
}
