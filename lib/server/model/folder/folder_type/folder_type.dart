import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum FolderType {
  @JsonValue('DEFAULT')
  def,
  @JsonValue('SYSTEM_RECENTLY_DELETED')
  systemRecentlyDeleted,
  @JsonValue('SYSTEM_TEMP_LINKS')
  systemTempLinks,
  @JsonValue('SYSTEM_ROOT')
  systemRoot,
  @JsonValue('SYSTEM_HIDDEN')
  systemHidden,
  @JsonValue('CUSTOM')
  custom,
}

extension FolderTypeExtension on FolderType {
  String get value {
    switch (this) {
      case FolderType.def:
        return 'DEFAULT';
      case FolderType.systemRecentlyDeleted:
        return 'SYSTEM_RECENTLY_DELETED';
      case FolderType.systemTempLinks:
        return 'SYSTEM_TEMP_LINKS';
      case FolderType.systemRoot:
        return 'SYSTEM_ROOT';
      case FolderType.systemHidden:
        return 'SYSTEM_HIDDEN';
      case FolderType.custom:
        return 'CUSTOM';
    }
  }

  static FolderType fromValue(String value) {
    switch (value) {
      case 'DEFAULT':
        return FolderType.def;
      case 'SYSTEM_RECENTLY_DELETED':
        return FolderType.systemRecentlyDeleted;
      case 'SYSTEM_TEMP_LINKS':
        return FolderType.systemTempLinks;
      case 'SYSTEM_ROOT':
        return FolderType.systemRoot;
      case 'SYSTEM_HIDDEN':
        return FolderType.systemHidden;
      case 'CUSTOM':
        return FolderType.custom;
      default:
        return FolderType.def;
    }
  }
}
