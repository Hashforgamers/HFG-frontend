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

  test('catalog sends the category; states are cached and retried', () async {
    final calls = <String>[];
    var fail = true;
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      calls.add('$p ${q ?? {}}');
      if (p == '/hash-store/locations') {
        if (fail) throw const StoreException('offline');
        return {
          'state_required': true,
          'states': [
            {'code': 'MH', 'name': 'Maharashtra'},
            {'code': 'X'},
          ],
        };
      }
      return {'products': [], 'count': 0};
    });
    await service.catalog(categoryId: 'pcat_1');
    expect(calls.single, contains('category_id: pcat_1'));

    await expectLater(service.states('in'), throwsA(isA<StoreException>()));
    fail = false;
    final states = await service.states('in');
    await service.states('in');
    expect(states.required, isTrue);
    expect(states.list.map((s) => s.name), ['Maharashtra']);
    expect(calls.where((c) => c.startsWith('/hash-store')).length, 2);
  });
}
