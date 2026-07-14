import 'package:flutter/foundation.dart';

/// Global notifier that tracks whether NowPlayingScreen is currently visible.
/// Set to true BEFORE the push (by openNowPlaying), false in NowPlayingScreen.dispose().
/// MiniAudioPlayer observes this and hides itself while the full-screen player is open.
final nowPlayingVisible = ValueNotifier<bool>(false);
