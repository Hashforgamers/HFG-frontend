import 'dart:io' show Platform;

class AppKeys {
  static const String rawgApiKey = '5161e75d1d234431ac34d3947d01ea1e';
  static const String gameSpotApiKey = '...';
  static const String _androidGoogleMapsApiKey =
      'AIzaSyAIeaszJ60ZcjL9hNYpsQ_JD8w8J2vnmuQ';
  static const String _iosGoogleMapsApiKey =
      'AIzaSyDjaI5XOoq4r0AbJVfDSz9tiQqLGBC_yNU';
  static String get googleMapsApiKey =>
      Platform.isAndroid ? _androidGoogleMapsApiKey : _iosGoogleMapsApiKey;
  static String get googlePlacesApiKey => googleMapsApiKey;
  static const String fruitNinjaSecretKey = 'dev';

  static const List<String> newsApiKeys = <String>[
    '51a460406b4c42c49acf3b06fd7aebcb',
    '8e619f80f675482fa9d9a7428ab8a3cd',
    '25f277808858445e9ad83230a2af5c4b',
    'ce0ee2717a214c128e7bb8bce624578d',
  ];

  static const List<String> serpApiKeys = <String>[
    'ff0566d621126eb6442cc76e33807d74dde7473b9417be93dd1cbc757a6c6baf',
    '5a448e4cd243fdd57fc92a6e61c3448872c7b7d82588803889c0aa45cb96af7e',
    'f5da7e32d9509302cc38341904d9a8f80ba82d5d68789c892826a25683865628',
    'cc44766411da5696ca811b64e8ce3dc89051cb19c2e01458f7f2be9b65b3cab2',
    '1192bba44b96ef7ec567bb0bbe8efc43fdc12a91f0b0343ec11c2df3b026cd6a',
    'cb4a2ea410db5d47ff0872165bd7138201fb21ad96e75957148de122491473f2',
    '2356e63291af937037ab58415767e80c2c086b676284aeb0d1b35a16b8ada363',
  ];
}
