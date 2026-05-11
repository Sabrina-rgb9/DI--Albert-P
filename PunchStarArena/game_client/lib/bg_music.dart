import 'package:audioplayers/audioplayers.dart';

class BgMusic {
  BgMusic._();
  static final BgMusic _instance = BgMusic._();
  static BgMusic get instance => _instance;

  Future<void> play() async {}

  Future<void> stop() async {}

  Future<void> playGameplay() async {}

  Future<void> stopGameplay() async {}

  Future<void> disposePlayer() async {}
}