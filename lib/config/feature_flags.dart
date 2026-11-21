import 'package:hash/core/service/app_remote_config.dart';

/// App-wide feature switches.
abstract final class FeatureFlags {
  /// Tournaments, the host program and tournament invites.
  ///
  /// Controlled remotely: Firebase Remote Config key `tournaments_enabled`,
  /// switched from Push Studio. Defaults to off because cash prize pools and
  /// host earnings conflict with the Google Play "Real-Money Gambling, Games
  /// and Contests" policy. When off, every tournament entry point is hidden
  /// (home sections, the Tournaments tab, player invites, chat, deep links).
  static bool get tournamentsEnabled => AppRemoteConfig.tournamentsEnabled;
}
