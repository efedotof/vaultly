import 'package:flutter/material.dart';

IconData getIconByExtension(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
      return Icons.image;
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow;
    case 'txt':
      return Icons.article;
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
      return Icons.video_file;
    case 'mp3':
    case 'wav':
    case 'flac':
      return Icons.audio_file;
    case 'zip':
    case 'rar':
    case '7z':
      return Icons.archive;
    case 'md':
    case 'markdown':
      return Icons.code;
    default:
      return Icons.insert_drive_file;
  }
}
