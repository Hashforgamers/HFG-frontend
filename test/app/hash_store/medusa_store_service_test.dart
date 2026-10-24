import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';

String _jwt(Map<String, dynamic> payload) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(payload)}.sig';
}

void main() {
  group('actorIdOf', () {
    test('empty actor means first use', () {
      expect(MedusaStoreService.actorIdOf(_jwt({'actor_id': ''})), '');
    });

    test('linked token returns the customer id', () {
      expect(
        MedusaStoreService.actorIdOf(_jwt({'actor_id': 'cus_123'})),
        'cus_123',
      );
    });

    test('garbage is treated as unlinked', () {
      expect(MedusaStoreService.actorIdOf('not-a-jwt'), '');
      expect(MedusaStoreService.actorIdOf('a.%%%.c'), '');
    });
  });

  test('StoreException prefers the server message', () {
    final options = RequestOptions(path: '/x');
    final e = StoreException.from(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 429,
          data: {'message': 'Wait 60 seconds before requesting a new code.'},
        ),
      ),
    );
    expect(e.message, 'Wait 60 seconds before requesting a new code.');
    expect(e.statusCode, 429);
    expect(e.isTimeout, isFalse);
  });
}
