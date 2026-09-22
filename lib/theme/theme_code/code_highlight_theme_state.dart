part of 'code_highlight_theme_cubit.dart';

@freezed
abstract class CodeHighlightThemeState with _$CodeHighlightThemeState {
  const factory CodeHighlightThemeState({@Default('github') String themeName}) =
      _CodeHighlightThemeState;
}
