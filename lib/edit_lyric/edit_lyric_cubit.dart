import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lipl_model/lipl_model.dart';
import 'package:loading_status/loading_status.dart';

part 'edit_lyric_cubit.freezed.dart';

@freezed
class EditLyricState with _$EditLyricState {
  const EditLyricState._();
  const factory EditLyricState({
    @Default(true) bool isNew,
    @Default(LoadingStatus.initial) LoadingStatus status,
    @Default(null) String? id,
    @Default('') String title,
    @Default('') String text,
  }) = _EditLyricState;
}

class EditLyricCubit extends Cubit<EditLyricState> {
  EditLyricCubit({
    Lyric? lyric,
  }) : super(
          EditLyricState(
            isNew: lyric?.id == null,
            id: lyric?.id ?? newId(),
            title: lyric?.title ?? '',
            text: lyric?.parts.toText() ?? '',
          ),
        );

  void submitted() {
    emit(state.copyWith(status: LoadingStatus.success));
  }

  void titleChanged(String title) {
    emit(state.copyWith(title: title));
  }

  void textChanged(String text) {
    emit(state.copyWith(text: text));
  }
}
