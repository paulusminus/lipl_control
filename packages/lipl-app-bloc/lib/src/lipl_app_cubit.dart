import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:lipl_model/lipl_model.dart';
import 'package:loading_status/loading_status.dart';
import 'lipl_rest_api.dart';

class LiplAppState extends Equatable {
  const LiplAppState({
    required this.lyrics,
    required this.playlists,
    required this.status,
    required this.credentials,
  });

  factory LiplAppState.initial() => const LiplAppState(
        lyrics: [],
        playlists: [],
        status: LoadingStatus.initial,
        credentials: null,
      );

  final List<Lyric> lyrics;
  final List<Playlist> playlists;
  final LoadingStatus status;
  final Credentials? credentials;

  LiplAppState copyWith({
    List<Lyric>? lyrics,
    List<Playlist>? playlists,
    LoadingStatus? status,
    Credentials? credentials,
  }) =>
      LiplAppState(
        lyrics: lyrics ?? this.lyrics,
        playlists: playlists ?? this.playlists,
        status: status ?? this.status,
        credentials: credentials ?? this.credentials,
      );

  @override
  List<Object?> get props => [lyrics, playlists, status, credentials];
}

class LiplAppCubit extends Cubit<LiplAppState> {
  LiplAppCubit({required this.credentialsStream, LiplRestApiInterface? api})
      : super(LiplAppState.initial()) {
    _api = api;
    _subscription = credentialsStream.listen((credentials) {
      emit(state.copyWith(credentials: credentials));
      load();
    });
  }

  late StreamSubscription<Credentials?> _subscription;
  late LiplRestApiInterface? _api;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }

  Stream<Credentials?> credentialsStream;

  Stream<List<Lyric>> get lyricsStream => stream
      .where((state) => state.status == LoadingStatus.success)
      .map((state) => state.lyrics)
      .distinct();

  Stream<List<Playlist>> get playlistsStream => stream
      .where((state) => state.status == LoadingStatus.success)
      .map((state) => state.playlists);

  @override
  void onError(Object error, StackTrace stackTrace) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        emit(state.copyWith(status: LoadingStatus.unauthorized));
      }
    }
    super.onError(error, stackTrace);
  }

  Future<void> _runAsync(Future<void> Function() runnable) async {
    try {
      await runnable();
    } catch (error) {
      addError(error);
    }
  }

  Future<void> load() => _runAsync(() async {
        emit(
          state.copyWith(
            status: LoadingStatus.loading,
          ),
        );
        List<Lyric> lyrics = [];
        List<Playlist> playlists = [];
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        await Future.wait<void>(
          [
            api.getLyrics().then((value) {
              lyrics = value;
            }),
            api.getPlaylists().then((value) {
              playlists = value;
            }),
          ],
        );
        emit(
          state.copyWith(
            lyrics: lyrics.sortByTitle(),
            playlists: playlists.sortByTitle(),
            status: LoadingStatus.success,
          ),
        );
      });

  Future<void> postLyric(LyricPost lyricPost) => _runAsync(() async {
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        emit(state.copyWith(status: LoadingStatus.changing));
        final lyric = await api.postLyric(lyricPost);
        emit(
          state.copyWith(
            lyrics: state.lyrics.addItem(lyric),
            status: LoadingStatus.success,
          ),
        );
      });

  Future<void> putLyric(Lyric lyric) => _runAsync(() async {
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        emit(state.copyWith(status: LoadingStatus.changing));
        final Lyric returnedLyric = await api.putLyric(lyric.id, lyric);
        emit(
          state.copyWith(
            lyrics: state.lyrics.replaceItem(returnedLyric),
            status: LoadingStatus.success,
          ),
        );
      });

  Future<void> deleteLyric(String id) => _runAsync(() async {
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        emit(state.copyWith(status: LoadingStatus.changing));
        await api.deleteLyric(id);
        emit(
          state.copyWith(
            lyrics: state.lyrics.removeItemById(id),
            playlists: state.playlists
                .map((Playlist p) => p.withoutMember(id))
                .toList(),
            status: LoadingStatus.success,
          ),
        );
      });

  Future<void> postPlaylist(PlaylistPost playlistPost) => _runAsync(() async {
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        emit(state.copyWith(status: LoadingStatus.changing));
        final playlist = await api.postPlaylist(playlistPost);
        emit(
          state.copyWith(
            playlists: state.playlists.addItem(playlist),
            status: LoadingStatus.success,
          ),
        );
      });

  Future<void> putPlaylist(Playlist playlist) => _runAsync(() async {
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        emit(state.copyWith(status: LoadingStatus.changing));
        final Playlist playlistReturned =
            await api.putPlaylist(playlist.id, playlist);
        emit(
          state.copyWith(
            playlists: state.playlists.replaceItem(playlistReturned),
            status: LoadingStatus.success,
          ),
        );
      });

  Future<void> deletePlaylist(String id) => _runAsync(() async {
        final api = _api ?? apiFromConfig(credentials: state.credentials);
        emit(state.copyWith(status: LoadingStatus.changing));
        await api.deletePlaylist(id);
        emit(
          state.copyWith(
            playlists: state.playlists.removeItemById(id),
            status: LoadingStatus.success,
          ),
        );
      });
}
