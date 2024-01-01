import 'dart:io';
import 'package:lipl_model/lipl_model.dart';
import 'package:lipl_app_bloc/lipl_app_bloc.dart';
import 'package:loading_status/loading_status.dart';
import 'package:path/path.dart' as p;

const String path = '/home/paul/Documenten/lipl.data/Geheugenkoor/';
const Credentials? credentials = null;

bool isSuccess(LiplAppState state) => state.status == LoadingStatus.success;

Future<LyricPost> fromFile(File file) async {
  final String title = p.basenameWithoutExtension(file.path);
  final text = await file.readAsString();
  return LyricPost(
    title: title,
    parts: text.toParts(),
  );
}

Future<void> main() async {
  final LiplAppCubit cubit =
      LiplAppCubit(credentialsStream: const Stream.empty(), isWeb: false);
  await cubit.load();

  Future<Lyric> postLyric(File file) async {
    final lyricPost = await fromFile(file);
    await cubit.postLyric(lyricPost);
    final Lyric lyric = cubit.state.lyrics.firstWhere(
      (Lyric lyric) => lyric.title == lyricPost.title,
    );
    return lyric;
  }

  final List<Lyric> lyrics = await Directory(path)
      .list()
      .where(
        (FileSystemEntity entity) => entity is File,
      )
      .map(
        (FileSystemEntity entity) => entity as File,
      )
      .where(
        (File file) => p.extension(file.path).toLowerCase() == '.txt',
      )
      .asyncMap(postLyric)
      .toList();

  final PlaylistPost playlistPost = PlaylistPost(
    title: 'Alles',
    members: lyrics.map((Lyric lyric) => lyric.id).toList(),
  );

  await cubit.postPlaylist(playlistPost);

  await cubit.close();
}
