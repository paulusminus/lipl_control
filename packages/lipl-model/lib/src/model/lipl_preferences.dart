import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'model.dart';

part 'lipl_preferences.freezed.dart';
part 'lipl_preferences.g.dart';

@freezed
class LiplPreferences with _$LiplPreferences {
  const LiplPreferences._();
  const factory LiplPreferences({
    @Default(null) Credentials? credentials,
    @Default([]) List<Lyric> lyrics,
    @Default([]) List<Playlist> playlists,
  }) = _LiplPreferences;

  factory LiplPreferences.fromJson(Map<String, Object?> json) =>
      _$LiplPreferencesFromJson(json);

  factory LiplPreferences.deserialize(String s) =>
      LiplPreferences.fromJson(jsonDecode(s));
  String serialize() => jsonEncode(toJson());
}
