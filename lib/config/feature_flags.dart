/// App-wide feature switches, compiled into the build.
abstract final class FeatureFlags {
  /// Tournaments, the host program and tournament invites.
  ///
  /// Off while the Google Play "Real-Money Gambling, Games and Contests"
  /// policy issue is resolved: cash prize pools and host earnings are not
  /// allowed in the Play build. When off, every tournament entry point is
  /// hidden (home sections, the Tournaments tab, player invites, chat and
  /// deep links). The feature code stays in place for re-enabling.
  static const bool tournamentsEnabled = true;
}
