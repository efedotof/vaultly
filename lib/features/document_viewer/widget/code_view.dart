import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

import 'package:flutter_highlight/themes/agate.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/arta.dart';
import 'package:flutter_highlight/themes/ascetic.dart';

import 'package:flutter_highlight/themes/dark.dart';
import 'package:flutter_highlight/themes/default.dart';
import 'package:flutter_highlight/themes/docco.dart';
import 'package:flutter_highlight/themes/far.dart';
import 'package:flutter_highlight/themes/foundation.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/gml.dart';
import 'package:flutter_highlight/themes/googlecode.dart';
import 'package:flutter_highlight/themes/grayscale.dart';
import 'package:flutter_highlight/themes/hybrid.dart';
import 'package:flutter_highlight/themes/idea.dart';

import 'package:flutter_highlight/themes/lightfair.dart';
import 'package:flutter_highlight/themes/magula.dart';
import 'package:flutter_highlight/themes/monokai.dart';

import 'package:flutter_highlight/themes/nord.dart';
import 'package:flutter_highlight/themes/obsidian.dart';

import 'package:flutter_highlight/themes/pojoaque.dart';
import 'package:flutter_highlight/themes/purebasic.dart';
import 'package:flutter_highlight/themes/qtcreator_dark.dart';
import 'package:flutter_highlight/themes/qtcreator_light.dart';
import 'package:flutter_highlight/themes/rainbow.dart';
import 'package:flutter_highlight/themes/routeros.dart';

import 'package:flutter_highlight/themes/sunburst.dart';

import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/xcode.dart';
import 'package:flutter_highlight/themes/xt256.dart';
import 'package:vaulth_app/theme/theme_code/code_highlight_theme_cubit.dart';

class CodeView extends StatelessWidget {
  final Uint8List data;
  final String fileName;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onUserInteraction;

  const CodeView({
    super.key,
    required this.data,
    required this.fileName,
    required this.isFullscreen,
    this.onToggleFullscreen,
    this.onUserInteraction,
  });

  String _detectLanguage(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    const map = {
      'dart': 'dart',
      'java': 'java',
      'kt': 'kotlin',
      'kts': 'kotlin',
      'swift': 'swift',
      'c': 'c',
      'cpp': 'cpp',
      'cc': 'cpp',
      'cxx': 'cpp',
      'h': 'cpp',
      'hpp': 'cpp',
      'py': 'python',
      'js': 'javascript',
      'mjs': 'javascript',
      'ts': 'typescript',
      'jsx': 'javascript',
      'tsx': 'typescript',
      'html': 'html',
      'htm': 'html',
      'css': 'css',
      'scss': 'scss',
      'sass': 'scss',
      'less': 'less',
      'json': 'json',
      'xml': 'xml',
      'yaml': 'yaml',
      'yml': 'yaml',
      'toml': 'toml',
      'sh': 'bash',
      'bat': 'dos',
      'ps1': 'powershell',
      'go': 'go',
      'rs': 'rust',
      'rb': 'ruby',
      'php': 'php',
      'sql': 'sql',
      'r': 'r',
      'm': 'objectivec',
      'mm': 'objectivec',
      'vue': 'html',
      'svelte': 'html',
      'gradle': 'groovy',
      'properties': 'properties',
      'env': 'properties',
      'gitignore': 'git',
      'dockerignore': 'docker',
    };
    return map[ext] ?? 'plaintext';
  }

  static final Map<String, Map<String, TextStyle>> themeMap = {
    'agate': agateTheme,
    'androidstudio': androidstudioTheme,
    'arta': artaTheme,
    'ascetic': asceticTheme,
    'dark': darkTheme,
    'default': defaultTheme,
    'docco': doccoTheme,
    'far': farTheme,
    'foundation': foundationTheme,
    'github': githubTheme,
    'gml': gmlTheme,
    'googlecode': googlecodeTheme,
    'grayscale': grayscaleTheme,
    'hybrid': hybridTheme,
    'idea': ideaTheme,
    'lightfair': lightfairTheme,
    'magula': magulaTheme,
    'monokai': monokaiTheme,
    'nord': nordTheme,
    'obsidian': obsidianTheme,
    'pojoaque': pojoaqueTheme,
    'purebasic': purebasicTheme,
    'qtcreator_dark': qtcreatorDarkTheme,
    'qtcreator_light': qtcreatorLightTheme,
    'rainbow': rainbowTheme,
    'routeros': routerosTheme,
    'sunburst': sunburstTheme,
    'vs': vsTheme,
    'vs2015': vs2015Theme,
    'xcode': xcodeTheme,
    'xt256': xt256Theme,
  };

  @override
  Widget build(BuildContext context) {
    final content = utf8.decode(data, allowMalformed: true);
    final language = _detectLanguage(fileName);
    final topMargin = isFullscreen ? 0.0 : kToolbarHeight;

    return BlocBuilder<CodeHighlightThemeCubit, CodeHighlightThemeState>(
      builder: (context, state) {
        final theme = themeMap[state.themeName] ?? githubTheme;

        return Container(
          margin: EdgeInsets.only(top: topMargin),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                onUserInteraction?.call();
              }
              return false;
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  content,
                  language: language,
                  theme: theme,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
