import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_cubit.freezed.dart';

@freezed
class SearchState with _$SearchState {
  const SearchState._();
  const factory SearchState({
    @Default('') String searchTerm,
  }) = _SearchState;
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchState(searchTerm: ''));

  void searchChanged(String value) {
    emit(state.copyWith(searchTerm: value));
  }
}
