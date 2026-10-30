import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/live/utils/live_youtube_utils.dart';

void main() {
  const id = 'dQw4w9WgXcQ';

  test('accepts YouTube live, watch and short links', () {
    for (final url in [
      'https://www.youtube.com/live/$id?si=abc',
      'youtube.com/live/$id',
      'https://m.youtube.com/watch?v=$id&feature=share',
      'https://youtu.be/$id',
    ]) {
      expect(LiveYoutubeUtils.extractVideoId(url), id, reason: url);
    }
    expect(
      LiveYoutubeUtils.canonicalUrl('https://youtu.be/$id?t=4'),
      'https://www.youtube.com/live/$id',
    );
  });

  test('rejects anything that is not a YouTube video link', () {
    for (final url in [
      '',
      'https://instagram.com/p/$id',
      'https://evil.com/watch?v=$id',
      'https://youtube.com.evil.com/live/$id',
      'https://notyoutube.com/live/$id',
      'https://www.youtube.com/@somechannel/live',
      'https://www.youtube.com/shorts/$id',
      'https://www.youtube.com/watch?v=short',
      'javascript:alert(1)//youtu.be/$id',
      'check this $id',
      id,
    ]) {
      expect(LiveYoutubeUtils.isSupportedUrl(url), isFalse, reason: url);
    }
  });
}
