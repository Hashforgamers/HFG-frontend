import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/deeplink_service.dart';
import 'package:hash/core/service/push_router.dart';

String _uri(PushTarget t) => (t as PushDeepLink).uri.toString();

void main() {
  test('explicit deep_link wins over type', () {
    final t = PushRouter.resolve({
      'deep_link': 'hash://wallet',
      'type': 'chat',
    });
    expect(_uri(t), 'hash://wallet');
  });

  test('rematch opens the exact Ludo match', () {
    expect(
      _uri(PushRouter.resolve({'type': 'rematch', 'match_id': 'abc'})),
      'hash://game/ludomatch_abc',
    );
    expect(_uri(PushRouter.resolve({'type': 'rematch'})), 'hash://game/ludo');
  });

  test('quick match waiting push joins via the join-or-quick-match link', () {
    expect(
      _uri(
        PushRouter.resolve({'type': 'quick_match_waiting', 'match_id': 'm1'}),
      ),
      'hash://game/ludojoin_m1',
    );
  });

  test('leaderboard and wallet pushes route to their screens', () {
    expect(
      _uri(PushRouter.resolve({'type': 'leaderboard', 'rank': 3})),
      'hash://game/mini-games',
    );
    expect(_uri(PushRouter.resolve({'type': 'wallet'})), 'hash://wallet');
    expect(_uri(PushRouter.resolve({'type': 'reward'})), 'hash://wallet');
  });

  test('chat, live and inbox', () {
    expect(
      (PushRouter.resolve({'type': 'chat', 'room_id': 'r1'}) as PushChat)
          .roomId,
      'r1',
    );
    expect(
      (PushRouter.resolve({'type': 'live', 'stream_id': 's1'})
              as PushLiveStream)
          .streamId,
      's1',
    );
    final inbox = PushRouter.resolve({'type': 'new_notification'});
    expect((inbox as PushNamedRoute).route, '/notifications');
  });

  test('named route fallback, and nothing for unknown payloads', () {
    expect(
      (PushRouter.resolve({'route': '/wallet'}) as PushNamedRoute).route,
      '/wallet',
    );
    expect(PushRouter.resolve({'type': 'offer'}), isA<PushNone>());
    expect(PushRouter.resolve({}), isA<PushNone>());
  });

  test('every produced link is one DeepLinkService can route', () {
    for (final data in [
      {'type': 'rematch', 'match_id': 'abc'},
      {'type': 'quick_match_waiting', 'match_id': 'm1'},
      {'type': 'ludo'},
      {'type': 'leaderboard'},
      {'type': 'wallet'},
    ]) {
      final uri = (PushRouter.resolve(data) as PushDeepLink).uri;
      expect(DeepLinkService.parse(uri).isValid, isTrue, reason: '$uri');
    }
  });

  test('shop pushes open the order, the orders tab or the shop', () {
    expect(
      _uri(PushRouter.resolve({'type': 'store_order', 'order_id': 'order_1'})),
      'hash://shop/order/order_1',
    );
    expect(
      _uri(PushRouter.resolve({'type': 'store_review', 'reference_id': 'o2'})),
      'hash://shop/order/o2',
    );
    expect(
      _uri(PushRouter.resolve({'type': 'order_update'})),
      'hash://shop/orders',
    );
    expect(
      _uri(PushRouter.resolve({'type': 'store_promotion'})),
      'hash://shop',
    );
  });

  test('tournament feed rows open the tournament; others do not', () {
    expect(
      _uri(
        PushRouter.resolve({
          'type': 'community_registration_success',
          'reference_id': 't1',
        }),
      ),
      'hash://tournament/t1',
    );
    expect(
      PushRouter.resolve({
        'type': 'community_host_verification_payment_reference',
        'reference_id': 'x',
      }),
      isA<PushNone>(),
    );
  });
}
