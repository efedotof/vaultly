import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'code_highlight_theme_state.dart';
part 'code_highlight_theme_cubit.freezed.dart';

class CodeHighlightThemeCubit extends Cubit<CodeHighlightThemeState> {
  static const String _prefsKey = 'code_highlight_theme';
  final SharedPreferences _prefs;

  CodeHighlightThemeCubit(this._prefs)
      : super(CodeHighlightThemeState(
          themeName: _prefs.getString(_prefsKey) ?? 'github',
        ));

  Future<void> setTheme(String themeName) async {
    await _prefs.setString(_prefsKey, themeName);
    emit(state.copyWith(themeName: themeName));
  }
}