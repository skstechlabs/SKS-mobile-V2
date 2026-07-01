import 'package:flutter/foundation.dart';

/// Global notifier that tracks whether NowPlayingScreen is currently visible.
///
/// NowPlayingScreen sets this to true in initState and false in dispose.
/// MiniAudioPlayer (and any other widget) listens to this and hides itself
/// when the full-screen player is open — prevents showing two sets of controls.
///
/// This works regardless of how NowPlayingScreen is pushed:
///   - from MiniAudioPlayer (via Navigator.push)
///   - from AllSongsPage
///   - from HomePage bhajan cards
///   - from any future entry point
final nowPlayingVisible = ValueNotifier<bool>(false);
