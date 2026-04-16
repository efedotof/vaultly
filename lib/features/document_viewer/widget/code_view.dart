import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

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

  @override
  Widget build(BuildContext context) {
    final content = utf8.decode(data, allowMalformed: true);
    final language = _detectLanguage(fileName);
    final topMargin = isFullscreen ? 0.0 : kToolbarHeight;

    return Container(
      margin: EdgeInsets.only(top: topMargin),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            onUserInteraction?.call();
          }
          return false;
        },
        child: HighlightView(
          content,
          language: language,
          theme: githubTheme,
          padding: const EdgeInsets.all(16),
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
    );
  }
}
