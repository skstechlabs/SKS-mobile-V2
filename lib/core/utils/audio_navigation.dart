import 'package:flutter/material.dart';
import '../services/now_playing_state.dart';
import '../../features/audio/now_playing_screen.dart';

/// Opens NowPlayingScreen as a slide-up modal from any context.
///
/// Guards against double-push using [nowPlayingVisible].
/// Sets [nowPlayingVisible] to `true` **before** the push so the mini player
/// hides instantly — no orange flash before the full screen appears.
void openNowPlaying(BuildContext context) {
  if (nowPlayingVisible.value) return; // already on screen

  // Hide mini player immediately before route animation starts
  nowPlayingVisible.value = true;

  Navigator.of(context, rootNavigator: false).push(
    PageRouteBuilder(
      opaque: false,                       // allows blur/overlay effect
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => const NowPlayingScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 320),
    ),
  ).whenComplete(() {
    // Safety net — reset flag if the route was popped via gesture without
    // going through NowPlayingScreen.dispose() (e.g. predictive back).
    nowPlayingVisible.value = false;
  });
}
