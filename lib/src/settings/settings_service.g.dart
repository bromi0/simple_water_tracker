// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsService _$SettingsServiceFromJson(Map<String, dynamic> json) =>
    SettingsService()
      .._themeMode = $enumDecode(_$ThemeModeEnumMap, json['_themeMode']);

Map<String, dynamic> _$SettingsServiceToJson(SettingsService instance) =>
    <String, dynamic>{
      '_themeMode': _$ThemeModeEnumMap[instance._themeMode]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
