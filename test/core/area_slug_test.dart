import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/analytics_service.dart';

void main() {
  test('areaSlug', () {
    expect(AnalyticsService.areaSlug('Mira Road'), 'mira_road');
    expect(AnalyticsService.areaSlug(' Andheri (West) '), 'andheri_west');
    expect(AnalyticsService.areaSlug(''), '');
  });
}
